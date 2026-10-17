#!/usr/bin/env node
// Writes users/{uid}.nameLower (the name in lower case, for the name search)
// for accounts that do not have it yet and did not switch "Find me by name"
// off. The app keeps the field in step from version B3 on; this only helps
// accounts that have not opened the new version yet. Optional.
//
//   node backfill-name-search.js [--dry-run] [--project <id> --production]
'use strict';

const { init } = require('./common');

async function backfillNameSearch(db, { dryRun = false } = {}) {
  const report = { written: 0, skippedOff: 0, upToDate: 0 };
  const users = await db.collection('users').get();
  let batch = db.batch();
  let pending = 0;
  for (const doc of users.docs) {
    const name = doc.get('name');
    if (typeof name !== 'string' || !name.trim()) continue;
    const wanted = name.toLowerCase();
    if (doc.get('nameLower') === wanted) {
      report.upToDate++;
      continue;
    }
    const settings = await doc.ref.collection('settings').doc('app').get();
    if (settings.get('privacy.findByName') === false) {
      report.skippedOff++;
      continue;
    }
    report.written++;
    if (dryRun) continue;
    batch.update(doc.ref, { nameLower: wanted });
    if (++pending === 400) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }
  if (pending) await batch.commit();
  return report;
}

if (require.main === module) {
  const { db, flags, production, projectId } = init();
  const dryRun = flags.includes('--dry-run');
  backfillNameSearch(db, { dryRun })
    .then((r) => console.log(`${production ? projectId : 'emulator'}${dryRun ? ' (dry run)' : ''}:`, r))
    .catch((e) => {
      console.error(e.message);
      process.exit(1);
    });
}

module.exports = { backfillNameSearch };
