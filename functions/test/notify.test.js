// Tests for lib/notify.js on the Firestore + Storage emulators started by
// `npm run test:emulate` (project demo-later-functions). FCM is faked.
'use strict';

const { test, before, beforeEach, describe } = require('node:test');
const assert = require('node:assert/strict');
const admin = require('firebase-admin');
const notify = require('../lib/notify');

const PROJECT = 'demo-later-functions';
let db;
let bucket;

before(() => {
  assert.ok(
    process.env.FIRESTORE_EMULATOR_HOST,
    'run through `npm run test:emulate` (emulators only)',
  );
  admin.initializeApp({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
  db = admin.firestore();
  bucket = admin.storage().bucket();
});

/** Records sent messages; tokens starting with "dead" fail as unregistered. */
function fakeMessaging() {
  const sent = [];
  return {
    sent,
    async sendEach(messages) {
      sent.push(...messages);
      const responses = messages.map((m) =>
        m.token.startsWith('dead')
          ? { success: false, error: { code: 'messaging/registration-token-not-registered' } }
          : { success: true },
      );
      return {
        responses,
        successCount: responses.filter((r) => r.success).length,
        failureCount: responses.filter((r) => !r.success).length,
      };
    },
  };
}

async function clearFirestore() {
  const res = await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  assert.ok(res.ok);
}

const users = () => db.collection('users');

async function addUser(uid, data = {}, tokens = []) {
  await users().doc(uid).set({ uid, name: uid.toUpperCase(), username: uid, friends: [], ...data });
  for (const t of tokens) {
    await users().doc(uid).collection('fcmTokens').doc(t).set({ token: t, platform: 'android' });
  }
}

async function follow(follower, target, notificationsEnabled = true) {
  await users().doc(follower).collection('following').doc(target).set({ notificationsEnabled });
  await users().doc(target).collection('followers').doc(follower).set({ followedAt: new Date() });
}

beforeEach(clearFirestore);

describe('tokens', () => {
  test('all devices plus the legacy field, without duplicates', async () => {
    await addUser('alice', { fcmToken: 'legacy' }, ['t1', 't2', 'legacy']);
    const tokens = (await notify.tokensFor(db, 'alice')).map((t) => t.token).sort();
    assert.deepEqual(tokens, ['legacy', 't1', 't2']);
  });

  test('dead tokens are removed, from the subcollection and the legacy field', async () => {
    await addUser('alice', { fcmToken: 'dead-legacy' }, ['t1', 'dead-1']);
    const messaging = fakeMessaging();
    const result = await notify.sendToUser({ db, messaging }, 'alice', (token) => ({ token }));
    assert.deepEqual(result, { sent: 1, failed: 2, pruned: 2 });
    const left = (await users().doc('alice').collection('fcmTokens').get()).docs.map((d) => d.id);
    assert.deepEqual(left, ['t1']);
    assert.equal((await users().doc('alice').get()).get('fcmToken'), undefined);
  });
});

describe('follow notifications', () => {
  test('a follow notification is pushed to every device of the user', async () => {
    await addUser('alice', {}, ['a1', 'a2']);
    const messaging = fakeMessaging();
    await notify.onNotificationCreated({ db, messaging }, 'alice', {
      type: 'follow',
      fromUserId: 'bob',
      fromUserName: 'bob',
    });
    assert.equal(messaging.sent.length, 2);
    assert.equal(messaging.sent[0].notification.body, 'bob started following you');
    assert.equal(messaging.sent[0].data.userId, 'bob');
    assert.equal(messaging.sent[0].android.notification.channelId, 'high_importance_channel');
  });

  test('other notification types are not pushed again', async () => {
    await addUser('alice', {}, ['a1']);
    const messaging = fakeMessaging();
    await notify.onNotificationCreated({ db, messaging }, 'alice', { type: 'capsule' });
    assert.equal(messaging.sent.length, 0);
  });
});

describe('capsule notifications (BUG-026, BUG-027)', () => {
  beforeEach(async () => {
    await addUser('owner', { friends: ['friendFollower'] });
    await addUser('friendFollower', {}, ['f1']);
    await addUser('follower', {}, ['p1']);
    await addUser('muted', {}, ['m1']);
    await addUser('noToken');
    await follow('friendFollower', 'owner');
    await follow('follower', 'owner');
    await follow('muted', 'owner', false);
    await follow('noToken', 'owner');
  });

  async function notified(uid) {
    return (await users().doc(uid).collection('notifications').get()).docs.map((d) => d.data());
  }

  test('public capsule: every follower with notifications on', async () => {
    const messaging = fakeMessaging();
    const result = await notify.onCapsuleCreated({ db, messaging }, 'c1', {
      ownerId: 'owner',
      privacy: 'public',
    });
    assert.equal(result.recipients, 3);
    assert.deepEqual(messaging.sent.map((m) => m.token).sort(), ['f1', 'p1']);
    assert.equal(messaging.sent[0].data.capsuleId, 'c1');
    assert.equal((await notified('noToken')).length, 1, 'in-app even without a token');
    assert.equal((await notified('muted')).length, 0);
    const [n] = await notified('follower');
    assert.equal(n.type, 'capsule');
    assert.equal(n.fromUserId, 'owner');
    assert.equal(n.capsuleId, 'c1');
  });

  test('friends-only capsule: only followers who are friends', async () => {
    const messaging = fakeMessaging();
    const result = await notify.onCapsuleCreated({ db, messaging }, 'c2', {
      ownerId: 'owner',
      privacy: 'friends',
    });
    assert.equal(result.recipients, 1);
    assert.deepEqual(messaging.sent.map((m) => m.token), ['f1']);
    assert.equal((await notified('follower')).length, 0);
  });

  test('private capsule: nobody', async () => {
    const messaging = fakeMessaging();
    const result = await notify.onCapsuleCreated({ db, messaging }, 'c3', {
      ownerId: 'owner',
      privacy: 'private',
    });
    assert.equal(result.recipients, 0);
    assert.equal(messaging.sent.length, 0);
  });

  test('legacy creatorId is still understood; no owner, no work', async () => {
    const messaging = fakeMessaging();
    const legacy = await notify.onCapsuleCreated({ db, messaging }, 'c4', {
      creatorId: 'owner',
      privacy: 'public',
    });
    assert.equal(legacy.recipients, 3);
    const none = await notify.onCapsuleCreated({ db, messaging }, 'c5', { privacy: 'public' });
    assert.equal(none.recipients, 0);
  });
});

describe('profile summary for the landing page (BUG-103)', () => {
  test('name and token URL of the small avatar; no email', async () => {
    await addUser('alice', { name: 'Alice Walker', email: 'alice@x.y' });
    await bucket.file('userdata/alice/assets/images/profile_image_small').save(Buffer.from('jpg'), {
      contentType: 'image/jpeg',
      metadata: { metadata: { firebaseStorageDownloadTokens: 'tok-123' } },
    });
    const summary = await notify.profileSummary({ db, bucket }, 'alice');
    assert.deepEqual(Object.keys(summary).sort(), ['displayName', 'photoURL']);
    assert.equal(summary.displayName, 'Alice Walker');
    assert.match(summary.photoURL, /profile_image_small\?alt=media&token=tok-123$/);
  });

  test('unknown users, bad ids and users without a picture', async () => {
    await addUser('bob');
    assert.equal(await notify.profileSummary({ db, bucket }, 'nobody'), null);
    assert.equal(await notify.profileSummary({ db, bucket }, '../etc'), null);
    assert.equal(await notify.profileSummary({ db, bucket }, undefined), null);
    assert.deepEqual(await notify.profileSummary({ db, bucket }, 'bob'), {
      displayName: 'BOB',
      photoURL: null,
    });
  });
});
