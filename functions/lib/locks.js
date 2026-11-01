// Locked capsules (capsule v3 B3, docs/capsule-v3/PHASE3_PLAN.md): a capsule
// that does not open at once keeps its photo and words in
// capsules/{id}/sealed/content, which the rules hand out only when it may
// open. This file queues capsules for their date, releases the date ones
// when it comes ("is open", F1), tells about place ones that became ready
// ("is ready", F2), opens a place capsule for someone standing there, and
// cleans up after a deleted capsule. Written against injected admin services
// so it can be tested on the emulators.
'use strict';

const { FieldValue, Timestamp } = require('firebase-admin/firestore');
const notify = require('./notify');
const prefs = require('./prefs');
const i18n = require('./i18n');

/** How close you must be to a place capsule's spot, in metres. */
const UNLOCK_RADIUS_M = 150;

/** The most of a fix's own accuracy added to that radius. */
const MAX_ACCURACY_M = 50;

/** Capsules handled per scheduled run (the next run takes the rest). */
const RELEASE_BATCH = 200;

const SCHEDULE = 'capsule_schedule';

/** Fields that live in the sealed part of a locked capsule. */
const SEALED_FIELDS = ['imageUrl', 'thumbUrl', 'frames', 'description'];

const toDate = (v) => (v && typeof v.toDate === 'function' ? v.toDate() : v instanceof Date ? v : null);

/**
 * capsules/{id} was created: if it opens later, queue it for that moment.
 * A sealed one that opens anywhere is released then; a place one is only
 * announced ("is ready"); an unsealed one from an older app version is
 * announced too ("is open").
 */
async function onCapsuleCreated(services, capsuleId, capsule) {
  if (!capsule) return null;
  const openAt = toDate(capsule.openAt);
  const at = notify.now(services);
  if (!openAt || openAt <= at) return null;
  const here = capsule.openWhere === 'here';
  const kind = capsule.sealed === true ? (here ? 'ready' : 'release') : 'open';
  await services.db.collection(SCHEDULE).doc(capsuleId).set({
    openAt: Timestamp.fromDate(openAt),
    kind,
  });
  return { queued: kind };
}

/** Who hears that a capsule opened: its owner, co-authors and recipient. */
function peopleOf(capsule) {
  const people = [capsule.ownerId];
  if (Array.isArray(capsule.coAuthors)) people.push(...capsule.coAuthors);
  if (Array.isArray(capsule.sharedWith)) people.push(...capsule.sharedWith);
  return [...new Set(people.filter((id) => typeof id === 'string' && id))];
}

/** The push for "is open" (F1) or "is ready" (F2). */
function openMessage({ kind, capsuleId, title, placeName }, token, sound = true, lang = 'en') {
  const ready = kind === 'ready';
  const body = ready
    ? placeName
      ? i18n.t(lang, 'readyBody', { place: placeName })
      : i18n.t(lang, 'readyBodyNoPlace')
    : i18n.t(lang, 'openBody');
  return {
    token,
    notification: {
      title: i18n.t(lang, ready ? 'readyTitle' : 'openTitle', { title }),
      body,
    },
    data: {
      type: ready ? 'capsuleReady' : 'capsuleOpen',
      capsuleId,
      clickAction: 'FLUTTER_NOTIFICATION_CLICK',
    },
    ...notify.delivery('capsules', sound, { tag: `capsule_${capsuleId}` }),
  };
}

/**
 * Tells [capsule]'s people that it opened ([kind] 'open') or is waiting at
 * its spot ('ready'): an in-app notification for each, a push for those who
 * want capsule pushes now.
 */
