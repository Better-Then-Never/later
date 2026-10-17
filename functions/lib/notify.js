// Notification and profile-summary logic of the Cloud Functions, written
// against injected admin services so it can be tested on the emulators.
'use strict';

const { FieldValue } = require('firebase-admin/firestore');
const prefs = require('./prefs');
const i18n = require('./i18n');

/** Longest message text shown in a push. */
const PREVIEW_LENGTH = 150;
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

/** Android and iOS delivery options for a push of [category]. */
function delivery(category, sound, { tag } = {}) {
  return {
    android: {
      priority: 'high',
      notification: {
        channelId: prefs.channelFor(category, sound),
        ...(sound ? { sound: 'default' } : {}),
        // Same tag = the new push replaces the previous one (one per chat).
        ...(tag ? { tag } : {}),
      },
    },
    apns: {
      payload: {
        aps: {
          ...(sound ? { sound: 'default' } : {}),
          ...(tag ? { 'thread-id': tag } : {}),
          contentAvailable: true,
        },
      },
    },
  };
}

function followMessage(notification, token, sound = true, lang = 'en') {
  const userName = notification.fromUserName || i18n.t(lang, 'someone');
  return {
    token,
    notification: {
      title: i18n.t(lang, 'followTitle'),
      body: i18n.t(lang, 'followBody', { name: userName }),
    },
    data: {
      type: 'follow',
      userName,
      userAvatar: notification.fromUserAvatar || '',
      userId: notification.fromUserId || '',
      clickAction: 'FLUTTER_NOTIFICATION_CLICK',
    },
    ...delivery('follows', sound),
  };
}

function capsuleMessage({ creatorName, ownerId, capsuleId }, token, sound = true, lang = 'en') {
  return {
    token,
    notification: {
      title: i18n.t(lang, 'capsuleTitle'),
      body: i18n.t(lang, 'capsuleBody', { name: creatorName }),
    },
    data: {
      type: 'capsule',
      userName: creatorName,
      userId: ownerId,
      capsuleId,
      clickAction: 'FLUTTER_NOTIFICATION_CLICK',
    },
    ...delivery('capsules', sound),
  };
}

/** What a photo message without a caption carries as its text. */
const PHOTO_SIGN = '📷';

/** Push to a co-author: a friend made a capsule with them. */
function coAuthorMessage({ creatorName, ownerId, capsuleId }, token, sound = true, lang = 'en') {
  return {
    token,
    notification: {
      title: i18n.t(lang, 'coAuthorTitle'),
      body: i18n.t(lang, 'coAuthorBody', { name: creatorName }),
    },
    data: {
      type: 'coAuthor',
      userName: creatorName,
      userId: ownerId,
      capsuleId,
      clickAction: 'FLUTTER_NOTIFICATION_CLICK',
    },
    ...delivery('capsules', sound),
  };
}

/** Most followers told about one new capsule. */
const MAX_FOLLOWER_FANOUT = 500;

/** Most co-authors a capsule may have (firestore.rules). */
const MAX_CO_AUTHORS = 5;

/**
 * The co-authors of [capsule] worth telling: friends of its owner (the rules
 * check that too), never the owner, at most five.
 */
function coAuthorsOf(capsule, ownerId, ownerFriends) {
  const list = Array.isArray(capsule.coAuthors) ? capsule.coAuthors : [];
  const friends = new Set(ownerFriends);
  return [...new Set(list)]
    .filter((id) => typeof id === 'string' && id !== ownerId && friends.has(id))
    .slice(0, MAX_CO_AUTHORS);
}

/** Body of a message push: the text, or a neutral line without preview. */
function messageBody(message, preview, lang = 'en') {
  const capsule = message.type === 'capsule';
  const photo = message.type === 'image';
  if (message.type === 'voice') return `🎤 ${i18n.t(lang, 'messageVoice')}`;
  if (!preview) {
    return i18n.t(lang, capsule ? 'messageCapsule' : photo ? 'messagePhoto' : 'messageNoPreview');
  }
  const short = shorten(String(message.text || ''));
  if (photo) {
    return short && short !== PHOTO_SIGN ? `${PHOTO_SIGN} ${short}` : i18n.t(lang, 'messagePhoto');
  }
  return capsule ? i18n.t(lang, 'messageCapsuleTitled', { title: short }) : short;
}

