// Notification and profile-summary logic of the Cloud Functions, written
// against injected admin services so it can be tested on the emulators.
'use strict';

const { FieldValue } = require('firebase-admin/firestore');

const CHANNEL_ID = 'high_importance_channel';
const BATCH_LIMIT = 500;

/** FCM errors that mean the token will never work again. */
const DEAD_TOKEN_CODES = new Set([
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
]);

/**
 * Every push token of [uid]: one document per device in
 * users/{uid}/fcmTokens (current app) plus the single legacy
 * users/{uid}.fcmToken field of older versions. Each entry knows how to
 * remove itself.
 */
async function tokensFor(db, uid) {
  const userRef = db.collection('users').doc(uid);
  const [tokenDocs, userDoc] = await Promise.all([
    userRef.collection('fcmTokens').get(),
    userRef.get(),
  ]);
  const byToken = new Map();
  for (const doc of tokenDocs.docs) {
    const token = doc.get('token') || doc.id;
    byToken.set(token, { token, remove: () => doc.ref.delete() });
  }
  const legacy = userDoc.exists ? userDoc.get('fcmToken') : null;
  if (typeof legacy === 'string' && legacy && !byToken.has(legacy)) {
    byToken.set(legacy, {
      token: legacy,
      remove: () =>
        userRef.update({
          fcmToken: FieldValue.delete(),
          fcmTokenUpdatedAt: FieldValue.delete(),
        }),
    });
  }
  return [...byToken.values()];
}

/**
 * Sends one message per device of [uid] and removes tokens FCM reports as
 * dead. Returns counts for logging and tests.
 */
async function sendToUser({ db, messaging }, uid, buildMessage) {
  const tokens = await tokensFor(db, uid);
  if (tokens.length === 0) return { sent: 0, failed: 0, pruned: 0 };
  const response = await messaging.sendEach(tokens.map((t) => buildMessage(t.token)));
  let pruned = 0;
  await Promise.all(
    response.responses.map(async (r, i) => {
      if (!r.success && DEAD_TOKEN_CODES.has(r.error && r.error.code)) {
        pruned++;
        await tokens[i].remove();
      }
    }),
  );
  return { sent: response.successCount, failed: response.failureCount, pruned };
}

function followMessage(notification, token) {
  const userName = notification.fromUserName || 'Someone';
  return {
    token,
    notification: {
      title: 'New Follower',
      body: `${userName} started following you`,
    },
    data: {
      type: 'follow',
      userName,
      userAvatar: notification.fromUserAvatar || '',
      userId: notification.fromUserId || '',
      clickAction: 'FLUTTER_NOTIFICATION_CLICK',
    },
    android: {
      priority: 'high',
      notification: { channelId: CHANNEL_ID, sound: 'default' },
    },
    apns: {
      payload: { aps: { sound: 'default', badge: 1, contentAvailable: true } },
    },
  };
}

function capsuleMessage({ creatorName, ownerId, capsuleId }, token) {
  return {
    token,
    notification: {
      title: 'New Capsule',
      body: `${creatorName} created a new capsule`,
    },
    data: {
      type: 'capsule',
      userName: creatorName,
      userId: ownerId,
      capsuleId,
      clickAction: 'FLUTTER_NOTIFICATION_CLICK',
    },
    android: {
      priority: 'high',
      notification: { channelId: CHANNEL_ID, sound: 'default' },
    },
  };
}

/** users/{uid}/notifications/{id} was created: push it if it is a follow. */
async function onNotificationCreated(services, uid, notification) {
  if (!notification || notification.type !== 'follow') return null;
  return sendToUser(services, uid, (token) => followMessage(notification, token));
}

/**
 * Followers of [ownerId] who should hear about a new capsule with
 * [privacy]: nobody for private capsules (BUG-027), only followers who are
 * also friends for friends-only capsules, and only followers who kept
 * notifications on.
 */
