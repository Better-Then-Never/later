// Removes everything a deleted account leaves behind (the Auth user is
// already gone when this runs). Idempotent: running it twice is harmless.
'use strict';

const { FieldValue } = require('firebase-admin/firestore');

const BATCH_LIMIT = 450;

async function deleteDocs(db, refs) {
  for (let i = 0; i < refs.length; i += BATCH_LIMIT) {
    const batch = db.batch();
    refs.slice(i, i + BATCH_LIMIT).forEach((ref) => batch.delete(ref));
    await batch.commit();
  }
}

/**
 * Deletes the data of [uid]: profile and its subcollections, username
 * reservation, capsules and every Storage file under userdata/{uid}/, chats
 * (with their messages), friend requests, and the user's entries in other
 * users' friend lists, followers and following. Returns counts for logs.
 */
async function deleteUserData({ db, bucket }, uid) {
  if (typeof uid !== 'string' || !/^[A-Za-z0-9]{1,128}$/.test(uid)) {
    throw new Error('invalid uid');
  }
  const userRef = db.collection('users').doc(uid);
  const user = await userRef.get();
  const data = user.exists ? user.data() : {};
  const report = { friends: 0, requests: 0, follows: 0, capsules: 0, chats: 0 };

  // Other users' friend lists.
  const friends = Array.isArray(data.friends) ? data.friends.filter((f) => typeof f === 'string') : [];
  for (let i = 0; i < friends.length; i += BATCH_LIMIT) {
    const batch = db.batch();
    for (const friend of friends.slice(i, i + BATCH_LIMIT)) {
      batch.set(db.collection('users').doc(friend), { friends: FieldValue.arrayRemove(uid) }, { merge: true });
    }
    await batch.commit();
  }
  report.friends = friends.length;

  // Friend requests in both directions.
  const requests = await Promise.all([
    db.collection('friend_requests').where('fromUserId', '==', uid).get(),
    db.collection('friend_requests').where('toUserId', '==', uid).get(),
  ]);
  const requestRefs = requests.flatMap((q) => q.docs.map((d) => d.ref));
  await deleteDocs(db, requestRefs);
  report.requests = requestRefs.length;

  // The other side of follows: users/{x}/following/{uid} and
  // users/{y}/followers/{uid}.
  const [followers, following] = await Promise.all([
    userRef.collection('followers').get(),
    userRef.collection('following').get(),
  ]);
  const followRefs = [
    ...followers.docs.map((d) => db.collection('users').doc(d.id).collection('following').doc(uid)),
    ...following.docs.map((d) => db.collection('users').doc(d.id).collection('followers').doc(uid)),
  ];
  await deleteDocs(db, followRefs);
  report.follows = followRefs.length;

  // Capsules (documents here, images with the Storage prefix below).
  const capsules = await db.collection('capsules').where('ownerId', '==', uid).get();
  await deleteDocs(db, capsules.docs.map((d) => d.ref));
  report.capsules = capsules.size;

  // Chats with their messages (the other participant loses them too: the
  // conversation partner no longer exists).
  const chats = await db.collection('chats').where('participants', 'array-contains', uid).get();
  for (const chat of chats.docs) {
    await db.recursiveDelete(chat.ref);
  }
  report.chats = chats.size;

  // Username reservation, if it is still this user's.
  if (typeof data.username === 'string' && data.username) {
    const reservation = db.collection('usernames').doc(data.username);
    const res = await reservation.get();
    if (res.exists && res.get('uid') === uid) await reservation.delete();
  }

  // Profile with every subcollection (tokens, notifications, follows,
  // blocks, settings) and all files.
  await db.recursiveDelete(userRef);
  await bucket.deleteFiles({ prefix: `userdata/${uid}/` });
  return report;
}

module.exports = { deleteUserData };
