// Shared start-up of the admin scripts: the emulator unless the owner passes
// `--project <id> --production` (then the machine's Google credentials are
// used, e.g. after `gcloud auth application-default login`).
'use strict';

const admin = require('firebase-admin');

function init(argv = process.argv.slice(2)) {
  const production = argv.includes('--production');
  const projectIndex = argv.indexOf('--project');
  const projectId = projectIndex >= 0 ? argv[projectIndex + 1] : 'demo-later-admin';
  if (production && projectIndex < 0) throw new Error('--production needs --project <id>');
  if (!production && (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST)) {
    throw new Error(
      'No emulator configured. Set FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST, ' +
        'or pass --project <id> --production to change the real project.',
    );
  }
  admin.initializeApp({ projectId });
  const args = argv.filter((a, i) => !a.startsWith('--') && argv[i - 1] !== '--project');
  return { admin, db: admin.firestore(), auth: admin.auth(), production, projectId, args, flags: argv };
}

/** uid of a username (from its reservation), or null. */
async function uidOfUsername(db, username) {
  const doc = await db.collection('usernames').doc(username.trim().toLowerCase()).get();
  return doc.exists ? doc.get('uid') : null;
}

module.exports = { init, uidOfUsername };
