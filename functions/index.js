'use strict';

const { setGlobalOptions } = require('firebase-functions/v2');
const { onRequest, onCall, HttpsError } = require('firebase-functions/v2/https');
const {
  onDocumentCreated,
  onDocumentDeleted,
  onDocumentUpdated,
  onDocumentWritten,
} = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');
const functionsV1 = require('firebase-functions/v1');
const notify = require('./lib/notify');
const account = require('./lib/account');
const social = require('./lib/social');
const gamification = require('./lib/gamification');
const broadcast = require('./lib/broadcast');
const chats = require('./lib/chats');
const contacts = require('./lib/contacts');

admin.initializeApp();

// The project's Compute Engine default service account no longer exists;
// the functions run (and their Firestore triggers deliver) as this one.
// Roles: Datastore User, FCM Admin, Storage Object Viewer, Logs Writer,
// Run Invoker, Eventarc Event Receiver (+ Cloud Build / Artifact Registry
// for building). See docs/refactor/MIGRATIONS_NEEDED.md.
setGlobalOptions({
  serviceAccount: 'later-functions@later-da778.iam.gserviceaccount.com',
});

// In the Functions emulator pushes are logged, not sent: FCM is not emulated,
// and a real send would go out with this machine's credentials
// (docs/feel/RIG.md).
const loggedMessaging = {
  async send(message) {
    logger.info('push not sent (emulator)', { message });
    return 'emulator';
  },
  async sendEach(messages) {
    logger.info('pushes not sent (emulator)', { messages });
    return {
      successCount: messages.length,
      failureCount: 0,
      responses: messages.map(() => ({ success: true })),
    };
  },
};

const services = () => ({
  db: admin.firestore(),
  messaging: process.env.FUNCTIONS_EMULATOR === 'true' ? loggedMessaging : admin.messaging(),
  bucket: admin.storage().bucket(),
});

// Name and avatar for the profile landing page (public/index.html).
exports.getUserData = onRequest({ cors: true }, async (req, res) => {
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }
  try {
    const summary = await notify.profileSummary(services(), req.query.userId);
    if (!summary) {
      res.status(404).json({ displayName: 'Your friend', photoURL: null });
      return;
    }
    res.set('Cache-Control', 'public, max-age=300');
    res.json(summary);
  } catch (error) {
    logger.error('getUserData failed', error);
    res.status(500).json({ displayName: 'Your friend', photoURL: null });
  }
});

// Push for "started following you" notifications.
exports.sendFollowerNotification = onDocumentCreated(
  'users/{userId}/notifications/{notificationId}',
  async (event) => {
    try {
      const result = await notify.onNotificationCreated(
        services(),
        event.params.userId,
        event.data && event.data.data(),
      );
      if (result) logger.info('Follower notification', result);
    } catch (error) {
      logger.error('Follower notification failed', error);
    }
  },
);

// In-app notification + push to followers when a capsule is created.
exports.sendCapsuleNotification = onDocumentCreated(
  'capsules/{capsuleId}',
  async (event) => {
    try {
      const result = await notify.onCapsuleCreated(
        services(),
        event.params.capsuleId,
        event.data && event.data.data(),
      );
      logger.info('Capsule notification', result);
    } catch (error) {
      logger.error('Capsule notification failed', error);
    }
  },
);

// Push for a new chat message to the other participant (respects their
// notification settings, mutes and quiet hours).
exports.sendMessageNotification = onDocumentCreated(
  'chats/{chatId}/messages/{messageId}',
  async (event) => {
    try {
      const result = await notify.onMessageCreated(
        services(),
        event.params.chatId,
        event.params.messageId,
        event.data && event.data.data(),
      );
      if (result) logger.info('Message notification', result);
    } catch (error) {
      logger.error('Message notification failed', error);
    }
  },
);

// "Delete account" in the app deletes the Auth user; this removes the data
// the account leaves behind. (Auth triggers exist only in the v1 API.)
exports.cleanupDeletedAccount = functionsV1
  .runWith({ serviceAccount: 'later-functions@later-da778.iam.gserviceaccount.com' })
  .auth.user()
  .onDelete(async (user) => {
    try {
      const report = await account.deleteUserData(services(), user.uid);
      logger.info('Deleted account data', { uid: user.uid, ...report });
    } catch (error) {
      logger.error('Deleting account data failed', error);
      throw error; // retried by the platform when retries are enabled
    }
  });

// ---- social: counters and notifications (functions/lib/social.js) -----------

/** Runs [work] and logs; a failing trigger never throws into a retry storm. */
function logged(name, work) {
  return async (event) => {
    try {
      const result = await work(event);
      if (result) logger.info(name, result);
    } catch (error) {
      logger.error(`${name} failed`, error);
    }
  };
}

const data = (snapshot) => (snapshot && snapshot.exists ? snapshot.data() : undefined);

// Suggestions from contacts (functions/lib/contacts.js), opt-in: the index
// follows "people with my email find me"; a request is answered once.
exports.syncContactIndex = onDocumentWritten(
  'users/{uid}/settings/app',
  logged('Contact index', (event) =>
    contacts.syncContactIndex(
      { db: admin.firestore(), auth: admin.auth() },
      event.params.uid,
      data(event.data && event.data.before),
      data(event.data && event.data.after),
    ),
  ),
);

exports.matchContacts = onDocumentWritten(
  'contactMatches/{uid}',
  logged('Contact matches', (event) =>
    contacts.matchContacts(
      { db: admin.firestore() },
      event.params.uid,
      data(event.data && event.data.after),
    ),
  ),
);

