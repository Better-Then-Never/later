// Chat housekeeping: a photo's file goes with its message; people join a
// group through an invite this code checks.
'use strict';

const { FieldValue } = require('firebase-admin/firestore');

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

module.exports = { onMessageDeleted, onGroupInvite };
