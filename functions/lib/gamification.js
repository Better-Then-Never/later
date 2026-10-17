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
/** Bounds of the world summary (one document per user, well under 1 MB). */
const MAX_COUNTRIES = 300;
const MAX_CITIES_PER_COUNTRY = 100;

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
  { id: 'curious', metric: 'capsulesViewed', tiers: [10, 50, 250, 1000], icon: 'visibility',
    title: { en: 'Curious', ru: 'Любопытный', pl: 'Ciekawski', de: 'Neugierig', es: 'Curioso' } },
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

// ---- the world summary (B7) ----------------------------------------------------

/** The capsule's country ("PL"), as the app's geocoder gave it, or null. */
function countryOf(capsule) {
  const code = capsule && capsule.countryCode;
  return typeof code === 'string' && /^[A-Z]{2}$/.test(code) ? code : null;
}

/** The capsule's town as a map key (no dots or slashes, at most 80 characters), or null. */
function cityOf(capsule) {
  const name = capsule && capsule.placeName;
  if (typeof name !== 'string') return null;
  const clean = name.replace(/[./]/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 80);
  return clean && !/^__.*__$/.test(clean) ? clean : null;
}

/**
 * The summary after one more capsule in [country] / [city] captured at
 * [when]: per country the capsules, the towns (capsules each) and the first
 * and last visit; totals for the profile. Null when the summary is full.
 * Stamps stay when a capsule is deleted, like a passport's.
 */
