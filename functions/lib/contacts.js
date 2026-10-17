// Friend suggestions from the phone's contacts, opt-in on both sides (B3,
// behind a flag in the app). Only hashes of email addresses travel: the app
// hashes its contacts' addresses on the phone (ContactsChannel.kt), and the
// index holds the hash of the verified email of each user who chose to be
// found. Requests are answered and their hashes dropped at once.
'use strict';

const crypto = require('crypto');
const { FieldValue } = require('firebase-admin/firestore');

/** Same as ContactsChannel.kt: versioned, so the scheme can change. */
const SALT = 'later-contacts-v1:';

/** Hashes looked up per request (the app sends at most this many). */
const MAX_HASHES = 1000;

const HEX64 = /^[0-9a-f]{64}$/;

function hashEmail(email) {
  return crypto.createHash('sha256').update(SALT + email.trim().toLowerCase()).digest('hex');
}

const wantsToBeFound = (settings) =>
  Boolean(settings && settings.privacy && settings.privacy.findByContacts === true);

/**
 * users/{uid}/settings/app was written: when "people with my email in
 * their contacts find me" changed, add or remove the user's entry. Only a
 * verified email is indexed (anyone could type someone else's address).
 */
async function syncContactIndex({ db, auth }, uid, before, after) {
  const was = wantsToBeFound(before);
  const wants = wantsToBeFound(after);
  if (was === wants) return { changed: false };
  let user;
  try {
    user = await auth.getUser(uid);
  } catch (_) {
    return { changed: false, reason: 'no-account' };
  }
  if (!user.email) return { changed: false, reason: 'no-email' };
  const ref = db.collection('contactIndex').doc(hashEmail(user.email));
  if (wants) {
    if (!user.emailVerified) return { changed: false, reason: 'unverified' };
    await ref.set({ uid, at: FieldValue.serverTimestamp() });
    return { changed: true, indexed: true };
  }
  const doc = await ref.get();
  if (doc.exists && doc.get('uid') === uid) await ref.delete();
  return { changed: true, indexed: false };
}

/**
 * contactMatches/{uid} asks (status "pending") with the hashes of the
 * user's contacts: answers with the people found who still allow it, who
 * are not the user and not blocked either way; the hashes are not kept.
 */
async function matchContacts({ db }, uid, request) {
  if (!request || request.status !== 'pending') return { matched: 0 };
  const hashes = [
    ...new Set(
      (Array.isArray(request.hashes) ? request.hashes : []).filter(
        (h) => typeof h === 'string' && HEX64.test(h),
      ),
    ),
  ].slice(0, MAX_HASHES);
  const found = new Set();
  for (let i = 0; i < hashes.length; i += 100) {
    const refs = hashes.slice(i, i + 100).map((h) => db.collection('contactIndex').doc(h));
    if (refs.length === 0) continue;
    for (const doc of await db.getAll(...refs)) {
      const other = doc.exists ? doc.get('uid') : null;
      if (typeof other === 'string' && other !== uid) found.add(other);
    }
  }
  const matches = [];
  for (const other of found) {
    const [settings, blockedByMe, blockedMe] = await Promise.all([
      db.doc(`users/${other}/settings/app`).get(),
      db.doc(`users/${uid}/blocked/${other}`).get(),
      db.doc(`users/${other}/blocked/${uid}`).get(),
    ]);
    if (!wantsToBeFound(settings.data())) continue;
    if (blockedByMe.exists || blockedMe.exists) continue;
    matches.push(other);
  }
  await db.doc(`contactMatches/${uid}`).set({
    status: 'done',
    matches,
    at: request.at || FieldValue.serverTimestamp(),
    doneAt: FieldValue.serverTimestamp(),
  });
  return { matched: matches.length, checked: hashes.length };
}

module.exports = { SALT, MAX_HASHES, hashEmail, syncContactIndex, matchContacts };
