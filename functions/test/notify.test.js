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
    assert.equal(messaging.sent[0].android.notification.channelId, 'activity');
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

const prefs = require('../lib/prefs');
const account = require('../lib/account');

/** Fixed clock: 2026-10-16 12:00 UTC. */
const noon = () => new Date(Date.UTC(2026, 9, 16, 12, 0));

async function setSettings(uid, data) {
  await users().doc(uid).collection('settings').doc('app').set(data);
}

describe('notification preferences', () => {
  test('missing settings mean everything on, quiet hours off', () => {
    const s = prefs.normalize(undefined);
    assert.equal(s.notifications.enabled, true);
    assert.equal(s.notifications.messages, true);
    assert.equal(s.notifications.quietHours.enabled, false);
    assert.deepEqual(s.mutedChats, []);
    assert.equal(prefs.blockedReason(s, 'messages', noon()), null);
  });

  test('quiet hours use local time and may span midnight', () => {
    const at = (h, m = 0) => new Date(Date.UTC(2026, 9, 16, h, m));
    const n = (start, end, offset = 0) =>
      prefs.normalize({ notifications: { quietHours: { enabled: true, start, end }, utcOffsetMinutes: offset } }).notifications;
    // 22:00-07:00 in UTC+2: 21:30 UTC is 23:30 local (quiet), 06:00 UTC is 08:00 local (not).
    assert.equal(prefs.inQuietHours(n(22 * 60, 7 * 60, 120), at(21, 30)), true);
    assert.equal(prefs.inQuietHours(n(22 * 60, 7 * 60, 120), at(6)), false);
    // Same-day window 13:00-15:00 UTC.
    assert.equal(prefs.inQuietHours(n(13 * 60, 15 * 60), at(14)), true);
    assert.equal(prefs.inQuietHours(n(13 * 60, 15 * 60), at(15)), false);
    // start == end means no quiet hours.
    assert.equal(prefs.inQuietHours(n(600, 600), at(10)), false);
  });

  test('bad values fall back to the defaults', () => {
    const s = prefs.normalize({ notifications: { enabled: 'no', quietHours: { start: 9999 }, utcOffsetMinutes: 99999 } });
    assert.equal(s.notifications.enabled, true);
    assert.equal(s.notifications.quietHours.start, 22 * 60);
    assert.equal(s.notifications.utcOffsetMinutes, 14 * 60);
  });

  test('channels: one per kind, a silent one when sound is off', () => {
    assert.equal(prefs.channelFor('messages', true), 'messages');
    assert.equal(prefs.channelFor('messages', false), 'messages_silent');
    assert.equal(prefs.channelFor('follows', true), 'activity');
    assert.equal(prefs.channelFor('capsules', false), 'activity_silent');
  });
});

