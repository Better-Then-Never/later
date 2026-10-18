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
const path = require('path');
const { init } = require('./common');
const broadcast = require('../../functions/lib/broadcast');

/**
 * The functions' firebase-admin: broadcast.js writes its server timestamp
 * with that copy, so the database must come from the same one (with this
 * folder's own copy the write failed: "Couldn't serialize object of type
 * ServerTimestampTransform").
 */
const functionsAdmin = () =>
  require(require.resolve('firebase-admin', { paths: [path.join(__dirname, '..', '..', 'functions')] }));

/** Sends [data] as the admin script; [messaging] defaults to FCM. */
function announce({ db, messaging }, data) {
  const caller = { uid: 'admin-script', token: { admin: true } };
  return broadcast.sendAnnouncement({ db, messaging }, caller, data);
}

if (require.main === module) {
  const { admin, db, args, production, projectId } = init(process.argv.slice(2), functionsAdmin());
  if (!args[0]) {
    console.error('usage: node announce.js message.json [--project <id> --production]');
    process.exit(2);
  }
  const data = JSON.parse(fs.readFileSync(args[0], 'utf8'));
  announce({ db, messaging: admin.messaging() }, data)
    .then((r) => console.log(`${production ? projectId : 'emulator'}:`, r))
    .catch((e) => {
      console.error(e.message);
      process.exit(1);
    });
}

module.exports = { announce, functionsAdmin };
