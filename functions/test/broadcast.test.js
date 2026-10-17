// lib/broadcast.js: admin-only announcements.
'use strict';

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const { ctx, fakeMessaging } = require('./helpers');
const broadcast = require('../lib/broadcast');

const admin = { uid: 'boss', token: { admin: true } };
const message = { title: { en: 'Hello', de: 'Hallo' }, body: { en: 'News!' } };

describe('announcements', () => {
  test('a normal user (or nobody) cannot send one', async () => {
    const messaging = fakeMessaging();
    for (const auth of [null, { uid: 'u', token: {} }, { uid: 'u', token: { admin: 'yes' } }]) {
      await assert.rejects(
        broadcast.sendAnnouncement({ db: ctx.db, messaging }, auth, message),
        (e) => e.code === 'permission-denied',
      );
    }
    assert.equal(messaging.topics.length, 0);
    assert.equal((await ctx.db.collection('announcements').get()).size, 0);
  });

  test('an admin sends one topic push per language and stores it', async () => {
    const messaging = fakeMessaging();
    const result = await broadcast.sendAnnouncement({ db: ctx.db, messaging }, admin, message);
    assert.equal(result.sent, 5);
    const de = messaging.topics.find((m) => m.topic === 'news_de');
    assert.equal(de.notification.title, 'Hallo');
    assert.equal(de.notification.body, 'News!', 'falls back to English');
    const doc = await ctx.db.collection('announcements').doc(result.id).get();
    assert.equal(doc.get('title').ru, 'Hello');
    assert.equal(doc.get('sentBy'), 'boss');
  });

  test('segments by language and platform', async () => {
    const messaging = fakeMessaging();
    await broadcast.sendAnnouncement({ db: ctx.db, messaging }, admin, {
      ...message,
      languages: ['ru', 'xx'],
      platform: 'ios',
    });
    assert.equal(messaging.topics.length, 1);
    assert.equal(messaging.topics[0].condition, "'news_ru' in topics && 'platform_ios' in topics");
  });

  test('invalid input is rejected', async () => {
    const messaging = fakeMessaging();
    await assert.rejects(
      broadcast.sendAnnouncement({ db: ctx.db, messaging }, admin, { title: {}, body: { en: 'x' } }),
      (e) => e.code === 'invalid-argument',
    );
    await assert.rejects(
      broadcast.sendAnnouncement({ db: ctx.db, messaging }, admin, { ...message, platform: 'web' }),
      (e) => e.code === 'invalid-argument',
    );
  });
});