async function capsuleRecipients(db, ownerId, privacy, ownerFriends) {
  if (privacy === 'private') return [];
  const followers = await db
    .collection('users')
    .doc(ownerId)
    .collection('followers')
    .get();
  let ids = followers.docs.map((d) => d.id).filter((id) => id !== ownerId);
  if (privacy !== 'public') {
    const friends = new Set(ownerFriends);
    ids = ids.filter((id) => friends.has(id));
  }
  const following = await Promise.all(
    ids.map((id) =>
      db.collection('users').doc(id).collection('following').doc(ownerId).get(),
    ),
  );
  return ids.filter((_, i) => following[i].exists && following[i].get('notificationsEnabled') === true);
}

/** capsules/{id} was created: notify the owner's followers. */
async function onCapsuleCreated(services, capsuleId, capsule) {
  const { db } = services;
  // `creatorId` was what this function used to read (never written, BUG-026).
  const ownerId = (capsule && (capsule.ownerId || capsule.creatorId)) || null;
  if (!ownerId) return { recipients: 0 };
  const privacy = capsule.privacy || 'friends';

  const ownerDoc = await db.collection('users').doc(ownerId).get();
  if (!ownerDoc.exists) return { recipients: 0 };
  const owner = ownerDoc.data();
  const creatorName = owner.username || owner.name || 'Someone';

  const recipients = await capsuleRecipients(db, ownerId, privacy, owner.friends || []);
  if (recipients.length === 0) return { recipients: 0 };

  // The in-app notification is written for every recipient, with or without
  // a device token.
  for (let i = 0; i < recipients.length; i += BATCH_LIMIT) {
    const batch = db.batch();
    for (const uid of recipients.slice(i, i + BATCH_LIMIT)) {
      batch.set(db.collection('users').doc(uid).collection('notifications').doc(), {
        type: 'capsule',
        fromUserId: ownerId,
        fromUserName: creatorName,
        fromUserAvatar: '',
        message: 'created a new capsule',
        capsuleId,
        timestamp: FieldValue.serverTimestamp(),
        isRead: false,
      });
    }
    await batch.commit();
  }

  const results = await Promise.all(
    recipients.map((uid) =>
      sendToUser(services, uid, (token) =>
        capsuleMessage({ creatorName, ownerId, capsuleId }, token),
      ),
    ),
  );
  return {
    recipients: recipients.length,
    sent: results.reduce((n, r) => n + r.sent, 0),
    pruned: results.reduce((n, r) => n + r.pruned, 0),
  };
}

const USER_ID = /^[A-Za-z0-9]{1,128}$/;

/**
 * Public card for the profile landing page: display name and avatar only
 * (BUG-103: no email, no makePublic, no debug data). The avatar URL is the
 * regular token download URL the app itself uses.
 */
async function profileSummary({ db, bucket }, userId) {
  if (typeof userId !== 'string' || !USER_ID.test(userId)) return null;
  const userDoc = await db.collection('users').doc(userId).get();
  if (!userDoc.exists) return null;
  const user = userDoc.data();
  let photoURL = null;
  for (const name of ['profile_image_small', 'profile_image']) {
    const filePath = `userdata/${userId}/assets/images/${name}`;
    const file = bucket.file(filePath);
    const [exists] = await file.exists();
    if (!exists) continue;
    const [meta] = await file.getMetadata();
    const tokens = meta.metadata && meta.metadata.firebaseStorageDownloadTokens;
    const token = typeof tokens === 'string' ? tokens.split(',')[0] : null;
    if (token) {
      photoURL =
        `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/` +
        `${encodeURIComponent(filePath)}?alt=media&token=${token}`;
      break;
    }
  }
  return { displayName: user.name || user.username || 'Your friend', photoURL };
}

module.exports = {
  DEAD_TOKEN_CODES,
  tokensFor,
  sendToUser,
  followMessage,
  capsuleMessage,
  onNotificationCreated,
  capsuleRecipients,
  onCapsuleCreated,
  profileSummary,
};
