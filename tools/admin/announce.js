#!/usr/bin/env node
// Sends an announcement to everyone with "News and updates" on, through the
// same code as the admin-only sendAnnouncement function (functions/lib/broadcast.js).
//
//   node announce.js message.json [--project <id> --production]
//
// message.json: { "title": {"en": "...", "ru": "..."}, "body": {"en": "..."},
//                 "languages": ["en", "de"], "platform": "android" }  (last two optional)
'use strict';

const fs = require('fs');
const { init } = require('./common');
const broadcast = require('../../functions/lib/broadcast');

if (require.main === module) {
  const { admin, db, args, production, projectId } = init();
  if (!args[0]) {
    console.error('usage: node announce.js message.json [--project <id> --production]');
    process.exit(2);
  }
  const data = JSON.parse(fs.readFileSync(args[0], 'utf8'));
  const caller = { uid: 'admin-script', token: { admin: true } };
  broadcast
    .sendAnnouncement({ db, messaging: admin.messaging() }, caller, data)
    .then((r) => console.log(`${production ? projectId : 'emulator'}:`, r))
    .catch((e) => {
      console.error(e.message);
      process.exit(1);
    });
}
