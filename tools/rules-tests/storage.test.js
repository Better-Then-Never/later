// Storage security rules tests (local emulator only).
const { test, before, after, describe } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { ref, uploadBytes, getBytes, deleteObject } = require('firebase/storage');

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-later-rules',
    storage: {
      rules: fs.readFileSync(path.join(__dirname, '../../storage.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 9299,
    },
  });
});

after(() => env.cleanup());

const storage = (uid) =>
  (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).storage();
const jpeg = { contentType: 'image/jpeg' };
const bytes = (n = 64) => new Uint8Array(n);

describe('profile images', () => {
  test('owner uploads the three known images as image/*', async () => {
    const s = storage('alice');
    for (const name of ['profile_image', 'profile_image_small', 'background_image']) {
      await assertSucceeds(uploadBytes(ref(s, `userdata/alice/assets/images/${name}`), bytes(), jpeg));
    }
  });

  test('wrong owner, name, type or size is refused', async () => {
    await assertFails(uploadBytes(ref(storage('bob'), 'userdata/alice/assets/images/profile_image'), bytes(), jpeg));
    await assertFails(uploadBytes(ref(storage('alice'), 'userdata/alice/assets/images/other'), bytes(), jpeg));
    await assertFails(
      uploadBytes(ref(storage('alice'), 'userdata/alice/assets/images/profile_image'), bytes(), {
        contentType: 'application/octet-stream',
      }),
    );
    await assertFails(
      uploadBytes(ref(storage('alice'), 'userdata/alice/assets/images/profile_image'), bytes(6 * 1024 * 1024), jpeg),
    );
  });

  test('signed-in users read avatars; signed-out users do not', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      uploadBytes(ref(ctx.storage(), 'userdata/alice/assets/images/profile_image'), bytes(), jpeg),
    );
    await assertSucceeds(getBytes(ref(storage('bob'), 'userdata/alice/assets/images/profile_image')));
    await assertFails(getBytes(ref(storage(null), 'userdata/alice/assets/images/profile_image')));
  });

  test('owner deletes', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      uploadBytes(ref(ctx.storage(), 'userdata/alice/assets/images/background_image'), bytes(), jpeg),
    );
    await assertFails(deleteObject(ref(storage('bob'), 'userdata/alice/assets/images/background_image')));
    await assertSucceeds(deleteObject(ref(storage('alice'), 'userdata/alice/assets/images/background_image')));
  });
});

