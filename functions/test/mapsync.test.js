// lib/mapsync.js: deleted capsules recorded for the map's sync.
'use strict';

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const { ctx } = require('./helpers');
const mapsync = require('../lib/mapsync');

const noon = () => new Date(Date.UTC(2026, 9, 19, 12, 0));
const services = () => ({ db: ctx.db, now: noon });
const deletion = async (id) => (await ctx.db.collection('capsule_deletions').doc(id).get()).data();

describe('capsule deletions for the map', () => {
  test('friends-only and public capsules are recorded with their owner and privacy', async () => {
    await mapsync.onCapsuleDeleted(services(), 'f1', { ownerId: 'bob', privacy: 'friends', title: 'Lake' });
    await mapsync.onCapsuleDeleted(services(), 'p1', { ownerId: 'carol', privacy: 'public' });
    const friends = await deletion('f1');
    assert.equal(friends.ownerId, 'bob');
    assert.equal(friends.privacy, 'friends');
    assert.ok(friends.deletedAt, 'server time');
    // Nothing else of the capsule.
    assert.deepEqual(Object.keys(friends).sort(), ['deletedAt', 'expireAt', 'ownerId', 'privacy']);
    assert.equal((await deletion('p1')).privacy, 'public');
  });

  test(`kept ${mapsync.KEEP_DAYS} days (the TTL policy reads expireAt)`, async () => {
    await mapsync.onCapsuleDeleted(services(), 'p2', { ownerId: 'carol', privacy: 'public' });
    const days = ((await deletion('p2')).expireAt.toMillis() - noon().getTime()) / (24 * 3600 * 1000);
    assert.equal(days, mapsync.KEEP_DAYS);
  });

  test('a private capsule leaves no record', async () => {
    const result = await mapsync.onCapsuleDeleted(services(), 'x1', { ownerId: 'bob', privacy: 'private' });
    assert.equal(result, null);
    assert.equal(await deletion('x1'), undefined);
    assert.equal(await mapsync.onCapsuleDeleted(services(), 'x2', undefined), null);
  });
});
