// lib/gamification.js: stats, streaks (capture day), places, achievements,
// streak reminders.
'use strict';

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const { GeoPoint, Timestamp } = require('firebase-admin/firestore');
const { ctx, fakeMessaging, users, addUser, setSettings } = require('./helpers');
const g = require('../lib/gamification');

const at = (iso) => new Date(iso);
const services = (now, messaging = fakeMessaging()) => ({ db: ctx.db, messaging, now: () => now });
const stats = async (uid) => (await users().doc(uid).get()).get('stats') || {};

function capsule(capturedIso, extra = {}) {
  return {
    ownerId: 'ana',
    privacy: 'friends',
    location: new GeoPoint(52.52, 13.405), // Berlin
    capturedAt: Timestamp.fromDate(at(capturedIso)),
    utcOffsetMinutes: 120,
    ...extra,
  };
}

describe('helpers', () => {
  test('local day, previous day, geohash, distance, location guard', () => {
    // 23:30 UTC is already the next day at UTC+2.
    assert.equal(g.localDay(at('2026-10-16T23:30:00Z'), 120), '2026-10-17');
    assert.equal(g.previousDay('2026-03-01'), '2026-02-28');
    // Reference value from the geohash article (Jutland, Denmark).
    assert.equal(g.geohash(57.64911, 10.40744, 11), 'u4pruydqqvj');
    assert.ok(Math.abs(g.distanceKm({ lat: 52.52, lng: 13.405 }, { lat: 48.137, lng: 11.575 }) - 504) < 5);
    assert.equal(g.validLocation(new GeoPoint(0, 0)), null);
    assert.deepEqual(g.validLocation(new GeoPoint(1, 2)), { lat: 1, lng: 2 });
  });

  test('streak rules', () => {
    assert.deepEqual(g.nextStreak({}, '2026-10-16'), {
      streakCurrent: 1, streakLongest: 1, streakLastDay: '2026-10-16',
    });
    const s = { streakCurrent: 4, streakLongest: 9, streakLastDay: '2026-10-16' };
    assert.equal(g.nextStreak(s, '2026-10-16'), null); // same day
    assert.equal(g.nextStreak(s, '2026-10-12'), null); // older day arrives late
    assert.deepEqual(g.nextStreak(s, '2026-10-17'), {
      streakCurrent: 5, streakLongest: 9, streakLastDay: '2026-10-17',
    });
    assert.equal(g.nextStreak(s, '2026-10-19').streakCurrent, 1); // gap
  });
});

describe('capsule stats', () => {
  test('counts, streak by capture day, places and distance', async () => {
    await addUser('ana');
    await g.onCapsuleCreated(services(at('2026-10-15T10:00:00Z')), 'c1', capsule('2026-10-15T09:00:00Z', { privacy: 'public' }));
    await g.onCapsuleCreated(
      services(at('2026-10-16T08:00:00Z')),
      'c2',
      // Munich, captured the next local day.
      capsule('2026-10-16T07:00:00Z', { location: new GeoPoint(48.137, 11.575), frames: ['a', 'b', 'c'] }),
    );
    // Back in Berlin, same local day: no new streak day, same place cell as c1.
    await g.onCapsuleCreated(services(at('2026-10-16T09:00:00Z')), 'c3', capsule('2026-10-16T08:30:00Z'));
    const s = await stats('ana');
    assert.equal(s.capsules, 3);
    assert.equal(s.publicCapsules, 1);
    assert.equal(s.loopCapsules, 1);
    assert.equal(s.streakCurrent, 2);
    assert.equal(s.streakLongest, 2);
    assert.equal(s.streakLastDay, '2026-10-16');
    assert.equal(s.places, 2);
    assert.ok(s.distanceKm > 1000 && s.distanceKm < 1020, `distance ${s.distanceKm}`);
    // The place cells stay private (not on the public profile document).
    const priv = await users().doc('ana').collection('private').doc('gamification').get();
    assert.equal(priv.get('cells').length, 2);
    assert.equal((await users().doc('ana').get()).get('cells'), undefined);
  });

  test('offline capsules count for their capture day within 48 hours', async () => {
    await addUser('ana');
    // Captured in the mountains on the 14th, uploaded on the 15th: counts.
    await g.onCapsuleCreated(services(at('2026-10-15T18:00:00Z')), 'c1', capsule('2026-10-14T10:00:00Z'));
    assert.equal((await stats('ana')).streakLastDay, '2026-10-14');
    // Captured four days ago: counted as a capsule, not for the streak.
    await g.onCapsuleCreated(services(at('2026-10-19T18:00:00Z')), 'c2', capsule('2026-10-15T10:00:00Z'));
    const s = await stats('ana');
    assert.equal(s.capsules, 2);
    assert.equal(s.streakLastDay, '2026-10-14');
  });

  test('night owls and invalid locations', async () => {
    await addUser('ana');
    // 01:00 local (23:00 UTC at +2), at 0,0: night capsule, no place.
    await g.onCapsuleCreated(
      services(at('2026-10-16T23:10:00Z')),
      'c1',
      capsule('2026-10-16T23:00:00Z', { location: new GeoPoint(0, 0) }),
    );
    const s = await stats('ana');
    assert.equal(s.nightCapsules, 1);
    assert.equal(s.places, undefined);
  });
});

