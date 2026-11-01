#!/usr/bin/env node
// One-off after deploying the capsule locks (capsule v3 B3,
// docs/capsule-v3/PHASE3_PLAN.md): capsules written before them that are
// still waiting for their date carry their photo and words in the capsule
// itself. This seals them as the app now does: the photo, thumbnail, loop
// frames and words move to capsules/{id}/sealed/content, the capsule is
// marked sealed and queued for release on its date. Safe to run again (a
// sealed capsule is skipped). A picture already sent in a chat stays there.
//
//   node seal-waiting-capsules.js [--dry-run] [--project <id> --production]
'use strict';

const { init } = require('./common');

const SEALED_FIELDS = ['imageUrl', 'thumbUrl', 'frames', 'description'];

async function sealWaitingCapsules(db, { dryRun = false, now = new Date() } = {}) {
  const { FieldValue, Timestamp } = require('firebase-admin/firestore');
  const report = { waiting: 0, sealed: 0, skipped: 0 };
  const waiting = await db
    .collection('capsules')
    .where('openAt', '>', Timestamp.fromDate(now))
    .get();
  for (const doc of waiting.docs) {
    report.waiting++;
    const capsule = doc.data();
    if (capsule.sealed === true || typeof capsule.imageUrl !== 'string') {
      report.skipped++;
      continue;
    }
    const content = {};
    const update = { sealed: true };
    for (const field of SEALED_FIELDS) {
      if (capsule[field] === undefined) continue;
      if (capsule[field] !== null) content[field] = capsule[field];
      update[field] = FieldValue.delete();
    }
    report.sealed++;
    if (dryRun) continue;
    const batch = db.batch();
    batch.set(doc.ref.collection('sealed').doc('content'), content);
    batch.update(doc.ref, update);
    batch.set(db.collection('capsule_schedule').doc(doc.id), {
      openAt: capsule.openAt,
      kind: 'release',
    });
    await batch.commit();
  }
  return report;
}

if (require.main === module) {
  const { db, flags, production, projectId } = init();
  const dryRun = flags.includes('--dry-run');
  sealWaitingCapsules(db, { dryRun })
    .then((r) => console.log(`${production ? projectId : 'emulator'}${dryRun ? ' (dry run)' : ''}:`, JSON.stringify(r)))
    .catch((e) => {
      console.error(e.message);
      process.exit(1);
    });
}

module.exports = { sealWaitingCapsules };
