// lib/locks.js: locked capsules queued, released, opened at their spot and
// cleaned up (capsule v3 B3, docs/capsule-v3/PHASE3_PLAN.md).
'use strict';

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const { GeoPoint, Timestamp } = require('firebase-admin/firestore');
const { ctx, fakeMessaging, addUser, setSettings } = require('./helpers');
const locks = require('../lib/locks');

const noon = () => new Date(Date.UTC(2026, 10, 1, 12, 0));
const hour = 3600 * 1000;
const services = (messaging = fakeMessaging(), now = noon) => ({ db: ctx.db, messaging, now });
const capsules = () => ctx.db.collection('capsules');
const schedule = (id) => ctx.db.collection(locks.SCHEDULE).doc(id);
const notifications = async (uid) =>
  (await ctx.db.collection('users').doc(uid).collection('notifications').get()).docs.map((d) => d.data());

// The spot: the Old Town square, Warsaw.
const SPOT = { lat: 52.2497, lng: 21.0122 };
const content = { imageUrl: 'https://img', thumbUrl: 'https://thumb', description: 'Hi' };

/** A sealed capsule of Alice and its sealed part. */
async function sealed(id, extra = {}) {
  const capsule = {
    ownerId: 'alice',
    title: 'Lake',
    privacy: 'friends',
    color: 'red',
    location: new GeoPoint(SPOT.lat, SPOT.lng),
    placeName: 'Old Town',
    createdAt: Timestamp.fromDate(new Date(noon().getTime() - 24 * hour)),
    openAt: Timestamp.fromDate(new Date(noon().getTime() + hour)),
    sealed: true,
    ...extra,
  };
  await capsules().doc(id).set(capsule);
  await capsules().doc(id).collection('sealed').doc('content').set(content);
  return capsule;
}

describe('queued for their date', () => {
  test('a sealed capsule for later is released then; a place one only announced', async () => {
    const later = Timestamp.fromDate(new Date(noon().getTime() + hour));
    assert.deepEqual(
      await locks.onCapsuleCreated(services(), 'd1', { sealed: true, openAt: later }),
      { queued: 'release' },
    );
    assert.equal((await schedule('d1').get()).get('kind'), 'release');
    await locks.onCapsuleCreated(services(), 'p1', { sealed: true, openWhere: 'here', openAt: later });
    assert.equal((await schedule('p1').get()).get('kind'), 'ready');
    // An older app's unsealed capsule for later still hears "is open".
    await locks.onCapsuleCreated(services(), 'o1', { imageUrl: 'https://img', openAt: later });
    assert.equal((await schedule('o1').get()).get('kind'), 'open');
  });

  test('a capsule open at once, or a place one without a date, is not queued', async () => {
    const before = Timestamp.fromDate(new Date(noon().getTime() - hour));
    assert.equal(await locks.onCapsuleCreated(services(), 'n1', { openAt: null }), null);
    assert.equal(await locks.onCapsuleCreated(services(), 'n2', { openAt: before }), null);
    assert.equal(
      await locks.onCapsuleCreated(services(), 'n3', { sealed: true, openWhere: 'here' }),
      null,
    );
    assert.equal((await ctx.db.collection(locks.SCHEDULE).get()).size, 0);
  });
});

describe('released when the date comes', () => {
  test('the photo and words go back into the capsule; its people hear it', async () => {
    await addUser('alice', { friends: ['bob'] }, ['ta']);
    await addUser('bob', { friends: ['alice'] }, ['tb']);
    await addUser('carol', {}, ['tc']);
    await sealed('c1', { coAuthors: ['bob'] });
    await schedule('c1').set({ openAt: Timestamp.fromDate(noon()), kind: 'release' });
    // Not due yet: nothing happens.
    await schedule('c2').set({ openAt: Timestamp.fromDate(new Date(noon().getTime() + hour)), kind: 'release' });
    const messaging = fakeMessaging();
    const report = await locks.releaseOpenedCapsules(services(messaging));
    assert.deepEqual(report, { released: 1, opened: 1, ready: 0, gone: 0 });

    const capsule = (await capsules().doc('c1').get()).data();
    assert.equal(capsule.imageUrl, 'https://img');
    assert.equal(capsule.thumbUrl, 'https://thumb');
    assert.equal(capsule.description, 'Hi');
    assert.equal(capsule.sealed, undefined);
    assert.equal((await capsules().doc('c1').collection('sealed').doc('content').get()).exists, false);
    assert.equal((await schedule('c1').get()).exists, false);
    assert.equal((await schedule('c2').get()).exists, true);

    // Alice and her co-author Bob, not Carol.
    assert.deepEqual(messaging.sent.map((m) => m.token).sort(), ['ta', 'tb']);
    assert.equal(messaging.sent[0].notification.title, 'Lake is open');
    assert.equal(messaging.sent[0].data.type, 'capsuleOpen');
    assert.equal(messaging.sent[0].data.capsuleId, 'c1');
    const [notice] = await notifications('bob');
    assert.equal(notice.type, 'capsuleOpen');
    assert.equal(notice.capsuleTitle, 'Lake');
    assert.equal((await notifications('carol')).length, 0);
  });

  test('a capsule sent to a friend: its recipient hears it, in their language', async () => {
    await addUser('alice', {}, ['ta']);
    await addUser('dan', {}, ['td']);
    await setSettings('dan', { language: 'de' });
    await sealed('g1', { privacy: 'private', sharedWith: ['alice', 'dan'] });
    await schedule('g1').set({ openAt: Timestamp.fromDate(noon()), kind: 'release' });
    const messaging = fakeMessaging();
    await locks.releaseOpenedCapsules(services(messaging));
    const toDan = messaging.sent.find((m) => m.token === 'td');
    assert.equal(toDan.notification.title, '„Lake“ ist offen');
  });

  test('a place capsule stays sealed and is announced as ready, with its place', async () => {
    await addUser('alice', {}, ['ta']);
    await sealed('p1', { openWhere: 'here' });
    await schedule('p1').set({ openAt: Timestamp.fromDate(noon()), kind: 'ready' });
    const messaging = fakeMessaging();
    const report = await locks.releaseOpenedCapsules(services(messaging));
    assert.deepEqual(report, { released: 0, opened: 0, ready: 1, gone: 0 });
    const capsule = (await capsules().doc('p1').get()).data();
    assert.equal(capsule.sealed, true);
    assert.equal(capsule.imageUrl, undefined);
    assert.equal(messaging.sent[0].notification.title, 'Lake is ready');
    assert.equal(messaging.sent[0].notification.body, "It's waiting in Old Town.");
    assert.equal(messaging.sent[0].data.type, 'capsuleReady');
  });

  test('capsule pushes turned off: the in-app notice only', async () => {
    await addUser('alice', {}, ['ta']);
    await setSettings('alice', { notifications: { capsules: false } });
    await sealed('q1');
    await schedule('q1').set({ openAt: Timestamp.fromDate(noon()), kind: 'release' });
    const messaging = fakeMessaging();
    await locks.releaseOpenedCapsules(services(messaging));
    assert.equal(messaging.sent.length, 0);
    assert.equal((await notifications('alice')).length, 1);
  });

  test('a capsule deleted before its date leaves nothing to do', async () => {
    await schedule('gone').set({ openAt: Timestamp.fromDate(noon()), kind: 'release' });
    const report = await locks.releaseOpenedCapsules(services());
    assert.deepEqual(report, { released: 0, opened: 0, ready: 0, gone: 1 });
    assert.equal((await schedule('gone').get()).exists, false);
  });
});

