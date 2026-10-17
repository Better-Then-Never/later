// A user's notification preferences (users/{uid}/settings/app), as the app
// writes them, with safe defaults for missing fields and documents: every
// account that never opened the new settings keeps getting everything.
'use strict';

const DEFAULT_NOTIFICATIONS = Object.freeze({
  enabled: true,
  messages: true,
  follows: true,
  capsules: true,
  friendRequests: true,
  reactions: true,
  comments: true,
  achievements: true,
  // Announcements from the Later team (topic pushes, see broadcast.js).
  news: true,
  // Evening reminder when the streak is at risk: opt-in.
  streakReminder: false,
  preview: true,
  sound: true,
  // Vibration with the sound (B6); a silent push never vibrates.
  vibrate: true,
  quietHours: Object.freeze({ enabled: false, start: 22 * 60, end: 7 * 60 }),
  // Device offset from UTC when the settings were saved (quiet hours are in
  // the user's local time).
  utcOffsetMinutes: 0,
});

const bool = (v, fallback) => (typeof v === 'boolean' ? v : fallback);
const minutes = (v, fallback) =>
  Number.isInteger(v) && v >= 0 && v < 24 * 60 ? v : fallback;

/** Normalises a stored settings document (or undefined) to full settings. */
function normalize(data) {
  const n = (data && data.notifications) || {};
  const q = n.quietHours || {};
  const d = DEFAULT_NOTIFICATIONS;
  return {
    notifications: {
      enabled: bool(n.enabled, d.enabled),
      messages: bool(n.messages, d.messages),
      follows: bool(n.follows, d.follows),
      capsules: bool(n.capsules, d.capsules),
      friendRequests: bool(n.friendRequests, d.friendRequests),
      reactions: bool(n.reactions, d.reactions),
      comments: bool(n.comments, d.comments),
      achievements: bool(n.achievements, d.achievements),
      news: bool(n.news, d.news),
      streakReminder: bool(n.streakReminder, d.streakReminder),
      preview: bool(n.preview, d.preview),
      sound: bool(n.sound, d.sound),
      vibrate: bool(n.vibrate, d.vibrate),
      quietHours: {
        enabled: bool(q.enabled, d.quietHours.enabled),
        start: minutes(q.start, d.quietHours.start),
        end: minutes(q.end, d.quietHours.end),
      },
      utcOffsetMinutes: Number.isInteger(n.utcOffsetMinutes)
        ? Math.max(-14 * 60, Math.min(14 * 60, n.utcOffsetMinutes))
        : d.utcOffsetMinutes,
    },
    // The app's language, for localized pushes (i18n.js); null = English.
    language: typeof (data && data.language) === 'string' ? data.language : null,
    mutedChats: Array.isArray(data && data.mutedChats)
      ? data.mutedChats.filter((c) => typeof c === 'string')
      : [],
  };
}

async function loadSettings(db, uid) {
  const doc = await db.collection('users').doc(uid).collection('settings').doc('app').get();
  return normalize(doc.exists ? doc.data() : undefined);
}

/** Whether [now] falls in the quiet hours, in the user's local time. */
function inQuietHours(notifications, now) {
  const q = notifications.quietHours;
  if (!q.enabled || q.start === q.end) return false;
  const day = 24 * 60;
  const utc = now.getUTCHours() * 60 + now.getUTCMinutes();
  const local = (((utc + notifications.utcOffsetMinutes) % day) + day) % day;
  return q.start < q.end
    ? local >= q.start && local < q.end
    : local >= q.start || local < q.end; // over midnight, e.g. 22:00-07:00
}

/**
 * Whether a push of [category] (a notification setting: 'messages',
 * 'follows', 'capsules', 'friendRequests', 'reactions', 'comments',
 * 'achievements', 'streakReminder') may be
 * sent now. Returns null when it may, otherwise the reason (for logs/tests).
 */
function blockedReason(settings, category, now = new Date()) {
  const n = settings.notifications;
  if (!n.enabled) return 'disabled';
  if (!n[category]) return `${category} off`;
  if (inQuietHours(n, now)) return 'quiet hours';
  return null;
}

/**
 * How a push alerts: true (sound and vibration), 'novibrate' (sound only)
 * or false (neither).
 */
function alertOf(settings) {
  const n = settings.notifications;
  if (!n.sound) return false;
  return n.vibrate === false ? 'novibrate' : true;
}

/**
 * Android channel: one per kind, with a silent variant when sound is off
 * and one without vibration ([sound] is what [alertOf] returns).
 */
function channelFor(category, sound) {
  const base = category === 'messages' ? 'messages' : 'activity';
  if (!sound) return `${base}_silent`;
  return sound === 'novibrate' ? `${base}_novibrate` : base;
}

module.exports = {
  DEFAULT_NOTIFICATIONS,
  normalize,
  loadSettings,
  inQuietHours,
  blockedReason,
  channelFor,
  alertOf,
};