/** [text] shortened to the preview length of a push. */
function shorten(text) {
  return text.length > PREVIEW_LENGTH ? `${text.slice(0, PREVIEW_LENGTH - 1)}…` : text;
}

function chatMessage({ senderName, senderId, chatId, messageId, body, title }, token, sound = true) {
  return {
    token,
    notification: { title: title || senderName, body },
    data: {
      type: 'message',
      userId: senderId,
      chatId,
      messageId,
      clickAction: 'FLUTTER_NOTIFICATION_CLICK',
    },
    ...delivery('messages', sound, { tag: chatId }),
  };
}

const now = (services) => (services.now ? services.now() : new Date());

/**
 * users/{uid}/notifications/{id} was created: push it if it is a follow and
 * the user wants follow pushes now.
 */
async function onNotificationCreated(services, uid, notification) {
  if (!notification || notification.type !== 'follow') return null;
  const settings = await prefs.loadSettings(services.db, uid);
  const blocked = prefs.blockedReason(settings, 'follows', now(services));
  if (blocked) return { skipped: blocked };
  const sound = prefs.alertOf(settings);
  const lang = i18n.languageOf(settings);
  return sendToUser(services, uid, (token) => followMessage(notification, token, sound, lang));
}

/**
 * chats/{chatId}/messages/{id} was created: push it to the other participant
 * unless they muted the chat, turned message pushes off or are in quiet
 * hours. One push per chat at a time on Android (tag = chat id).
 */
async function onMessageCreated(services, chatId, messageId, message) {
  if (String(chatId).startsWith('g_')) {
    return onGroupMessageCreated(services, chatId, messageId, message);
  }
  const members = String(chatId).split('_');
  const senderId = message && message.senderId;
  if (members.length !== 2 || !senderId || !members.includes(senderId)) return null;
  const to = members.find((m) => m !== senderId);
  const { db } = services;

  const settings = await prefs.loadSettings(db, to);
  if (settings.mutedChats.includes(chatId)) return { skipped: 'muted' };
  const blocked = prefs.blockedReason(settings, 'messages', now(services));
  if (blocked) return { skipped: blocked };

  const sender = await db.collection('users').doc(senderId).get();
  const lang = i18n.languageOf(settings);
  const senderName =
    (sender.exists && (sender.get('name') || sender.get('username'))) ||
    i18n.t(lang, 'messageNoPreview');
  const body = messageBody(message, settings.notifications.preview, lang);
  const sound = prefs.alertOf(settings);
  return sendToUser(services, to, (token) =>
    chatMessage({ senderName, senderId, chatId, messageId, body }, token, sound),
  );
}

/** Most people a group push goes to (groups have at most 20 members). */
const GROUP_PUSH_LIMIT = 20;

/**
 * A message in group [chatId]: every other member hears it ("Group name",
 * "Bob: text"), each by their own settings (mutes, quiet hours, previews).
 */