function nextWorld(world, country, city, when) {
  const countries = { ...((world && world.countries) || {}) };
  const known = countries[country];
  if (!known && Object.keys(countries).length >= MAX_COUNTRIES) return null;
  const entry = known
    ? { ...known, cities: { ...(known.cities || {}) } }
    : { capsules: 0, cities: {}, first: when, last: when };
  entry.capsules = (entry.capsules || 0) + 1;
  const first = toDate(entry.first);
  const last = toDate(entry.last);
  if (!first || when < first) entry.first = when;
  if (!last || when > last) entry.last = when;
  let newCity = false;
  if (city) {
    if (typeof entry.cities[city] === 'number') entry.cities[city] += 1;
    else if (Object.keys(entry.cities).length < MAX_CITIES_PER_COUNTRY) {
      entry.cities[city] = 1;
      newCity = true;
    }
  }
  countries[country] = entry;
  const cityCount = Object.values(countries).reduce((n, c) => n + Object.keys(c.cities || {}).length, 0);
  return {
    world: { countries, countryCount: Object.keys(countries).length, cityCount, updatedAt: when },
    newCountry: !known,
    newCity,
  };
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
  const worldRef = userRef.collection('world').doc('summary');
  const country = countryOf(capsule);
  return db.runTransaction(async (tx) => {
    const [user, priv, saved] = await Promise.all([
      tx.get(userRef),
      tx.get(privateRef),
      // Read only for capsules that know their country.
      country ? tx.get(worldRef) : null,
    ]);
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
    let world = null;
    if (country && user.exists) {
      world = nextWorld(saved.exists ? saved.data() : null, country, cityOf(capsule), captured);
      if (world) {
        tx.set(worldRef, world.world);
        update['stats.countries'] = world.world.countryCount;
        update['stats.cities'] = world.world.cityCount;
      }
    }
    if (user.exists) tx.update(userRef, update);
    if (Object.keys(privUpdate).length) tx.set(privateRef, privUpdate, { merge: true });
    return {
      counted: user.exists,
      streak,
      fresh,
      world: world && { country, newCountry: world.newCountry, newCity: world.newCity },
    };
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
  const was = metricsOf(before);
  const is = metricsOf(after);
  const candidates = ACHIEVEMENTS.filter(
    (a) => tierFor(a.tiers, is[a.metric]) > tierFor(a.tiers, was[a.metric]),
  );
  if (candidates.length === 0) return null;
  return unlock(services, uid, is, candidates);
}

/**
 * After a counted stat of [uid] changed (B6): the stat writers call this
 * instead of a trigger on every users/{uid} write (profile edits, pins,
 * favourites...). Two reads: the profile and the stored achievements;
 * unlocks every tier reached and not stored yet.
 */
async function checkAchievements(services, uid) {
  const { db } = services;
  if (typeof uid !== 'string' || !uid) return null;
  const userRef = db.collection('users').doc(uid);
  const [user, stored] = await Promise.all([
    userRef.get(),
    userRef.collection('achievements').get(),
  ]);
  if (!user.exists) return null;
  const is = metricsOf(user.data());
  const storedTier = new Map(
    stored.docs.map((d) => [d.id, Number.isInteger(d.get('tier')) ? d.get('tier') : -1]),
  );
  const candidates = ACHIEVEMENTS.filter(
    (a) => tierFor(a.tiers, is[a.metric]) > (storedTier.has(a.id) ? storedTier.get(a.id) : -1),
  );
  if (candidates.length === 0) return null;
  // A catch-up (several tiers reached since the last check, or levels added
  // later) tells the user once; the rest are stored quietly and show on the
  // profile.
  return unlock(services, uid, is, candidates, { notifyAtMost: 1 });
}

async function unlock(services, uid, is, candidates, { notifyAtMost = Infinity } = {}) {
  const { db } = services;
  const unlocked = [];
  let told = 0;
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
    if (told >= notifyAtMost) continue;
    told++;
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

// ---- capsules viewed (B7) --------------------------------------------------------

/**
 * Whether [uid] may count a view of [capsule] (someone else's capsule they
 * could open, already open). The app writes the marker only for those; this
 * keeps a hand-written marker from counting.
 */
async function viewCounts(db, uid, capsule, now) {
  if (!capsule || !capsule.ownerId || capsule.ownerId === uid) return false;
  const coAuthors = Array.isArray(capsule.coAuthors) ? capsule.coAuthors : [];
  if (coAuthors.includes(uid)) return false;
  const openAt = toDate(capsule.openAt);
  if (openAt && openAt > now) return false;
  if (capsule.privacy === 'public') return true;
  const sharedWith = Array.isArray(capsule.sharedWith) ? capsule.sharedWith : [];
  if (sharedWith.includes(uid)) return true;
  if (capsule.privacy !== 'friends') return false;
  const owner = await db.collection('users').doc(capsule.ownerId).get();
  const friends = (owner.exists && owner.get('friends')) || [];
  return Array.isArray(friends) && friends.includes(uid);
}

/**
 * users/{uid}/viewed/{capsuleId} created (the app opened someone else's
 * capsule for the first time): counts it once in stats.capsulesViewed (the
 * marker records that it was counted, so a retried event does not count it
 * again), then unlocks what that reached ("Curious").
 * Cost: one capsule read (and the owner for friends-only capsules), one
 * transaction, the achievement check.
 */
async function onCapsuleViewed(services, uid, capsuleId) {
  const { db } = services;
  const capsule = await db.collection('capsules').doc(capsuleId).get();
  const counts = await viewCounts(db, uid, capsule.exists ? capsule.data() : null, notify.now(services));
  const userRef = db.collection('users').doc(uid);
  const markRef = userRef.collection('viewed').doc(capsuleId);
  const counted = await db.runTransaction(async (tx) => {
    const [mark, user] = await Promise.all([tx.get(markRef), tx.get(userRef)]);
    if (!mark.exists || mark.get('counted') !== undefined || !user.exists) return false;
    tx.update(markRef, { counted: counts });
    if (counts) tx.update(userRef, { 'stats.capsulesViewed': FieldValue.increment(1) });
    return counts;
  });
  if (counted) await checkAchievements(services, uid);
  return { counted };
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
      ...notify.delivery('activity', prefs.alertOf(settings)),
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
  countryOf,
  cityOf,
  nextWorld,
  onCapsuleCreated,
  onUserUpdated,
  checkAchievements,
  onCapsuleViewed,
  sendStreakReminders,
};
