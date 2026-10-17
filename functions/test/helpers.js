// Shared setup for the function tests on the emulators (`npm run test:emulate`,
// project demo-later-functions; nothing real is reachable). FCM is faked.
'use strict';

const { before, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const admin = require('firebase-admin');

const PROJECT = 'demo-later-functions';
const ctx = { db: null, bucket: null };

before(() => {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'run through `npm run test:emulate` (emulators only)');
  admin.initializeApp({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
  ctx.db = admin.firestore();
  ctx.bucket = admin.storage().bucket();
});

beforeEach(async () => {
  const res = await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  assert.ok(res.ok);
});

/** Records sent messages (sendEach for tokens, send for topics). */
function fakeMessaging() {
  const sent = [];
  const topics = [];
  return {
    sent,
    topics,
    async sendEach(messages) {
      sent.push(...messages);
      return {
        responses: messages.map(() => ({ success: true })),
        successCount: messages.length,
        failureCount: 0,
      };
    },
    async send(message) {
      topics.push(message);
      return 'projects/x/messages/1';
    },
  };
}

const users = () => ctx.db.collection('users');

async function addUser(uid, data = {}, tokens = []) {
  await users().doc(uid).set({ uid, name: uid.toUpperCase(), username: uid, friends: [], ...data });
  for (const t of tokens) {
    await users().doc(uid).collection('fcmTokens').doc(t).set({ token: t, platform: 'android' });
  }
}

async function setSettings(uid, data) {
  await users().doc(uid).collection('settings').doc('app').set(data);
}

module.exports = { ctx, fakeMessaging, users, addUser, setSettings, admin };
