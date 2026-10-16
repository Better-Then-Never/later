// Runs the migration on the emulator against legacy-shaped documents.
//   firebase emulators:exec --config firebase.json --project demo-later-migrations "npm test"
'use strict';

const { test, before } = require('node:test');
const assert = require('node:assert/strict');
const admin = require('firebase-admin');
const { migrateUsers, migrateCapsules } = require('./migrate');

let db;
const quiet = () => {};

before(async () => {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'emulator only');
  admin.initializeApp({ projectId: 'demo-later-migrations' });
  db = admin.firestore();
  const users = db.collection('users');
  await users.doc('a').set({ name: 'A', username: 'Alice', email: 'a@x.y', fcmToken: 'tokA', friends: [] });
  await users.doc('b').set({ name: 'B', username: 'bob', friends: [] });
  await users.doc('c').set({ name: 'C', username: 'ALICE', friends: [] });
  await users.doc('d').set({ name: 'D', username: 'not valid!', friends: [] });
  await db.collection('usernames').doc('bob').set({ uid: 'b' });
  await db.collection('capsules').doc('old').set({ creatorId: 'a', title: 'x' });
  await db.collection('capsules').doc('ok').set({ ownerId: 'b', privacy: 'public', createdAt: new Date() });
});

test('a dry run changes nothing', async () => {
  const report = await migrateUsers(db, { apply: false, log: quiet });
  assert.equal(report.reserved, 1, 'alice only: bob is already reserved, ALICE conflicts');
  assert.equal((await db.collection('users').doc('a').get()).get('email'), 'a@x.y');
});

test('apply: lower-case + reserve, private fields out, token moved, conflicts reported', async () => {
  const report = await migrateUsers(db, { apply: true, log: quiet });
  const a = (await db.collection('users').doc('a').get()).data();
  assert.equal(a.username, 'alice');
  assert.equal(a.email, undefined);
  assert.equal(a.fcmToken, undefined);
  assert.equal((await db.collection('usernames').doc('alice').get()).get('uid'), 'a');
  assert.ok((await db.doc('users/a/fcmTokens/tokA').get()).exists);
  assert.equal(report.conflicts.length, 2, 'ALICE (taken) and "not valid!"');
  assert.equal((await db.collection('users').doc('c').get()).get('username'), 'ALICE');
});

test('capsules get an owner, a privacy and a creation time', async () => {
  const report = await migrateCapsules(db, { apply: true, log: quiet });
  assert.equal(report.fixed, 1);
  const old = (await db.collection('capsules').doc('old').get()).data();
  assert.equal(old.ownerId, 'a');
  assert.equal(old.privacy, 'friends');
  assert.ok(old.createdAt);
});

test('running it again finds nothing more to do', async () => {
  const users = await migrateUsers(db, { apply: true, log: quiet });
  const capsules = await migrateCapsules(db, { apply: true, log: quiet });
  assert.equal(users.reserved + users.lowercased + users.privateFieldsRemoved, 0);
  assert.equal(capsules.fixed, 0);
});