describe('message notifications', () => {
  const chatId = 'alice_bob';
  const services = (messaging) => ({ db, messaging, now: noon });

  beforeEach(async () => {
    await addUser('alice', { name: 'Alice' }, ['a1']);
    await addUser('bob', { name: 'Bob' }, ['b1']);
  });

  test('the other participant gets the text, tagged by chat', async () => {
    const messaging = fakeMessaging();
    const result = await notify.onMessageCreated(services(messaging), chatId, 'm1', {
      senderId: 'alice',
      text: 'Hi Bob',
    });
    assert.equal(result.sent, 1);
    const [push] = messaging.sent;
    assert.equal(push.token, 'b1');
    assert.equal(push.notification.title, 'Alice');
    assert.equal(push.notification.body, 'Hi Bob');
    assert.deepEqual(
      { type: push.data.type, chatId: push.data.chatId, userId: push.data.userId },
      { type: 'message', chatId, userId: 'alice' },
    );
    assert.equal(push.android.notification.channelId, 'messages');
    assert.equal(push.android.notification.tag, chatId);
  });

  test('a group message goes to every other member, each by their settings', async () => {
    await addUser('carol', { name: 'Carol' }, ['c1']);
    await addUser('dave', { name: 'Dave' }, ['d1']);
    await setSettings('dave', { mutedChats: ['g_trip12345678'] });
    await setSettings('carol', { language: 'ru' });
    await db.doc('chats/g_trip12345678').set({ name: 'Trip', members: ['alice', 'bob', 'carol', 'dave'] });
    const messaging = fakeMessaging();
    const report = await notify.onMessageCreated(services(messaging), 'g_trip12345678', 'm1', {
      senderId: 'alice',
      text: 'Tomorrow at 9',
    });
    assert.deepEqual(Object.keys(report).sort(), ['bob', 'carol', 'dave']);
    assert.deepEqual(report.dave, { skipped: 'muted' });
    assert.deepEqual(messaging.sent.map((m) => m.token).sort(), ['b1', 'c1']);
    const [push] = messaging.sent;
    assert.equal(push.notification.title, 'Trip');
    assert.equal(push.notification.body, 'Alice: Tomorrow at 9');
    assert.equal(push.data.chatId, 'g_trip12345678');

    // Not a member, or no such group: nobody.
    assert.equal(await notify.onMessageCreated(services(fakeMessaging()), 'g_trip12345678', 'm2', { senderId: 'erin', text: 'x' }), null);
    assert.equal(await notify.onMessageCreated(services(fakeMessaging()), 'g_none12345678', 'm3', { senderId: 'alice', text: 'x' }), null);
  });

  test('long texts are shortened; capsules say so', () => {
    assert.equal(notify.messageBody({ text: 'x'.repeat(200) }, true).length, 150);
    assert.equal(notify.messageBody({ type: 'capsule', text: 'Trip' }, true), 'Sent you a capsule: Trip');
    // Photos: the caption after a camera sign, or a line saying what it is.
    assert.equal(notify.messageBody({ type: 'image', text: '📷' }, true), 'Sent you a photo');
    assert.equal(notify.messageBody({ type: 'image', text: 'Look!' }, true), '📷 Look!');
    assert.equal(notify.messageBody({ type: 'image', text: 'Look!' }, false, 'ru'), 'Фото для вас');
  });

  test('no preview, no sound: neutral text on the silent channel', async () => {
    await setSettings('bob', { notifications: { preview: false, sound: false } });
    const messaging = fakeMessaging();
    await notify.onMessageCreated(services(messaging), chatId, 'm1', { senderId: 'alice', text: 'secret' });
    const [push] = messaging.sent;
    assert.equal(push.notification.body, 'New message');
    assert.equal(push.android.notification.channelId, 'messages_silent');
    assert.equal(push.android.notification.sound, undefined);
  });

  test('muted chat, messages off, everything off or quiet hours: no push', async () => {
    const send = async () => {
      const messaging = fakeMessaging();
      const result = await notify.onMessageCreated(services(messaging), chatId, 'm1', { senderId: 'alice', text: 'x' });
      return { result, sent: messaging.sent.length };
    };
    await setSettings('bob', { mutedChats: [chatId] });
    assert.deepEqual(await send(), { result: { skipped: 'muted' }, sent: 0 });
    await setSettings('bob', { notifications: { messages: false } });
    assert.deepEqual(await send(), { result: { skipped: 'messages off' }, sent: 0 });
    await setSettings('bob', { notifications: { enabled: false } });
    assert.deepEqual(await send(), { result: { skipped: 'disabled' }, sent: 0 });
    await setSettings('bob', { notifications: { quietHours: { enabled: true, start: 11 * 60, end: 13 * 60 } } });
    assert.deepEqual(await send(), { result: { skipped: 'quiet hours' }, sent: 0 });
  });

  test('senders outside the chat id are ignored', async () => {
    const messaging = fakeMessaging();
    assert.equal(await notify.onMessageCreated(services(messaging), chatId, 'm1', { senderId: 'carol', text: 'x' }), null);
    assert.equal(messaging.sent.length, 0);
  });
});

