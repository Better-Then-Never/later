// Runs the admin scripts against throwaway emulators (`npm run selftest`).
'use strict';

const assert = require('node:assert/strict');
const { init } = require('./common');
const { setAdmin } = require('./set-admin');
const { setVerified } = require('./set-verified');

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
  console.log('admin scripts: all checks passed');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
