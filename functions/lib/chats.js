// Chat housekeeping: a photo's file goes with its message; people join a
// group through an invite this code checks.
'use strict';

const { FieldValue } = require('firebase-admin/firestore');
const i18n = require('./i18n');
const notify = require('./notify');
const prefs = require('./prefs');
const social = require('./social');

/**
 * chats/{chatId}/messages/{id} was deleted (by its sender, "Clear history"
 * or account deletion): the photo or recording it carried is deleted from
 * Storage too, so it does not stay behind. Only files in that chat's folder
 * are touched (storage.rules: chats/{chatId}/{sender}/{id}.jpg or .m4a).
 */
async function onMessageDeleted({ bucket }, chatId, message) {
  const path =
    message && message.type === 'image'
      ? message.imagePath
      : message && message.type === 'voice'
        ? message.audioPath
        : null;
  if (
    typeof path !== 'string' ||
    !path.startsWith(`chats/${chatId}/`) ||
    path.includes('..')
  ) {
    return null;
  }
  await bucket.file(path).delete({ ignoreNotFound: true });
  return { deleted: path };
}

/** Groups have at most this many members (firestore.rules). */
const GROUP_LIMIT = 20;

/**
 * chats/{g_id}/invites/{uid} was created by a member ([invite].by): [uid]
 * joins if they are that member's friend, blocked nobody in the group and
 * was not blocked by the inviter, and the group has room. The invite is
 * deleted either way. Returns what happened.
 */
async function onGroupInvite({ db }, chatId, uid, invite) {
  const ref = db.collection('chats').doc(chatId);
  const inviteRef = ref.collection('invites').doc(uid);
  const by = invite && invite.by;
  const outcome = await db.runTransaction(async (tx) => {
    const group = await tx.get(ref);
    const members = group.exists && Array.isArray(group.get('members')) ? group.get('members') : null;
    if (!String(chatId).startsWith('g_') || !members || !members.includes(by)) return 'not-a-member';
    if (members.includes(uid)) return 'already-in';
    if (members.length >= GROUP_LIMIT) return 'full';
    const [user, theirBlocks, inviterBlocks] = await Promise.all([
      tx.get(db.collection('users').doc(uid)),
      tx.get(db.collection('users').doc(uid).collection('blocked')),
      tx.get(db.collection('users').doc(by).collection('blocked').doc(uid)),
    ]);
    if (!user.exists) return 'no-account';
    const friends = Array.isArray(user.get('friends')) ? user.get('friends') : [];
    if (!friends.includes(by)) return 'not-a-friend';
    if (inviterBlocks.exists || theirBlocks.docs.some((d) => members.includes(d.id))) return 'blocked';
    tx.update(ref, { members: FieldValue.arrayUnion(uid) });
    return 'joined';
  });
  await inviteRef.delete();
  return { [uid]: outcome };
}

/**
 * chats/{chatId}/messages/{id} changed: when someone (not its author) newly
 * reacted, the author hears it ("Anna", "❤️ to your message: text"), by
 * their message settings; muted chats and blocked people stay quiet. One push
 * per change (the newest reaction).
 */
async function onMessageReacted(services, chatId, messageId, before, after) {
  if (!before || !after) return null;
  const author = after.senderId;
  const was = before.reactions || {};
  const added = Object.entries(after.reactions || {}).filter(
    ([uid, type]) => uid !== author && was[uid] !== type && social.REACTIONS[type],
  );
  if (!author || added.length === 0) return null;
  const [reactorId, type] = added[added.length - 1];
  const { db } = services;
  const settings = await prefs.loadSettings(db, author);
  if (settings.mutedChats.includes(chatId)) return { skipped: 'muted' };
  const blocked = prefs.blockedReason(settings, 'messages', notify.now(services));
  if (blocked) return { skipped: blocked };
  if (await social.isBlocked(db, author, reactorId)) return { skipped: 'blocked' };
  const lang = i18n.languageOf(settings);
  const reactor = await db.collection('users').doc(reactorId).get();
  const name =
    (reactor.exists && (reactor.get('name') || reactor.get('username'))) || i18n.t(lang, 'someone');
  const emoji = social.REACTIONS[type];
  const text = notify.shorten(String(after.text || ''));
  const body = settings.notifications.preview
    ? i18n.t(lang, 'messageReactionText', { emoji, text })
    : i18n.t(lang, 'messageReaction', { emoji });
  return notify.sendToUser(services, author, (token) =>
    notify.chatMessage(
      { senderName: name, senderId: reactorId, chatId, messageId, body },
      token,
      prefs.alertOf(settings),
    ),
  );
}

module.exports = { onMessageDeleted, onGroupInvite, onMessageReacted };