describe('preferences for follow and capsule pushes', () => {
  test('follow pushes respect "new followers" off', async () => {
    await addUser('alice', {}, ['a1']);
    await setSettings('alice', { notifications: { follows: false } });
    const messaging = fakeMessaging();
    const result = await notify.onNotificationCreated({ db, messaging, now: noon }, 'alice', { type: 'follow', fromUserId: 'bob' });
    assert.deepEqual(result, { skipped: 'follows off' });
    assert.equal(messaging.sent.length, 0);
  });

  test('capsule pushes skip users who turned them off; the in-app notice stays', async () => {
    await addUser('owner');
    await addUser('fan', {}, ['f1']);
    await follow('fan', 'owner');
    await setSettings('fan', { notifications: { capsules: false } });
    const messaging = fakeMessaging();
    const result = await notify.onCapsuleCreated({ db, messaging, now: noon }, 'c1', { ownerId: 'owner', privacy: 'public' });
    assert.equal(result.recipients, 1);
    assert.equal(messaging.sent.length, 0);
    const inApp = await users().doc('fan').collection('notifications').get();
    assert.equal(inApp.size, 1);
  });
});

describe('account deletion cleanup', () => {
  test('removes the account everywhere and leaves others intact', async () => {
    await addUser('gone', { username: 'gone', friends: ['bob'] }, ['g1']);
    await addUser('bob', { friends: ['gone', 'carol'] });
    await addUser('carol');
    await db.collection('usernames').doc('gone').set({ uid: 'gone' });
    await db.collection('friend_requests').doc('gone_carol').set({ fromUserId: 'gone', toUserId: 'carol' });
    await db.collection('friend_requests').doc('bob_carol').set({ fromUserId: 'bob', toUserId: 'carol' });
    await follow('carol', 'gone');
    await follow('gone', 'bob');
    await db.collection('capsules').doc('c1').set({ ownerId: 'gone', title: 'x' });
    await db.collection('capsules').doc('c2').set({ ownerId: 'bob', title: 'y' });
    await db.doc('chats/bob_gone').set({ participants: ['gone', 'bob'], lastMessage: 'hi' });
    await db.doc('chats/bob_gone/messages/m1').set({ senderId: 'gone', text: 'hi' });
    await setSettings('gone', { mutedChats: [] });
    await bucket.file('userdata/gone/assets/images/profile_image').save('x');
    await bucket.file('userdata/bob/assets/images/profile_image').save('y');
    await bucket.file('chats/bob_gone/bob/p1.jpg').save('z');
    await db.doc('chats/g_group1234567').set({ name: 'G', members: ['gone', 'bob', 'carol'] });
    await bucket.file('chats/bob_carol/bob/p2.jpg').save('z');

    const report = await account.deleteUserData({ db, bucket }, 'gone');
    assert.deepEqual(report, { friends: 1, requests: 1, follows: 2, capsules: 1, chats: 1, groups: 1, reactions: 0, comments: 0 });
    assert.deepEqual((await db.doc('chats/g_group1234567').get()).get('members'), ['bob', 'carol']);

    assert.equal((await users().doc('gone').get()).exists, false);
    assert.equal((await users().doc('gone').collection('settings').doc('app').get()).exists, false);
    assert.deepEqual((await users().doc('bob').get()).get('friends'), ['carol']);
    assert.equal((await db.collection('usernames').doc('gone').get()).exists, false);
    assert.equal((await db.collection('friend_requests').doc('gone_carol').get()).exists, false);
    assert.equal((await db.collection('friend_requests').doc('bob_carol').get()).exists, true);
    assert.equal((await users().doc('carol').collection('following').doc('gone').get()).exists, false);
    assert.equal((await users().doc('bob').collection('followers').doc('gone').get()).exists, false);
    assert.equal((await db.collection('capsules').doc('c1').get()).exists, false);
    assert.equal((await db.collection('capsules').doc('c2').get()).exists, true);
    assert.equal((await db.doc('chats/bob_gone').get()).exists, false);
    assert.equal((await db.doc('chats/bob_gone/messages/m1').get()).exists, false);
    assert.equal((await bucket.file('userdata/gone/assets/images/profile_image').exists())[0], false);
    assert.equal((await bucket.file('userdata/bob/assets/images/profile_image').exists())[0], true);
    assert.equal((await bucket.file('chats/bob_gone/bob/p1.jpg').exists())[0], false);
    assert.equal((await bucket.file('chats/bob_carol/bob/p2.jpg').exists())[0], true);

    // Running it again is harmless.
    await account.deleteUserData({ db, bucket }, 'gone');
  });

  test('refuses an invalid uid', async () => {
    await assert.rejects(account.deleteUserData({ db, bucket }, '../x'));
  });
});
