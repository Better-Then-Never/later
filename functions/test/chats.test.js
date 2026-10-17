// Tests for lib/chats.js on the Storage emulator started by
// `npm run test:emulate` (project demo-later-functions).
'use strict';

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const { ctx } = require('./helpers');
const chats = require('../lib/chats');

const exists = async (path) => (await ctx.bucket.file(path).exists())[0];

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
