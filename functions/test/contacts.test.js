// Tests for lib/contacts.js on the Firestore emulator started by
// `npm run test:emulate` (project demo-later-functions). Auth is faked.
'use strict';

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const { ctx, addUser, setSettings } = require('./helpers');
const contacts = require('../lib/contacts');

const fakeAuth = (accounts) => ({
  async getUser(uid) {
    if (!accounts[uid]) throw new Error('auth/user-not-found');
    return { uid, ...accounts[uid] };
  },
});

const on = { privacy: { findByContacts: true } };
const off = { privacy: { findByContacts: false } };

describe('contact suggestions', () => {
  const db = () => ctx.db;
  const auth = fakeAuth({
    anna: { email: 'Anna@Example.com ', emailVerified: true },
    ben: { email: 'ben@example.com', emailVerified: false },
    carl: { email: 'carl@example.com', emailVerified: true },
  });
  const index = async () => (await db().collection('contactIndex').get()).docs.map((d) => d.get('uid'));

  test('the hash is the app\'s: salted SHA-256 of the lower-case email', () => {
    assert.equal(contacts.hashEmail(' ANNA@example.com'), contacts.hashEmail('anna@example.com'));
    assert.match(contacts.hashEmail('x@y.z'), /^[0-9a-f]{64}$/);
  });

  test('only verified emails of people who opted in are indexed, and removed again', async () => {
    assert.deepEqual(await contacts.syncContactIndex({ db: db(), auth }, 'anna', off, on), { changed: true, indexed: true });
    const unverified = await contacts.syncContactIndex({ db: db(), auth }, 'ben', {}, on);
    assert.equal(unverified.reason, 'unverified');
    assert.deepEqual(await contacts.syncContactIndex({ db: db(), auth }, 'anna', on, on), { changed: false }, 'other settings changed');
    assert.deepEqual(await index(), ['anna']);
    await contacts.syncContactIndex({ db: db(), auth }, 'anna', on, off);
    assert.deepEqual(await index(), []);
  });

  test('matches people who allow it, never yourself or a block; hashes dropped', async () => {
    for (const uid of ['me', 'anna', 'carl', 'dora']) await addUser(uid);
    await setSettings('anna', on);
    await setSettings('carl', on);
    await setSettings('dora', off); // indexed once, then switched off
    await contacts.syncContactIndex({ db: db(), auth }, 'anna', {}, on);
    await contacts.syncContactIndex({ db: db(), auth }, 'carl', {}, on);
    await db().doc(`contactIndex/${contacts.hashEmail('dora@example.com')}`).set({ uid: 'dora' });
    await db().doc(`contactIndex/${contacts.hashEmail('me@example.com')}`).set({ uid: 'me' });
    await db().doc('users/carl/blocked/me').set({ blockedAt: new Date() });

    const hashes = ['anna@example.com', 'carl@example.com', 'dora@example.com', 'me@example.com', 'nobody@example.com']
      .map(contacts.hashEmail);
    const result = await contacts.matchContacts({ db: db() }, 'me', {
      status: 'pending',
      hashes: [...hashes, 'not-a-hash', hashes[0]],
    });
    assert.deepEqual(result, { matched: 1, checked: 5 });
    const doc = (await db().doc('contactMatches/me').get()).data();
    assert.equal(doc.status, 'done');
    assert.deepEqual(doc.matches, ['anna']);
    assert.equal(doc.hashes, undefined, 'the contacts are not kept');

    // Its own answer does not run again.
    assert.deepEqual(await contacts.matchContacts({ db: db() }, 'me', doc), { matched: 0 });
  });
});
