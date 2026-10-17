#!/usr/bin/env node
// Grants (or with --revoke removes) the `admin` custom claim, which allows
// sending announcements (sendAnnouncement). The user signs in again to get it.
//
//   node set-admin.js <email-or-uid> [--revoke] [--project <id> --production]
'use strict';

const { init } = require('./common');

async function setAdmin(auth, who, revoke = false) {
  const user = who.includes('@') ? await auth.getUserByEmail(who) : await auth.getUser(who);
  const claims = { ...(user.customClaims || {}) };
  if (revoke) delete claims.admin;
  else claims.admin = true;
  await auth.setCustomUserClaims(user.uid, claims);
  return { uid: user.uid, admin: !revoke };
}

if (require.main === module) {
  const { auth, args, flags, production, projectId } = init();
  if (!args[0]) {
    console.error('usage: node set-admin.js <email-or-uid> [--revoke] [--project <id> --production]');
    process.exit(2);
  }
  setAdmin(auth, args[0], flags.includes('--revoke'))
    .then((r) => console.log(`${production ? projectId : 'emulator'}:`, r))
    .catch((e) => {
      console.error(e.message);
      process.exit(1);
    });
}

module.exports = { setAdmin };
