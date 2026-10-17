// Counters and notifications for the social features: follower counts,
// reactions and comments on capsules, friend requests. Written against
// injected admin services so it runs on the emulators in tests.
'use strict';

const { FieldValue } = require('firebase-admin/firestore');
const prefs = require('./prefs');
const i18n = require('./i18n');
const notify = require('./notify');

/** The six reactions (DECISIONS.md D-12): stored key -> emoji in pushes. */
const REACTIONS = Object.freeze({
  heart: '❤️',
  laugh: '😂',
  wow: '😮',
  sad: '😢',
  fire: '🔥',
  clap: '👏',
});

const users = (db) => db.collection('users');

async function displayName(db, uid, lang) {
  const doc = await users(db).doc(uid).get();
  return (doc.exists && (doc.get('name') || doc.get('username'))) || i18n.t(lang, 'someone');
}

/** Whether [owner] blocked [other] (blocked users get no notifications from each other). */
async function isBlocked(db, owner, other) {
  const [a, b] = await Promise.all([
    users(db).doc(owner).collection('blocked').doc(other).get(),
    users(db).doc(other).collection('blocked').doc(owner).get(),
  ]);
  return a.exists || b.exists;
}

/**
 * Writes the in-app notification [id] for [uid] (deterministic ids: a retried
 * trigger overwrites instead of duplicating) and pushes it when the user's
 * settings allow [category]. [text] builds the push for a language.
 */
async function deliver(services, uid, id, category, inApp, text) {
  const { db } = services;
  await users(db).doc(uid).collection('notifications').doc(id).set({
    ...inApp,
    timestamp: FieldValue.serverTimestamp(),
    isRead: false,
  });
  const settings = await prefs.loadSettings(db, uid);
  const blocked = prefs.blockedReason(settings, category, notify.now(services));
  if (blocked) return { skipped: blocked };
  const lang = i18n.languageOf(settings);
  const { title, body, data } = await text(lang);
  const sound = prefs.alertOf(settings);
  return notify.sendToUser(services, uid, (token) => ({
    token,
    notification: { title, body },
    data: { ...data, clickAction: 'FLUTTER_NOTIFICATION_CLICK' },
    ...notify.delivery(category, sound),
  }));
}

// ---- follower counts ------------------------------------------------------

/** users/{uid}/followers/{x} created (+1) or deleted (-1). */
async function onFollowerChanged({ db }, uid, delta) {
  await users(db).doc(uid).set({ followerCount: FieldValue.increment(delta) }, { merge: true });
  return { uid, followerCount: delta };
}

/** users/{uid}/following/{x} created (+1) or deleted (-1). */
async function onFollowingChanged({ db }, uid, delta) {
  await users(db).doc(uid).set({ followingCount: FieldValue.increment(delta) }, { merge: true });
  return { uid, followingCount: delta };
}

// ---- reactions --------------------------------------------------------------

/**
 * capsules/{capsuleId}/reactions/{uid} was written ([before]/[after] are the
 * document data or undefined). Moves the counters and notifies the owner of a
 * new reaction (once per person and capsule).
 */
async function onReactionWritten(services, capsuleId, uid, before, after) {
  const { db } = services;
  const capsuleRef = db.collection('capsules').doc(capsuleId);
  const oldType = before && REACTIONS[before.type] ? before.type : null;
  const newType = after && REACTIONS[after.type] ? after.type : null;
  if (oldType === newType) return null;
  const update = {};
  if (oldType) update[`reactionCounts.${oldType}`] = FieldValue.increment(-1);
  if (newType) update[`reactionCounts.${newType}`] = FieldValue.increment(1);
  if (!oldType) update.reactionTotal = FieldValue.increment(1);
  if (!newType) update.reactionTotal = FieldValue.increment(-1);
  const capsule = await capsuleRef.get();
  if (!capsule.exists) return { skipped: 'capsule gone' };
  await capsuleRef.update(update);

  const ownerId = capsule.get('ownerId');
  // Only a first reaction notifies (changing the emoji does not).
  if (!newType || oldType || !ownerId || ownerId === uid) return { counted: true };
  if (await isBlocked(db, ownerId, uid)) return { counted: true, skipped: 'blocked' };
  await users(db).doc(ownerId).set(
    { stats: { reactionsReceived: FieldValue.increment(1) } },
    { merge: true },
  );
  const result = await deliver(
    services,
    ownerId,
    `reaction_${capsuleId}_${uid}`,
    'reactions',
    { type: 'reaction', fromUserId: uid, capsuleId, reaction: newType },
    async (lang) => ({
      title: i18n.t(lang, 'reactionTitle'),
      body: i18n.t(lang, 'reactionBody', {
        name: await displayName(db, uid, lang),
        emoji: REACTIONS[newType],
      }),
      data: { type: 'reaction', userId: uid, capsuleId },
    }),
  );
  return { counted: true, ownerId, notified: result };
}

