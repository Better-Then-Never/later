// Streaks, stats and achievements (DECISIONS.md D-15, D-16). Everything is
// computed here, on the server: clients cannot write stats or achievements.
'use strict';

const { FieldValue } = require('firebase-admin/firestore');
const prefs = require('./prefs');
const i18n = require('./i18n');
const social = require('./social');
const notify = require('./notify');

/** How old a capture may be on arrival and still count for the streak. */
const STREAK_WINDOW_MS = 48 * 60 * 60 * 1000;
/** Geohash length for "places": 5 characters ≈ 4.9 × 4.9 km. */
const PLACE_PRECISION = 5;
const MAX_PLACES = 5000;

/**
 * The achievement registry. `metric` is a field of users/{uid}.stats (or
 * `friends`, the length of the friends list). Reaching a tier value unlocks
 * that tier. `icon` is the Material placeholder the app shows until
 * assets/achievements/<id>.png exists. Titles are for pushes; the app has its
 * own localized texts (achievement<Id>Title keys).
 */
const ACHIEVEMENTS = Object.freeze([
  { id: 'first_capsule', metric: 'capsules', tiers: [1], icon: 'photo_camera',
    title: { en: 'First capsule', ru: 'Первая капсула', pl: 'Pierwsza kapsuła', de: 'Erste Kapsel', es: 'Primera cápsula' } },
  { id: 'collector', metric: 'capsules', tiers: [5, 25, 100, 500], icon: 'collections',
    title: { en: 'Collector', ru: 'Коллекционер', pl: 'Kolekcjoner', de: 'Sammler', es: 'Coleccionista' } },
  { id: 'open_book', metric: 'publicCapsules', tiers: [1, 10, 50], icon: 'public',
    title: { en: 'Open book', ru: 'Открытая книга', pl: 'Otwarta księga', de: 'Offenes Buch', es: 'Libro abierto' } },
  { id: 'animator', metric: 'loopCapsules', tiers: [1, 10], icon: 'animation',
    title: { en: 'Animator', ru: 'Аниматор', pl: 'Animator', de: 'Animator', es: 'Animador' } },
  { id: 'streak', metric: 'streakLongest', tiers: [3, 7, 14, 30, 100], icon: 'local_fire_department',
    title: { en: 'On fire', ru: 'В ударе', pl: 'W formie', de: 'Feuer und Flamme', es: 'En racha' } },
  { id: 'explorer', metric: 'places', tiers: [3, 10, 25, 100], icon: 'explore',
    title: { en: 'Explorer', ru: 'Исследователь', pl: 'Odkrywca', de: 'Entdecker', es: 'Explorador' } },
  { id: 'traveler', metric: 'distanceKm', tiers: [100, 1000, 10000], icon: 'flight_takeoff',
    title: { en: 'Traveler', ru: 'Путешественник', pl: 'Podróżnik', de: 'Weltenbummler', es: 'Viajero' } },
  { id: 'crowd_pleaser', metric: 'reactionsReceived', tiers: [10, 100, 1000], icon: 'favorite',
    title: { en: 'Crowd pleaser', ru: 'Любимец публики', pl: 'Ulubieniec publiczności', de: 'Publikumsliebling', es: 'Favorito del público' } },
  { id: 'chatterbox', metric: 'commentsWritten', tiers: [1, 25, 100], icon: 'chat_bubble',
    title: { en: 'Chatterbox', ru: 'Душа компании', pl: 'Gaduła', de: 'Plaudertasche', es: 'Charlatán' } },
  { id: 'friendly', metric: 'friends', tiers: [1, 10, 50], icon: 'group',
    title: { en: 'Friendly', ru: 'Дружелюбный', pl: 'Towarzyski', de: 'Gesellig', es: 'Sociable' } },
  { id: 'night_owl', metric: 'nightCapsules', tiers: [1, 10], icon: 'nightlight',
    title: { en: 'Night owl', ru: 'Сова', pl: 'Nocny marek', de: 'Nachteule', es: 'Ave nocturna' } },
  { id: 'early_bird', metric: 'morningCapsules', tiers: [1, 10], icon: 'wb_twilight',
    title: { en: 'Early bird', ru: 'Жаворонок', pl: 'Ranny ptaszek', de: 'Frühaufsteher', es: 'Madrugador' } },
]);

// ---- helpers ------------------------------------------------------------------

const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';

function geohash(lat, lng, precision = PLACE_PRECISION) {
  let latMin = -90, latMax = 90, lngMin = -180, lngMax = 180;
  let hash = '', bit = 0, ch = 0, even = true;
  while (hash.length < precision) {
    if (even) {
      const mid = (lngMin + lngMax) / 2;
      if (lng >= mid) { ch |= 1 << (4 - bit); lngMin = mid; } else { lngMax = mid; }
    } else {
      const mid = (latMin + latMax) / 2;
      if (lat >= mid) { ch |= 1 << (4 - bit); latMin = mid; } else { latMax = mid; }
    }
    even = !even;
    if (bit < 4) bit++;
    else { hash += BASE32[ch]; bit = 0; ch = 0; }
  }
  return hash;
}