describe('achievements', () => {
  test('unlock once per tier, with an in-app notification and a push', async () => {
    await addUser('ana', {}, ['a1']);
    const messaging = fakeMessaging();
    const s = services(at('2026-10-16T12:00:00Z'), messaging);
    const before = { stats: {}, friends: [] };
    const after = { stats: { capsules: 5 }, friends: ['b'] };
    const result = await g.onUserUpdated(s, 'ana', before, after);
    assert.deepEqual(result.unlocked.sort(), ['collector:0', 'first_capsule:0', 'friendly:0']);
    const docs = await users().doc('ana').collection('achievements').get();
    assert.deepEqual(docs.docs.map((d) => d.id).sort(), ['collector', 'first_capsule', 'friendly']);
    assert.equal(messaging.sent.length, 3);
    assert.ok(messaging.sent.some((m) => m.notification.body === 'Collector'));

    // The same change again (a retried trigger) unlocks nothing new.
    assert.deepEqual((await g.onUserUpdated(s, 'ana', before, after)).unlocked, []);
    // Unrelated profile edits do not even look.
    assert.equal(await g.onUserUpdated(s, 'ana', after, { ...after, name: 'Ana' }), null);
    // The next tier.
    const next = await g.onUserUpdated(s, 'ana', after, { ...after, stats: { capsules: 25 } });
    assert.deepEqual(next.unlocked, ['collector:1']);
    assert.equal((await users().doc('ana').collection('achievements').doc('collector').get()).get('tier'), 1);
  });

  test('checked where a stat changes: from the profile and what is stored', async () => {
    const messaging = fakeMessaging();
    const s = services(at('2026-10-16T12:00:00Z'), messaging);
    await addUser('ben', { stats: { capsules: 6, reactionsReceived: 10 }, friends: ['a'] });
    // First capsule was unlocked before; Collector and Crowd pleaser are new.
    await users().doc('ben').collection('achievements').doc('first_capsule').set({ id: 'first_capsule', tier: 0 });
    const result = await g.checkAchievements(s, 'ben');
    assert.deepEqual(result.unlocked.sort(), ['collector:0', 'crowd_pleaser:0', 'friendly:0']);
    // Nothing new: no writes, no pushes.
    assert.equal(await g.checkAchievements(s, 'ben'), null);
    // Three reached at once: stored, but told once (no burst of pushes).
    const stored = await users().doc('ben').collection('achievements').get();
    assert.equal(stored.size, 4);
    const notes = await users().doc('ben').collection('notifications').get();
    assert.equal(notes.size, 1, 'a catch-up tells once');
    assert.equal(await g.checkAchievements(s, 'nobody'), null);
  });

  test('every achievement has a title in all five languages and ascending tiers', () => {
    for (const a of g.ACHIEVEMENTS) {
      for (const lang of ['en', 'ru', 'pl', 'de', 'es']) assert.ok(a.title[lang], `${a.id} ${lang}`);
      assert.deepEqual([...a.tiers].sort((x, y) => x - y), a.tiers, a.id);
    }
  });
});

describe('streak reminders', () => {
  test('only opted-in users whose streak ends tonight, once a day, at 19:00 local', async () => {
    // 17:00 UTC = 19:00 at UTC+2.
    const now = at('2026-10-16T17:00:00Z');
    await addUser('ana', { stats: { streakCurrent: 6, streakLastDay: '2026-10-15' } }, ['a1']);
    await setSettings('ana', { language: 'pl', notifications: { streakReminder: true, utcOffsetMinutes: 120 } });
    await addUser('ben', { stats: { streakCurrent: 6, streakLastDay: '2026-10-16' } }, ['b1']); // already today
    await setSettings('ben', { notifications: { streakReminder: true, utcOffsetMinutes: 120 } });
    await addUser('cid', { stats: { streakCurrent: 6, streakLastDay: '2026-10-15' } }, ['c1']); // not opted in
    await setSettings('cid', { notifications: { utcOffsetMinutes: 120 } });
    const messaging = fakeMessaging();
    const result = await g.sendStreakReminders(services(now, messaging));
    assert.equal(result.checked, 2);
    assert.equal(messaging.sent.length, 1);
    assert.equal(messaging.sent[0].token, 'a1');
    assert.equal(messaging.sent[0].notification.body, 'Twoja seria (6 dni) skończy się dziś w nocy. Stwórz kapsułę!');
    // Running again within the same day does not repeat it.
    await g.sendStreakReminders(services(now, messaging));
    assert.equal(messaging.sent.length, 1);
  });
});