// Someone invited to a group joins if the inviter is their friend
// (functions/lib/chats.js).
exports.acceptGroupInvite = onDocumentCreated(
  'chats/{chatId}/invites/{uid}',
  logged('Group invite', (e) =>
    chats.onGroupInvite(services(), e.params.chatId, e.params.uid, data(e.data)),
  ),
);

// Someone reacted to a chat message: its author hears it
// (functions/lib/chats.js).
exports.sendMessageReactionNotification = onDocumentUpdated(
  'chats/{chatId}/messages/{messageId}',
  logged('Message reaction', (e) =>
    chats.onMessageReacted(
      services(),
      e.params.chatId,
      e.params.messageId,
      data(e.data.before),
      data(e.data.after),
    ),
  ),
);

// A chat photo's or recording's file is deleted with its message
// (functions/lib/chats.js).
exports.deleteChatFile = onDocumentDeleted(
  'chats/{chatId}/messages/{messageId}',
  logged('Chat file', (e) => chats.onMessageDeleted(services(), e.params.chatId, data(e.data))),
);

exports.countFollowerAdded = onDocumentCreated(
  'users/{uid}/followers/{follower}',
  logged('Follower count', (e) => social.onFollowerChanged(services(), e.params.uid, 1)),
);
exports.countFollowerRemoved = onDocumentDeleted(
  'users/{uid}/followers/{follower}',
  logged('Follower count', (e) => social.onFollowerChanged(services(), e.params.uid, -1)),
);
exports.countFollowingAdded = onDocumentCreated(
  'users/{uid}/following/{target}',
  logged('Following count', (e) => social.onFollowingChanged(services(), e.params.uid, 1)),
);
exports.countFollowingRemoved = onDocumentDeleted(
  'users/{uid}/following/{target}',
  logged('Following count', (e) => social.onFollowingChanged(services(), e.params.uid, -1)),
);

exports.onReactionWritten = onDocumentWritten(
  'capsules/{capsuleId}/reactions/{uid}',
  logged('Reaction', async (e) => {
    const result = await social.onReactionWritten(
      services(),
      e.params.capsuleId,
      e.params.uid,
      data(e.data && e.data.before),
      data(e.data && e.data.after),
    );
    // The owner received one more reaction (Crowd pleaser).
    if (result && result.ownerId) {
      await gamification.checkAchievements(services(), result.ownerId);
    }
    return result;
  }),
);

exports.onCommentCreated = onDocumentCreated(
  'capsules/{capsuleId}/comments/{commentId}',
  logged('Comment', async (e) => {
    const comment = data(e.data);
    const result = await social.onCommentCreated(
      services(),
      e.params.capsuleId,
      e.params.commentId,
      comment,
    );
    // The author wrote one more comment (Chatterbox).
    if (comment && comment.authorId) {
      await gamification.checkAchievements(services(), comment.authorId);
    }
    return result;
  }),
);
exports.onCommentDeleted = onDocumentDeleted(
  'capsules/{capsuleId}/comments/{commentId}',
  logged('Comment deleted', (e) => social.onCommentDeleted(services(), e.params.capsuleId)),
);

exports.onFriendRequestCreated = onDocumentCreated(
  'friend_requests/{requestId}',
  logged('Friend request', (e) =>
    social.onFriendRequestCreated(services(), e.params.requestId, data(e.data)),
  ),
);
exports.onFriendRequestUpdated = onDocumentUpdated(
  'friend_requests/{requestId}',
  logged('Friend request accepted', async (e) => {
    const before = data(e.data && e.data.before);
    const after = data(e.data && e.data.after);
    const result = await social.onFriendRequestUpdated(
      services(),
      e.params.requestId,
      before,
      after,
    );
    // Both have one more friend (Friendly).
    if (result !== null && after) {
      await gamification.checkAchievements(services(), after.fromUserId);
      await gamification.checkAchievements(services(), after.toUserId);
    }
    return result;
  }),
);

// ---- gamification: stats, streaks, achievements (functions/lib/gamification.js)

// Counts a new capsule, then unlocks what its stats reached. The former
// unlockAchievements trigger ran on every users/{uid} write (profile
// edits, pins, favourites); achievements are now checked only where a
// counted stat changes: here, reactions, comments, accepted friends (B6).
exports.updateCapsuleStats = onDocumentCreated(
  'capsules/{capsuleId}',
  logged('Capsule stats', async (e) => {
    const capsule = data(e.data);
    const result = await gamification.onCapsuleCreated(services(), e.params.capsuleId, capsule);
    if (capsule && capsule.ownerId) {
      await gamification.checkAchievements(services(), capsule.ownerId);
    }
    return result;
  }),
);

exports.sendStreakReminders = onSchedule(
  'every 60 minutes',
  logged('Streak reminders', () => gamification.sendStreakReminders(services())),
);

// ---- announcements (functions/lib/broadcast.js, docs/ux/ADMIN.md) ------------

exports.sendAnnouncement = onCall(async (request) => {
  try {
    return await broadcast.sendAnnouncement(services(), request.auth, request.data);
  } catch (error) {
    if (error instanceof broadcast.AnnouncementError) {
      throw new HttpsError(error.code, error.message);
    }
    logger.error('Announcement failed', error);
    throw new HttpsError('internal', 'Sending the announcement failed.');
  }
});
