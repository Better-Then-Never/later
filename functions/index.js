'use strict';

const { setGlobalOptions } = require('firebase-functions/v2');
const { onRequest } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');
const functionsV1 = require('firebase-functions/v1');
const notify = require('./lib/notify');
const account = require('./lib/account');

admin.initializeApp();

// The project's Compute Engine default service account no longer exists;
// the functions run (and their Firestore triggers deliver) as this one.
// Roles: Datastore User, FCM Admin, Storage Object Viewer, Logs Writer,
// Run Invoker, Eventarc Event Receiver (+ Cloud Build / Artifact Registry
// for building). See docs/refactor/MIGRATIONS_NEEDED.md.
setGlobalOptions({
  serviceAccount: 'later-functions@later-da778.iam.gserviceaccount.com',
});

const services = () => ({
  db: admin.firestore(),
  messaging: admin.messaging(),
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