async function announce(services, capsuleId, capsule, kind) {
  const { db } = services;
  const people = peopleOf(capsule);
  if (people.length === 0) return { sent: 0 };
  const title = String(capsule.title || '').slice(0, 100);
  const placeName = typeof capsule.placeName === 'string' ? capsule.placeName : '';
  const type = kind === 'ready' ? 'capsuleReady' : 'capsuleOpen';
  const owner = await db.collection('users').doc(capsule.ownerId).get();
  const ownerName = (owner.exists && (owner.get('username') || owner.get('name'))) || '';
  const batch = db.batch();
  for (const uid of people) {
    batch.set(db.collection('users').doc(uid).collection('notifications').doc(), {
      type,
      fromUserId: capsule.ownerId,
      fromUserName: ownerName,
      fromUserAvatar: '',
      // What older app versions show for a type they do not know.
      message: kind === 'ready' ? `${title} is ready` : `${title} is open`,
      capsuleId,
      capsuleTitle: title,
      ...(placeName ? { placeName } : {}),
      timestamp: FieldValue.serverTimestamp(),
      isRead: false,
    });
  }
  await batch.commit();
  const at = notify.now(services);
  const results = await Promise.all(
    people.map(async (uid) => {
      const settings = await prefs.loadSettings(db, uid);
      if (prefs.blockedReason(settings, 'capsules', at)) return { sent: 0, pruned: 0 };
      const sound = prefs.alertOf(settings);
      const lang = i18n.languageOf(settings);
      return notify.sendToUser(services, uid, (token) =>
        openMessage({ kind, capsuleId, title, placeName }, token, sound, lang),
      );
    }),
  );
  return { people: people.length, sent: results.reduce((n, r) => n + r.sent, 0) };
}

/**
 * Moves a sealed capsule's photo and words back into the capsule, so lists
 * and chats show it without one more read; the capsule is no longer
 * sealed. Returns the capsule as it is now, or null when it is gone.
 */
async function release(db, ref, entryRef) {
  return db.runTransaction(async (tx) => {
    const sealedRef = ref.collection('sealed').doc('content');
    const [snap, sealed] = await Promise.all([tx.get(ref), tx.get(sealedRef)]);
    tx.delete(entryRef);
    if (!snap.exists) return null;
    const capsule = snap.data();
    if (capsule.sealed !== true) return capsule;
    const content = sealed.exists ? sealed.data() : {};
    const update = { sealed: FieldValue.delete() };
    for (const field of SEALED_FIELDS) {
      if (content[field] !== undefined && content[field] !== null) update[field] = content[field];
    }
    tx.update(ref, update);
    if (sealed.exists) tx.delete(sealedRef);
    return { ...capsule, ...content };
  });
}

/**
 * Every few minutes: the capsules whose date came. Date capsules are
 * released and announced ("is open"); place capsules are announced as
 * ready, and stay sealed until each person opens them there.
 */
async function releaseOpenedCapsules(services) {
  const { db } = services;
  const at = notify.now(services);
  const due = await db
    .collection(SCHEDULE)
    .where('openAt', '<=', Timestamp.fromDate(at))
    .orderBy('openAt')
    .limit(RELEASE_BATCH)
    .get();
  const report = { released: 0, opened: 0, ready: 0, gone: 0 };
  for (const entry of due.docs) {
    const capsuleId = entry.id;
    const kind = entry.get('kind');
    const ref = db.collection('capsules').doc(capsuleId);
    let capsule;
    if (kind === 'release') {
      capsule = await release(db, ref, entry.ref);
      if (capsule) report.released++;
    } else {
      const snap = await ref.get();
      await entry.ref.delete();
      capsule = snap.exists ? snap.data() : null;
    }
    if (!capsule) {
      report.gone++;
      continue;
    }
    const announced = kind === 'ready' ? 'ready' : 'open';
    await announce(services, capsuleId, capsule, announced);
    report[announced === 'ready' ? 'ready' : 'opened']++;
  }
  return report;
}

/** Distance between two points on the Earth, in metres (haversine). */
function distanceMetres(lat1, lng1, lat2, lng2) {
  const rad = (d) => (d * Math.PI) / 180;
  const dLat = rad(lat2 - lat1);
  const dLng = rad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * 6371008.8 * Math.asin(Math.min(1, Math.sqrt(a)));
}

/** A refused unlock, with a code the callable turns into an HttpsError. */
class UnlockError extends Error {
  constructor(code, message, details) {
    super(message);
    this.code = code;
    this.details = details;
  }
}

