// Tests for lib/chats.js on the Storage emulator started by
// `npm run test:emulate` (project demo-later-functions).
'use strict';

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const { ctx, addUser } = require('./helpers');
const chats = require('../lib/chats');

const exists = async (path) => (await ctx.bucket.file(path).exists())[0];

describe('group invites', () => {
  const G = 'g_trip12345678';
  const db = () => ctx.db;
  const invite = async (uid, by) => {
    await db().doc(`chats/${G}/invites/${uid}`).set({ by });
    return chats.onGroupInvite({ db: db() }, G, uid, { by });
  };
  const members = async () => (await db().doc(`chats/${G}`).get()).get('members');

  test("a friend of the inviter joins; others do not; the invite goes either way", async () => {
    await addUser('alice', { friends: ['bob', 'carol'] });
    await addUser('bob', { friends: ['alice'] });
    await addUser('carol', { friends: ['alice'] });
    await addUser('dave', { friends: ['erin'] });
    await addUser('erin', { friends: ['dave'] });
    await db().doc(`chats/${G}`).set({ name: 'Trip', members: ['alice'], createdBy: 'alice' });

    assert.deepEqual(await invite('bob', 'alice'), { bob: 'joined' });
    assert.deepEqual(await members(), ['alice', 'bob']);
    assert.deepEqual(await invite('dave', 'bob'), { dave: 'not-a-friend' });
    assert.deepEqual(await invite('bob', 'alice'), { bob: 'already-in' });
    assert.deepEqual(await invite('carol', 'erin'), { carol: 'not-a-member' });
    assert.deepEqual(await invite('ghost', 'alice'), { ghost: 'no-account' });
    assert.equal((await db().collection(`chats/${G}/invites`).get()).size, 0);

    // Carol blocked Bob, who is in it: she is not put next to him.
    await db().doc('users/carol/blocked/bob').set({ at: 1 });
    assert.deepEqual(await invite('carol', 'alice'), { carol: 'blocked' });
    assert.deepEqual(await members(), ['alice', 'bob']);
  });

  test('a full group takes nobody', async () => {
    const full = Array.from({ length: 20 }, (_, i) => `u${i}`);
    await addUser('u0', { friends: ['newbie'] });
    await addUser('newbie', { friends: ['u0'] });
    await db().doc(`chats/${G}`).set({ name: 'Big', members: full, createdBy: 'u0' });
    assert.deepEqual(await invite('newbie', 'u0'), { newbie: 'full' });
  });
});

describe('chat photos', () => {
  test("a deleted photo message takes its file along; nothing else is touched", async () => {
    const { bucket } = ctx;
    await bucket.file('chats/alice_bob/alice/p1.jpg').save('jpg');
    await bucket.file('chats/alice_bob/alice/p2.jpg').save('jpg');

    const result = await chats.onMessageDeleted({ bucket }, 'alice_bob', {
      type: 'image',
      imagePath: 'chats/alice_bob/alice/p1.jpg',
    });
    assert.deepEqual(result, { deleted: 'chats/alice_bob/alice/p1.jpg' });
    assert.equal(await exists('chats/alice_bob/alice/p1.jpg'), false);
    assert.equal(await exists('chats/alice_bob/alice/p2.jpg'), true);

    // Already gone (deleted by the app): fine.
    await chats.onMessageDeleted({ bucket }, 'alice_bob', {
      type: 'image',
      imagePath: 'chats/alice_bob/alice/p1.jpg',
    });
  });

  test('a deleted voice message takes its recording along', async () => {
    const { bucket } = ctx;
    await bucket.file('chats/alice_bob/bob/v1.m4a').save('aac');
    assert.deepEqual(
      await chats.onMessageDeleted({ bucket }, 'alice_bob', { type: 'voice', audioPath: 'chats/alice_bob/bob/v1.m4a' }),
      { deleted: 'chats/alice_bob/bob/v1.m4a' },
    );
    assert.equal(await exists('chats/alice_bob/bob/v1.m4a'), false);
  });

  test('text messages and paths outside the chat are ignored', async () => {
    const { bucket } = ctx;
    await bucket.file('chats/alice_carol/alice/p3.jpg').save('jpg');
    await bucket.file('userdata/alice/capsules/c1/image.jpg').save('jpg');
    const ignored = [
      { type: 'text', text: 'hi' },
      { type: 'image', imagePath: 'chats/alice_carol/alice/p3.jpg' },
      { type: 'image', imagePath: 'chats/alice_bob/../alice_carol/alice/p3.jpg' },
      { type: 'image', imagePath: 'userdata/alice/capsules/c1/image.jpg' },
      { type: 'image' },
      undefined,
    ];
    for (const message of ignored) {
      assert.equal(await chats.onMessageDeleted({ bucket }, 'alice_bob', message), null);
    }
    assert.equal(await exists('chats/alice_carol/alice/p3.jpg'), true);
    assert.equal(await exists('userdata/alice/capsules/c1/image.jpg'), true);
  });
});