function distanceKm(a, b) {
  const rad = (d) => (d * Math.PI) / 180;
  const dLat = rad(b.lat - a.lat);
  const dLng = rad(b.lng - a.lng);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 6371 * 2 * Math.asin(Math.sqrt(h));
}

/** YYYY-MM-DD of [date] shifted by [offsetMinutes] (the user's local day). */
function localDay(date, offsetMinutes) {
  return new Date(date.getTime() + offsetMinutes * 60000).toISOString().slice(0, 10);
}

function previousDay(day) {
  const d = new Date(`${day}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() - 1);
  return d.toISOString().slice(0, 10);
}

const toDate = (v) => (v && typeof v.toDate === 'function' ? v.toDate() : v instanceof Date ? v : null);

/** A valid capsule position (not missing, not 0,0, in range). */
function validLocation(loc) {
  if (!loc) return null;
  const lat = typeof loc.latitude === 'number' ? loc.latitude : loc._latitude;
  const lng = typeof loc.longitude === 'number' ? loc.longitude : loc._longitude;
  if (typeof lat !== 'number' || typeof lng !== 'number') return null;
  if (Math.abs(lat) > 90 || Math.abs(lng) > 180) return null;
  if (Math.abs(lat) < 1e-4 && Math.abs(lng) < 1e-4) return null;
  return { lat, lng };
}

/** The next streak after a capture on [day]. */
function nextStreak(stats, day) {
  const current = stats.streakCurrent || 0;
  const longest = stats.streakLongest || 0;
  const last = stats.streakLastDay || null;
  if (last === day) return null; // already counted today
  if (last && day < last) return null; // an older day arriving late
  const next = last && previousDay(day) === last ? current + 1 : 1;
  return { streakCurrent: next, streakLongest: Math.max(longest, next), streakLastDay: day };
}

// ---- capsule created: stats and streak ----------------------------------------

/**
 * capsules/{id} created: update the owner's stats (totals, streak, places,
 * distance, night/morning) in one transaction. The capture time and the
 * device offset come from the capsule (offline capsules keep both).
 */
async function onCapsuleCreated(services, capsuleId, capsule) {
  const { db } = services;
  const ownerId = capsule && capsule.ownerId;
  if (!ownerId) return null;
  const now = notify.now(services);
  const captured = toDate(capsule.capturedAt) || toDate(capsule.createdAt) || now;
  const offset = Number.isInteger(capsule.utcOffsetMinutes)
    ? Math.max(-14 * 60, Math.min(14 * 60, capsule.utcOffsetMinutes))
    : 0;
  const fresh = now.getTime() - captured.getTime() <= STREAK_WINDOW_MS && captured <= now;
  const day = localDay(captured, offset);
  const hour = new Date(captured.getTime() + offset * 60000).getUTCHours();
  const location = validLocation(capsule.location);

  const userRef = db.collection('users').doc(ownerId);
  const privateRef = userRef.collection('private').doc('gamification');
  return db.runTransaction(async (tx) => {
    const [user, priv] = await Promise.all([tx.get(userRef), tx.get(privateRef)]);
    const stats = (user.exists && user.get('stats')) || {};
    const p = priv.exists ? priv.data() : {};
    const update = {
      'stats.capsules': FieldValue.increment(1),
    };
    if (capsule.privacy === 'public') update['stats.publicCapsules'] = FieldValue.increment(1);
    if (Array.isArray(capsule.frames) && capsule.frames.length > 1) {
      update['stats.loopCapsules'] = FieldValue.increment(1);
    }
    if (hour < 5) update['stats.nightCapsules'] = FieldValue.increment(1);
    else if (hour < 8) update['stats.morningCapsules'] = FieldValue.increment(1);

    let streak = null;
    if (fresh) {
      streak = nextStreak(stats, day);
      if (streak) {
        update['stats.streakCurrent'] = streak.streakCurrent;
        update['stats.streakLongest'] = streak.streakLongest;
        update['stats.streakLastDay'] = streak.streakLastDay;
      }
    }

    const privUpdate = {};
    if (location) {
      const cell = geohash(location.lat, location.lng);
      const cells = Array.isArray(p.cells) ? p.cells : [];
      if (!cells.includes(cell) && cells.length < MAX_PLACES) {
        privUpdate.cells = FieldValue.arrayUnion(cell);
        update['stats.places'] = FieldValue.increment(1);
      }
      if (p.last && typeof p.last.lat === 'number') {
        const km = Math.round(distanceKm(p.last, location) * 10) / 10;
        if (km > 0) update['stats.distanceKm'] = FieldValue.increment(km);
      }
      privUpdate.last = location;
    }
    if (user.exists) tx.update(userRef, update);
    if (Object.keys(privUpdate).length) tx.set(privateRef, privUpdate, { merge: true });
    return { counted: user.exists, streak, fresh };
  });
}

// ---- users/{uid} updated: unlock achievements ------------------------------------

function metricsOf(user) {
  const stats = (user && user.stats) || {};
  return {
    ...stats,
    friends: Array.isArray(user && user.friends) ? user.friends.length : 0,
  };
}

/** The highest tier index reached for [value] (-1 = none). */
function tierFor(tiers, value) {
  let reached = -1;
  tiers.forEach((t, i) => { if (typeof value === 'number' && value >= t) reached = i; });
  return reached;
}

/**
 * users/{uid} changed: unlock every achievement tier whose metric crossed a
 * threshold, once (the achievement document keeps the highest tier).
 */
async function onUserUpdated(services, uid, before, after) {
  const { db } = services;
  const was = metricsOf(before);
  const is = metricsOf(after);
  const candidates = ACHIEVEMENTS.filter(
    (a) => tierFor(a.tiers, is[a.metric]) > tierFor(a.tiers, was[a.metric]),
  );
  if (candidates.length === 0) return null;
  const unlocked = [];
  for (const a of candidates) {
    const tier = tierFor(a.tiers, is[a.metric]);
    const ref = db.collection('users').doc(uid).collection('achievements').doc(a.id);
    const isNew = await db.runTransaction(async (tx) => {
      const doc = await tx.get(ref);
      const stored = doc.exists && Number.isInteger(doc.get('tier')) ? doc.get('tier') : -1;
      if (tier <= stored) return false;
      tx.set(ref, {
        id: a.id,
        tier,
        tiers: a.tiers.length,
        value: is[a.metric],
        unlockedAt: FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (!isNew) continue;
    unlocked.push(`${a.id}:${tier}`);
    await social.deliver(
      services,
      uid,
      `achievement_${a.id}_${tier}`,
      'achievements',
      { type: 'achievement', achievementId: a.id, tier },
      async (lang) => ({
        title: i18n.t(lang, 'achievementTitle'),
        body: i18n.t(lang, 'achievementBody', { title: a.title[lang] || a.title.en }),
        data: { type: 'achievement', achievementId: a.id },
      }),
    );
  }
  return { unlocked };
}

// ---- streak reminder ------------------------------------------------------------

/**
 * Hourly: users who opted in and whose local time is [reminderHour] get a
 * reminder when their streak was last extended yesterday (it ends tonight).
 * Cost: one query bounded by the opted-in users, one read each.
 */
async function sendStreakReminders(services, reminderHour = 19) {
  const { db } = services;
  const now = notify.now(services);
  const settingsDocs = await db
    .collectionGroup('settings')
    .where('notifications.streakReminder', '==', true)
    .get();
  let sent = 0;
  for (const doc of settingsDocs.docs) {
    const userRef = doc.ref.parent.parent;
    if (!userRef) continue;
    const settings = prefs.normalize(doc.data());
    const offset = settings.notifications.utcOffsetMinutes;
    const local = new Date(now.getTime() + offset * 60000);
    if (local.getUTCHours() !== reminderHour) continue;
    const today = local.toISOString().slice(0, 10);
    const user = await userRef.get();
    const stats = (user.exists && user.get('stats')) || {};
    if (!stats.streakCurrent || stats.streakLastDay !== previousDay(today)) continue;
    const privateRef = userRef.collection('private').doc('gamification');
    const priv = await privateRef.get();
    if (priv.exists && priv.get('lastReminderDay') === today) continue;
    await privateRef.set({ lastReminderDay: today }, { merge: true });
    if (prefs.blockedReason(settings, 'streakReminder', now)) continue;
    const lang = i18n.languageOf(settings);
    const result = await notify.sendToUser(services, userRef.id, (token) => ({
      token,
      notification: {
        title: i18n.t(lang, 'streakTitle'),
        body: i18n.t(lang, 'streakBody', { days: stats.streakCurrent }),
      },
      data: { type: 'streak', clickAction: 'FLUTTER_NOTIFICATION_CLICK' },
      ...notify.delivery('activity', settings.notifications.sound),
    }));
    sent += result.sent;
  }
  return { checked: settingsDocs.size, sent };
}

module.exports = {
  ACHIEVEMENTS,
  STREAK_WINDOW_MS,
  geohash,
  distanceKm,
  localDay,
  previousDay,
  nextStreak,
  validLocation,
  tierFor,
  onCapsuleCreated,
  onUserUpdated,
  sendStreakReminders,
};
