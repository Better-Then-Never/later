#!/usr/bin/env node
// One-off data migration for the refactored app (docs/refactor/MIGRATIONS_NEEDED.md).
//
//   node migrate.js                      dry run against the emulator
//   node migrate.js --apply              apply on the emulator
//   node migrate.js --project <id> --production --apply
//                                        real project (owner's decision only)
//
// Dry run is the default: it prints what would change and changes nothing.
'use strict';

const admin = require('firebase-admin');
const { FieldValue } = require('firebase-admin/firestore');

const USERNAME = /^[a-z0-9._-]{3,30}$/;
const PRIVACY = new Set(['private', 'friends', 'public']);

/** Plans and (optionally) applies the user-document migration. */
async function migrateUsers(db, { apply, log = console.log }) {
  const users = await db.collection('users').get();
  const reservations = new Map(); // username -> uid
  for (const doc of (await db.collection('usernames').get()).docs) {
    reservations.set(doc.id, doc.get('uid'));
  }
  const report = { users: users.size, lowercased: 0, reserved: 0, conflicts: [], privateFieldsRemoved: 0, tokensMoved: 0, blocksMoved: 0 };

  for (const doc of users.docs) {
    const data = doc.data();
    const uid = doc.id;
    const update = {};
    const writes = [];

    // 1. Usernames: lower-case and reserve, unless taken by someone else.
    if (typeof data.username === 'string') {
      const lower = data.username.trim().toLowerCase();
      const owner = reservations.get(lower);
      if (!USERNAME.test(lower)) {
        report.conflicts.push(`${uid}: username "${data.username}" is not valid; fix by hand`);
      } else if (owner && owner !== uid) {
        report.conflicts.push(`${uid}: username "${lower}" is reserved by ${owner}; fix by hand`);
      } else {
        if (lower !== data.username) {
          update.username = lower;
          report.lowercased++;
        }
        if (!owner) {
          reservations.set(lower, uid);
          writes.push((batch) => batch.set(db.collection('usernames').doc(lower), { uid }));
          report.reserved++;
        }
      }
    }

    // 2. Private data that every signed-in user could read (BUG-071).
    for (const field of ['email', 'fcmToken', 'fcmTokenUpdatedAt']) {
      if (field in data) update[field] = FieldValue.delete();
    }
    if ('email' in data || 'fcmToken' in data) report.privateFieldsRemoved++;

    // 3. The legacy single token becomes a per-device token document.
    if (typeof data.fcmToken === 'string' && data.fcmToken) {
      const token = data.fcmToken;
      writes.push((batch) =>
        batch.set(doc.ref.collection('fcmTokens').doc(token), {
          token,
          platform: 'other',
          updatedAt: FieldValue.serverTimestamp(),
        }),
      );
      report.tokensMoved++;
    }

    // 4. Blocks made in main's app (blockedUsers array) become
    //    users/{uid}/blocked/{other} documents, which the rules check.
    if (Array.isArray(data.blockedUsers)) {
      for (const other of data.blockedUsers) {
        if (typeof other !== 'string' || !other || other === uid || other.includes('/')) continue;
        writes.push((batch) =>
          batch.set(doc.ref.collection('blocked').doc(other), { blockedAt: FieldValue.serverTimestamp() }),
        );
        report.blocksMoved++;
      }
      update.blockedUsers = FieldValue.delete();
    }

    if (Object.keys(update).length) writes.push((batch) => batch.update(doc.ref, update));
    if (writes.length) {
      log(`users/${uid}: ${Object.keys(update).join(', ') || '-'}${writes.length > 1 ? ' (+ reservation/token/blocks)' : ''}`);
      if (apply) {
        const batch = db.batch();
        writes.forEach((w) => w(batch));
        await batch.commit();
      }
    }
  }
  return report;
}

/** Capsules the rules or the app cannot read correctly. */
async function migrateCapsules(db, { apply, log = console.log }) {
  const capsules = await db.collection('capsules').get();
  const report = { capsules: capsules.size, fixed: 0, problems: [] };
  for (const doc of capsules.docs) {
    const data = doc.data();
    const update = {};
    if (!data.ownerId && typeof data.creatorId === 'string') update.ownerId = data.creatorId;
    if (!data.ownerId && !data.creatorId) report.problems.push(`capsules/${doc.id}: no owner`);
    // The rules decide visibility from `privacy`; the app treated a missing
    // value as friends-only.
    if (!PRIVACY.has(data.privacy)) update.privacy = 'friends';
    if (!data.createdAt) update.createdAt = doc.createTime;
    if (Object.keys(update).length) {
      report.fixed++;
      log(`capsules/${doc.id}: ${Object.keys(update).join(', ')}`);
      if (apply) await doc.ref.update(update);
    }
  }
  return report;
}

async function main() {
  const args = process.argv.slice(2);
  const apply = args.includes('--apply');
  const production = args.includes('--production');
  const projectArg = args.indexOf('--project');
  const projectId = projectArg >= 0 ? args[projectArg + 1] : 'later-da778';

  if (!process.env.FIRESTORE_EMULATOR_HOST && !production) {
    console.error(
      'Refusing to run without FIRESTORE_EMULATOR_HOST. To migrate a real project ' +
        'pass --project <id> --production (owner decision; take a backup first).',
    );
    process.exit(1);
  }
  admin.initializeApp({ projectId });
  const db = admin.firestore();
  console.log(`${apply ? 'APPLYING' : 'DRY RUN'} on ${projectId}` +
    `${process.env.FIRESTORE_EMULATOR_HOST ? ' (emulator)' : ''}`);
  const users = await migrateUsers(db, { apply });
  const capsules = await migrateCapsules(db, { apply });
  console.log(JSON.stringify({ users, capsules }, null, 2));
}

if (require.main === module) {
  main().catch((e) => {
    console.error(e);
    process.exit(1);
  });
}

module.exports = { migrateUsers, migrateCapsules };
