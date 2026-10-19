// The map's sync (docs/map/COLD_START.md, "Delta sync"): the phone keeps the
// pins it last showed and asks only for what changed since. Capsules are
// never edited (firestore.rules), so a change is a new capsule (its
// createdAt, set by the server) or a deleted one: recorded here for
// friends-only and public capsules, readable by whoever could see the
// capsule (rules). A private capsule's only readers are its owner and
// co-authors, whose own lists on the map follow it already.
//
// Kept KEEP_DAYS days: a TTL policy deletes them by expireAt (deploy step in
// docs/map/COLD_START.md); a phone away longer reads everything again.
'use strict';

const { FieldValue, Timestamp } = require('firebase-admin/firestore');

const KEEP_DAYS = 30;

async function onCapsuleDeleted({ db, now = () => new Date() }, capsuleId, before) {
  if (!before) return null;
  const { ownerId, privacy } = before;
  if (privacy !== 'friends' && privacy !== 'public') return null;
  await db
    .collection('capsule_deletions')
    .doc(capsuleId)
    .set({
      ownerId,
      privacy,
      deletedAt: FieldValue.serverTimestamp(),
      expireAt: Timestamp.fromMillis(now().getTime() + KEEP_DAYS * 24 * 3600 * 1000),
    });
  return { capsuleId, privacy };
}

module.exports = { onCapsuleDeleted, KEEP_DAYS };
