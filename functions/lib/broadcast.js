// Announcements from the Later team (DECISIONS.md D-17): admin only, one
// topic push per language, no per-user fan-out. See docs/ux/ADMIN.md.
'use strict';

const { FieldValue } = require('firebase-admin/firestore');
const i18n = require('./i18n');

class AnnouncementError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code; // 'permission-denied' | 'invalid-argument'
  }
}

const PLATFORMS = ['android', 'ios'];

/** Topic of the announcements in [lang] (the app subscribes when "News" is on). */
const newsTopic = (lang) => `news_${lang}`;
const platformTopic = (platform) => `platform_${platform}`;

function texts(map, field) {
  if (!map || typeof map !== 'object' || typeof map.en !== 'string' || !map.en.trim()) {
    throw new AnnouncementError('invalid-argument', `${field}.en is required`);
  }
  const out = {};
  for (const lang of i18n.LANGUAGES) {
    const v = map[lang];
    if (v !== undefined && (typeof v !== 'string' || v.length > 500)) {
      throw new AnnouncementError('invalid-argument', `${field}.${lang} must be a string up to 500 characters`);
    }
    out[lang] = (v || map.en).trim();
  }
  return out;
}

/**
 * Sends an announcement. [auth] is the caller's auth context: only a user
 * with the custom claim `admin: true` may call it. [data]:
 * `{ title: {en, ru?, ...}, body: {en, ...}, languages?: [...], platform?: 'android'|'ios' }`.
 */
async function sendAnnouncement({ db, messaging }, auth, data) {
  if (!auth || !auth.token || auth.token.admin !== true) {
    throw new AnnouncementError('permission-denied', 'Only admins can send announcements.');
  }
  const title = texts(data && data.title, 'title');
  const body = texts(data && data.body, 'body');
  const languages = Array.isArray(data.languages) && data.languages.length
    ? data.languages.filter((l) => i18n.LANGUAGES.includes(l))
    : i18n.LANGUAGES;
  if (languages.length === 0) throw new AnnouncementError('invalid-argument', 'no valid languages');
  const platform = data.platform == null ? null : data.platform;
  if (platform !== null && !PLATFORMS.includes(platform)) {
    throw new AnnouncementError('invalid-argument', 'platform must be android or ios');
  }

  const ref = db.collection('announcements').doc();
  await ref.set({
    title,
    body,
    languages,
    platform,
    sentBy: auth.uid,
    createdAt: FieldValue.serverTimestamp(),
  });
  let sent = 0;
  for (const lang of languages) {
    const target = platform
      ? { condition: `'${newsTopic(lang)}' in topics && '${platformTopic(platform)}' in topics` }
      : { topic: newsTopic(lang) };
    await messaging.send({
      ...target,
      notification: { title: title[lang], body: body[lang] },
      data: { type: 'announcement', announcementId: ref.id },
      android: { priority: 'normal', notification: { channelId: 'activity' } },
    });
    sent++;
  }
  return { id: ref.id, sent };
}

module.exports = { AnnouncementError, sendAnnouncement, newsTopic, platformTopic };
