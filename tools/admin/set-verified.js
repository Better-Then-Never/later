#!/usr/bin/env node
// Sets the verified badge (users/{uid}.verified = true) for the usernames in
// verified_users.json, or for the usernames given on the command line.
// Clients cannot write this field (firestore.rules); only this script can.
//
//   node set-verified.js [username ...] [--revoke] [--dry-run] [--project <id> --production]
'use strict';

const { init, uidOfUsername } = require('./common');

async function setVerified(db, usernames, { revoke = false, dryRun = false } = {}) {
  const report = { changed: [], missing: [] };
  for (const name of usernames) {
    const uid = await uidOfUsername(db, name);
    if (!uid) {
      report.missing.push(name);
      continue;
    }
    if (!dryRun) await db.collection('users').doc(uid).set({ verified: !revoke }, { merge: true });
    report.changed.push({ username: name, uid, verified: !revoke });
  }
  return report;
}

if (require.main === module) {
  const { db, args, flags, production, projectId } = init();
  const usernames = args.length ? args : require('./verified_users.json').usernames;
  const dryRun = flags.includes('--dry-run');
  setVerified(db, usernames, { revoke: flags.includes('--revoke'), dryRun })
    .then((r) => {
      console.log(`${production ? projectId : 'emulator'}${dryRun ? ' (dry run)' : ''}:`, JSON.stringify(r, null, 2));
      if (r.missing.length) console.log('Usernames not found (check the exact spelling):', r.missing.join(', '));
    })
    .catch((e) => {
      console.error(e.message);
      process.exit(1);
    });
}

module.exports = { setVerified };