describe('opened at its spot', () => {
  const auth = (uid) => ({ uid });
  const at = (metresNorth, extra = {}) => ({
    capsuleId: 'p1',
    lat: SPOT.lat + metresNorth / 111320,
    lng: SPOT.lng,
    accuracy: 10,
    ...extra,
  });
  const refused = async (promise, code) => {
    await assert.rejects(promise, (e) => e instanceof locks.UnlockError && e.code === code);
  };
  const unlocked = async (uid, id = 'p1') =>
    (await ctx.db.collection('users').doc(uid).collection('unlocked').doc(id).get()).exists;

  test('within 150 m (plus the fix, at most 50 m) it opens and hands out the sealed part', async () => {
    await addUser('alice', { friends: ['bob'] });
    await addUser('bob', { friends: ['alice'] });
    await sealed('p1', { openWhere: 'here', openAt: null });
    const result = await locks.unlockCapsule(services(), auth('bob'), at(120));
    assert.deepEqual(result.content, content);
    assert.ok(Math.abs(result.distance - 120) <= 1);
    assert.equal(await unlocked('bob'), true);
    // 190 m with a 60 m fix: 150 + 50 at most.
    await sealed('p2', { openWhere: 'here', openAt: null });
    await locks.unlockCapsule(services(), auth('bob'), at(190, { capsuleId: 'p2', accuracy: 60 }));
    assert.equal(await unlocked('bob', 'p2'), true);
  });

  test('too far, too early, not a place capsule, or not yours to see: refused', async () => {
    await addUser('alice', { friends: ['bob'] });
    await addUser('bob', { friends: ['alice'] });
    await addUser('carol');
    await sealed('p1', { openWhere: 'here', openAt: null });
    await refused(locks.unlockCapsule(services(), auth('bob'), at(260, { accuracy: 200 })), 'out-of-range');
    await refused(locks.unlockCapsule(services(), auth('carol'), at(0)), 'not-found');
    await refused(locks.unlockCapsule(services(), null, at(0)), 'unauthenticated');
    await refused(locks.unlockCapsule(services(), auth('bob'), at(0, { capsuleId: 'nope' })), 'not-found');
    await refused(locks.unlockCapsule(services(), auth('bob'), at(0, { lat: 'x' })), 'invalid-argument');
    await sealed('p3', { openWhere: 'here' }); // its date is an hour away
    await refused(locks.unlockCapsule(services(), auth('bob'), at(0, { capsuleId: 'p3' })), 'failed-precondition');
    await sealed('d1'); // opens anywhere
    await refused(locks.unlockCapsule(services(), auth('bob'), at(0, { capsuleId: 'd1' })), 'failed-precondition');
    assert.equal(await unlocked('bob'), false);
    assert.equal(await unlocked('carol'), false);
  });

  test('distances on the Earth', () => {
    assert.ok(Math.abs(locks.distanceMetres(52, 21, 52.001, 21) - 111.2) < 0.5);
    assert.equal(locks.distanceMetres(SPOT.lat, SPOT.lng, SPOT.lat, SPOT.lng), 0);
  });
});

describe('cleaned up after deletion', () => {
  test('the sealed part, comments, reactions and the queue entry go too', async () => {
    await sealed('c1');
    await capsules().doc('c1').collection('comments').doc('m1').set({ text: 'x' });
    await capsules().doc('c1').collection('reactions').doc('bob').set({ type: 'heart' });
    await schedule('c1').set({ openAt: Timestamp.fromDate(noon()), kind: 'release' });
    await capsules().doc('c1').delete();
    await locks.onCapsuleDeleted(services(), 'c1');
    for (const sub of ['sealed', 'comments', 'reactions']) {
      assert.equal((await capsules().doc('c1').collection(sub).get()).size, 0, sub);
    }
    assert.equal((await schedule('c1').get()).exists, false);
  });
});
