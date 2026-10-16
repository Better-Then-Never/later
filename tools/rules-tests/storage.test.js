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

describe('capsule images', () => {
  test('owner writes image.jpg; others cannot read or write', async () => {
    await assertSucceeds(uploadBytes(ref(storage('alice'), 'userdata/alice/capsules/c1/image.jpg'), bytes(), jpeg));
    await assertFails(uploadBytes(ref(storage('alice'), 'userdata/alice/capsules/c1/other.png'), bytes(), jpeg));
    await assertFails(uploadBytes(ref(storage('bob'), 'userdata/alice/capsules/c2/image.jpg'), bytes(), jpeg));
    await assertFails(getBytes(ref(storage('bob'), 'userdata/alice/capsules/c1/image.jpg')));
    await assertSucceeds(getBytes(ref(storage('alice'), 'userdata/alice/capsules/c1/image.jpg')));
  });

  test('everything else is closed', async () => {
    await assertFails(uploadBytes(ref(storage('alice'), 'public/x.jpg'), bytes(), jpeg));
  });
});