describe('chat photos', () => {
  const photo = (who, path = 'chats/alice_bob/alice/m1.jpg') => ref(storage(who), path);

  test('the sender uploads to their folder of the chat; both participants read', async () => {
    await assertSucceeds(uploadBytes(photo('alice'), bytes(), jpeg));
    await assertSucceeds(getBytes(photo('alice')));
    await assertSucceeds(getBytes(photo('bob')));
    await assertFails(getBytes(photo('carol')));
    await assertFails(getBytes(photo(null)));
  });

  test('not in your name, not in a chat you are not part of, only small jpegs', async () => {
    await assertFails(uploadBytes(photo('bob'), bytes(), jpeg));
    await assertFails(uploadBytes(photo('carol', 'chats/alice_bob/carol/m1.jpg'), bytes(), jpeg));
    await assertFails(uploadBytes(photo('alice', 'chats/alice/alice/m1.jpg'), bytes(), jpeg));
    await assertFails(uploadBytes(photo('alice', 'chats/alice_bob_carol/alice/m1.jpg'), bytes(), jpeg));
    await assertFails(uploadBytes(photo('alice', 'chats/alice_bob/alice/m1.png'), bytes(), jpeg));
    await assertFails(uploadBytes(photo('alice', 'chats/alice_bob/alice/m-1.jpg'), bytes(), jpeg));
    await assertFails(uploadBytes(photo('alice'), bytes(), { contentType: 'text/plain' }));
    await assertFails(uploadBytes(photo('alice'), new Uint8Array(5 * 1024 * 1024 + 1), jpeg));
  });

  test('voice messages: .m4a audio in the same folder', async () => {
    const m4a = { contentType: 'audio/mp4' };
    await assertSucceeds(uploadBytes(photo('alice', 'chats/alice_bob/alice/v1.m4a'), bytes(), m4a));
    await assertSucceeds(getBytes(photo('bob', 'chats/alice_bob/alice/v1.m4a')));
    await assertFails(uploadBytes(photo('alice', 'chats/alice_bob/alice/v2.m4a'), bytes(), jpeg));
    await assertFails(uploadBytes(photo('alice', 'chats/alice_bob/alice/v3.jpg'), bytes(), m4a));
    await assertFails(uploadBytes(photo('alice', 'chats/alice_bob/alice/v4.mp3'), bytes(), m4a));
    await assertFails(uploadBytes(photo('alice', 'chats/alice_bob/alice/v5.m4a'), new Uint8Array(5 * 1024 * 1024 + 1), m4a));
  });

  test('only the sender deletes; nobody replaces a sent photo', async () => {
    await assertSucceeds(uploadBytes(photo('alice', 'chats/alice_bob/alice/m2.jpg'), bytes(), jpeg));
    await assertFails(uploadBytes(photo('alice', 'chats/alice_bob/alice/m2.jpg'), bytes(), jpeg));
    await assertFails(deleteObject(photo('bob', 'chats/alice_bob/alice/m2.jpg')));
    await assertSucceeds(deleteObject(photo('alice', 'chats/alice_bob/alice/m2.jpg')));
  });
});

describe('capsule images', () => {
  test('owner writes image.jpg; others cannot read or write', async () => {
    await assertSucceeds(uploadBytes(ref(storage('alice'), 'userdata/alice/capsules/c1/image.jpg'), bytes(), jpeg));
    await assertFails(uploadBytes(ref(storage('alice'), 'userdata/alice/capsules/c1/other.png'), bytes(), jpeg));
    await assertFails(uploadBytes(ref(storage('bob'), 'userdata/alice/capsules/c2/image.jpg'), bytes(), jpeg));
    await assertFails(getBytes(ref(storage('bob'), 'userdata/alice/capsules/c1/image.jpg')));
    await assertSucceeds(getBytes(ref(storage('alice'), 'userdata/alice/capsules/c1/image.jpg')));
  });

  test('a loop capsule stores up to ten small frames', async () => {
    const frame = (n, who = 'alice') => ref(storage(who), `userdata/alice/capsules/c3/frame_${n}.jpg`);
    await assertSucceeds(uploadBytes(frame(0), bytes(), jpeg));
    await assertSucceeds(uploadBytes(frame(9), bytes(), jpeg));
    await assertFails(uploadBytes(frame(10), bytes(), jpeg));
    await assertFails(uploadBytes(frame('a'), bytes(), jpeg));
    await assertFails(uploadBytes(frame(1, 'bob'), bytes(), jpeg));
    await assertFails(uploadBytes(frame(2), new Uint8Array(3 * 1024 * 1024 + 1), jpeg));
  });

  test('a small thumbnail next to the photo', async () => {
    const thumb = (who = 'alice') => ref(storage(who), 'userdata/alice/capsules/c4/thumb.jpg');
    await assertSucceeds(uploadBytes(thumb(), bytes(), jpeg));
    await assertFails(uploadBytes(thumb('bob'), bytes(), jpeg));
    await assertFails(uploadBytes(thumb(), new Uint8Array(512 * 1024 + 1), jpeg));
  });

  test('everything else is closed', async () => {
    await assertFails(uploadBytes(ref(storage('alice'), 'chats/x.jpg'), bytes(), jpeg));
    await assertFails(uploadBytes(ref(storage('alice'), 'public/x.jpg'), bytes(), jpeg));
  });
});