async function onGroupMessageCreated(services, chatId, messageId, message) {
  const { db } = services;
  const senderId = message && message.senderId;
  const group = await db.collection('chats').doc(chatId).get();
  const members = group.exists ? group.get('members') : null;
  if (!senderId || !Array.isArray(members) || !members.includes(senderId)) return null;
  const sender = await db.collection('users').doc(senderId).get();
  const groupName = String(group.get('name') || '');
  const recipients = members.filter((m) => m !== senderId).slice(0, GROUP_PUSH_LIMIT);
  const report = {};
  for (const to of recipients) {
    const settings = await prefs.loadSettings(db, to);
    if (settings.mutedChats.includes(chatId)) {
      report[to] = { skipped: 'muted' };
      continue;
    }
    const blocked = prefs.blockedReason(settings, 'messages', now(services));
    if (blocked) {
      report[to] = { skipped: blocked };
      continue;
    }
    const lang = i18n.languageOf(settings);
    const senderName =
      (sender.exists && (sender.get('name') || sender.get('username'))) || i18n.t(lang, 'someone');
    const text = messageBody(message, settings.notifications.preview, lang);
    const body = settings.notifications.preview ? `${senderName}: ${text}` : text;
    const sound = prefs.alertOf(settings);
    report[to] = await sendToUser(services, to, (token) =>
      chatMessage({ senderName, senderId, chatId, messageId, body, title: groupName || senderName }, token, sound),
    );
  }
  return report;
}

/**
 * Followers of [ownerId] who should hear about a new capsule with
 * [privacy]: nobody for private capsules (BUG-027), only followers who are
 * also friends for friends-only capsules, and only followers who kept
 * notifications on.
 */
async function capsuleRecipients(db, ownerId, privacy, ownerFriends, max = MAX_FOLLOWER_FANOUT) {
  if (privacy === 'private') return [];
  // Bounded (B6): at most [max] followers; one capsule never fans out to
  // an unbounded audience. (No ordering: follows written by older app
  // versions may lack followedAt and an orderBy would leave them out.)
  const followers = await db
    .collection('users')
    .doc(ownerId)
    .collection('followers')
    .limit(max)
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

/**
 * capsules/{id} was created: notify its co-authors (whatever its privacy)
 * and the owner's followers (co-authors hear about it only once).
 */
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

  const coAuthors = coAuthorsOf(capsule, ownerId, owner.friends || []);
  const together = new Set(coAuthors);
  const recipients = (await capsuleRecipients(db, ownerId, privacy, owner.friends || []))
    .filter((uid) => !together.has(uid));
  if (recipients.length === 0 && coAuthors.length === 0) return { recipients: 0 };
  const at = now(services);

  // The in-app notification is written for every recipient, with or without
  // a device token. Old apps show an unknown type's stored message.
  const everyone = [
    ...coAuthors.map((uid) => ({ uid, type: 'coAuthor', message: 'made a capsule with you' })),
    ...recipients.map((uid) => ({ uid, type: 'capsule', message: 'created a new capsule' })),
  ];
  for (let i = 0; i < everyone.length; i += BATCH_LIMIT) {
    const batch = db.batch();
    for (const { uid, type, message } of everyone.slice(i, i + BATCH_LIMIT)) {
      batch.set(db.collection('users').doc(uid).collection('notifications').doc(), {
        type,
        fromUserId: ownerId,
        fromUserName: creatorName,
        fromUserAvatar: '',
        message,
        capsuleId,
        timestamp: FieldValue.serverTimestamp(),
        isRead: false,
      });
    }
    await batch.commit();
  }

  // Pushes only for recipients who want capsule pushes now; the in-app
  // notification above is written for everyone.
  const results = await Promise.all(
    everyone.map(async ({ uid, type }) => {
      const settings = await prefs.loadSettings(db, uid);
      if (prefs.blockedReason(settings, 'capsules', at)) return { sent: 0, pruned: 0 };
      const sound = prefs.alertOf(settings);
      const lang = i18n.languageOf(settings);
      const build = type === 'coAuthor' ? coAuthorMessage : capsuleMessage;
      return sendToUser(services, uid, (token) =>
        build({ creatorName, ownerId, capsuleId }, token, sound, lang),
      );
    }),
  );
  return {
    recipients: recipients.length,
    coAuthors: coAuthors.length,
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
  coAuthorMessage,
  coAuthorsOf,
  onNotificationCreated,
  messageBody,
  shorten,
  delivery,
  now,
  chatMessage,
  onMessageCreated,
  onGroupMessageCreated,
  capsuleRecipients,
  MAX_FOLLOWER_FANOUT,
  onCapsuleCreated,
  profileSummary,
};