// ---- comments ---------------------------------------------------------------

/** capsules/{capsuleId}/comments/{commentId} was created. */
async function onCommentCreated(services, capsuleId, commentId, comment) {
  const { db } = services;
  const capsuleRef = db.collection('capsules').doc(capsuleId);
  const capsule = await capsuleRef.get();
  if (!capsule.exists || !comment) return { skipped: 'capsule gone' };
  await capsuleRef.update({ commentCount: FieldValue.increment(1) });
  const authorId = comment.authorId;
  await users(db).doc(authorId).set(
    { stats: { commentsWritten: FieldValue.increment(1) } },
    { merge: true },
  );

  const ownerId = capsule.get('ownerId');
  const text = notify.shorten(String(comment.text || ''));
  const notified = {};
  const recipients = [];
  if (ownerId && ownerId !== authorId) recipients.push([ownerId, 'comment']);
  if (comment.replyTo) {
    const parent = await capsuleRef.collection('comments').doc(comment.replyTo).get();
    const parentAuthor = parent.exists ? parent.get('authorId') : null;
    if (parentAuthor && parentAuthor !== authorId && parentAuthor !== ownerId) {
      recipients.push([parentAuthor, 'reply']);
    }
  }
  for (const [uid, kind] of recipients) {
    if (await isBlocked(db, uid, authorId)) {
      notified[uid] = { skipped: 'blocked' };
      continue;
    }
    notified[uid] = await deliver(
      services,
      uid,
      `${kind}_${capsuleId}_${commentId}`,
      'comments',
      { type: kind, fromUserId: authorId, capsuleId, commentId, message: text },
      async (lang) => ({
        title: i18n.t(lang, kind === 'reply' ? 'replyTitle' : 'commentTitle'),
        body: i18n.t(lang, 'commentBody', {
          name: await displayName(db, authorId, lang),
          text,
        }),
        data: { type: kind, userId: authorId, capsuleId, commentId },
      }),
    );
  }
  return { counted: true, notified };
}

/** capsules/{capsuleId}/comments/{commentId} was deleted. */
async function onCommentDeleted({ db }, capsuleId) {
  const capsuleRef = db.collection('capsules').doc(capsuleId);
  const capsule = await capsuleRef.get();
  if (!capsule.exists) return null;
  await capsuleRef.update({ commentCount: FieldValue.increment(-1) });
  return { counted: true };
}

// ---- friend requests ----------------------------------------------------------

/** friend_requests/{from_to} created: tell the receiver. */
async function onFriendRequestCreated(services, requestId, request) {
  if (!request || request.status !== 'pending') return null;
  const { db } = services;
  const from = request.fromUserId;
  const to = request.toUserId;
  if (await isBlocked(db, to, from)) return { skipped: 'blocked' };
  return deliver(
    services,
    to,
    `request_${requestId}`,
    'friendRequests',
    { type: 'friendRequest', fromUserId: from },
    async (lang) => ({
      title: i18n.t(lang, 'requestTitle'),
      body: i18n.t(lang, 'requestBody', { name: await displayName(db, from, lang) }),
      data: { type: 'friendRequest', userId: from },
    }),
  );
}

/** friend_requests/{from_to} updated: when accepted, tell the sender. */
async function onFriendRequestUpdated(services, requestId, before, after) {
  if (!before || !after || before.status === 'accepted' || after.status !== 'accepted') {
    return null;
  }
  const { db } = services;
  const from = after.fromUserId;
  const to = after.toUserId;
  await users(db).doc(from).set({ stats: { friendsMade: FieldValue.increment(1) } }, { merge: true });
  await users(db).doc(to).set({ stats: { friendsMade: FieldValue.increment(1) } }, { merge: true });
  return deliver(
    services,
    from,
    `accepted_${requestId}`,
    'friendRequests',
    { type: 'friendAccepted', fromUserId: to },
    async (lang) => ({
      title: i18n.t(lang, 'acceptedTitle'),
      body: i18n.t(lang, 'acceptedBody', { name: await displayName(db, to, lang) }),
      data: { type: 'friendAccepted', userId: to },
    }),
  );
}

module.exports = {
  REACTIONS,
  deliver,
  isBlocked,
  onFollowerChanged,
  onFollowingChanged,
  onReactionWritten,
  onCommentCreated,
  onCommentDeleted,
  onFriendRequestCreated,
  onFriendRequestUpdated,
};