/** Whether [uid] may see [capsule] (the rules' canSee). */
async function canSee(db, uid, capsule) {
  if (capsule.ownerId === uid) return true;
  if (capsule.privacy === 'public') return true;
  if (Array.isArray(capsule.sharedWith) && capsule.sharedWith.includes(uid)) return true;
  if (Array.isArray(capsule.coAuthors) && capsule.coAuthors.includes(uid)) return true;
  if (capsule.privacy === 'friends') {
    const owner = await db.collection('users').doc(capsule.ownerId).get();
    const friends = owner.exists ? owner.get('friends') : null;
    return Array.isArray(friends) && friends.includes(uid);
  }
  return false;
}

/**
 * Someone standing at a place capsule's spot opens it (B4): the capsule
 * must be one they may see, its date must have come, and the position the
 * phone reports must be within 150 m of the spot (plus the fix's accuracy,
 * at most 50 m). The position is trusted (no attestation exists); each
 * unlock is logged. Returns the sealed part.
 */
async function unlockCapsule(services, auth, data) {
  const { db } = services;
  const uid = auth && auth.uid;
  if (!uid) throw new UnlockError('unauthenticated', 'Sign in first.');
  const capsuleId = data && data.capsuleId;
  const lat = Number(data && data.lat);
  const lng = Number(data && data.lng);
  const accuracy = Number((data && data.accuracy) || 0);
  if (typeof capsuleId !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(capsuleId)) {
    throw new UnlockError('invalid-argument', 'No such capsule.');
  }
  if (!Number.isFinite(lat) || !Number.isFinite(lng) || Math.abs(lat) > 90 || Math.abs(lng) > 180) {
    throw new UnlockError('invalid-argument', 'No position.');
  }
  const ref = db.collection('capsules').doc(capsuleId);
  const snap = await ref.get();
  if (!snap.exists || !(await canSee(db, uid, snap.data()))) {
    throw new UnlockError('not-found', 'No such capsule.');
  }
  const capsule = snap.data();
  if (capsule.openWhere !== 'here') {
    throw new UnlockError('failed-precondition', 'This capsule opens anywhere.');
  }
  const openAt = toDate(capsule.openAt);
  if (openAt && openAt > notify.now(services)) {
    throw new UnlockError('failed-precondition', 'Not yet.', { openAt: openAt.toISOString() });
  }
  const spot = capsule.location;
  if (!spot || typeof spot.latitude !== 'number') {
    throw new UnlockError('failed-precondition', 'The capsule has no place.');
  }
  const distance = distanceMetres(lat, lng, spot.latitude, spot.longitude);
  const slack = Number.isFinite(accuracy) ? Math.min(Math.max(accuracy, 0), MAX_ACCURACY_M) : 0;
  if (distance > UNLOCK_RADIUS_M + slack) {
    throw new UnlockError('out-of-range', 'Too far.', { distance: Math.round(distance) });
  }
  const sealed = await ref.collection('sealed').doc('content').get();
  await db
    .collection('users')
    .doc(uid)
    .collection('unlocked')
    .doc(capsuleId)
    .set({ at: FieldValue.serverTimestamp(), distance: Math.round(distance) });
  return {
    distance: Math.round(distance),
    content: sealed.exists ? sealed.data() : null,
  };
}

/**
 * capsules/{id} was deleted: its sealed part, comments and reactions go
 * with it, and so does its place in the queue. (Unlocks in users/{uid}/
 * unlocked stay: they name a capsule that is gone and open nothing.)
 */
async function onCapsuleDeleted(services, capsuleId) {
  const { db } = services;
  const ref = db.collection('capsules').doc(capsuleId);
  await db.recursiveDelete(ref);
  await db.collection(SCHEDULE).doc(capsuleId).delete();
  return { cleaned: capsuleId };
}

module.exports = {
  UNLOCK_RADIUS_M,
  MAX_ACCURACY_M,
  SCHEDULE,
  UnlockError,
  onCapsuleCreated,
  releaseOpenedCapsules,
  unlockCapsule,
  onCapsuleDeleted,
  openMessage,
  distanceMetres,
  peopleOf,
};
