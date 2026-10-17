// Runs the admin scripts against throwaway emulators (`npm run selftest`).
'use strict';

const assert = require('node:assert/strict');
const { init } = require('./common');
const { setAdmin } = require('./set-admin');
const { setVerified } = require('./set-verified');
const { backfillCounts } = require('./backfill-counts');

(async () => {
  const { db, auth } = init([]);
  const user = await auth.createUser({ email: 'boss@later.test', password: 'emulator-only-123' });
  await db.doc('usernames/temka_ink').set({ uid: user.uid });
  await db.doc(`users/${user.uid}`).set({ uid: user.uid, username: 'temka_ink' });

  assert.deepEqual(await setAdmin(auth, 'boss@later.test'), { uid: user.uid, admin: true });
  assert.equal((await auth.getUser(user.uid)).customClaims.admin, true);
  await setAdmin(auth, user.uid, true);
  assert.equal((await auth.getUser(user.uid)).customClaims.admin, undefined);

  const dry = await setVerified(db, ['temka_ink', 'nobody'], { dryRun: true });
  assert.deepEqual(dry.missing, ['nobody']);
  assert.equal((await db.doc(`users/${user.uid}`).get()).get('verified'), undefined);
  await setVerified(db, ['temka_ink']);
  assert.equal((await db.doc(`users/${user.uid}`).get()).get('verified'), true);
  await setVerified(db, ['temka_ink'], { revoke: true });
  assert.equal((await db.doc(`users/${user.uid}`).get()).get('verified'), false);

  // Backfill: two followers, one following, two capsules (one public).
  await db.doc(`users/${user.uid}/followers/a`).set({ x: 1 });
  await db.doc(`users/${user.uid}/followers/b`).set({ x: 1 });
  await db.doc(`users/${user.uid}/following/c`).set({ x: 1 });
  await db.collection('capsules').add({ ownerId: user.uid, privacy: 'public' });
  await db.collection('capsules').add({ ownerId: user.uid, privacy: 'friends' });
  const dryRun = await backfillCounts(db, { dryRun: true });
  assert.equal(dryRun.changed, 1);
  assert.equal((await db.doc(`users/${user.uid}`).get()).get('followerCount'), undefined);
  await backfillCounts(db);
  const counted = (await db.doc(`users/${user.uid}`).get()).data();
  assert.equal(counted.followerCount, 2);
  assert.equal(counted.followingCount, 1);
  assert.deepEqual(counted.stats, { capsules: 2, publicCapsules: 1 });
  assert.equal((await backfillCounts(db)).changed, 0, 'running again changes nothing');

  console.log('admin scripts: all checks passed');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
