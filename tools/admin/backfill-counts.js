#!/usr/bin/env node
// One-off backfill after deploying the social functions: the follower and
// following counters and the capsule totals only move from the day the
// functions run, so existing accounts would show 0. This counts what already
// exists and writes it once. Safe to run again (it sets, not increments).
//
// Streaks, places and distance are not rebuilt: they start fresh (a streak
// needs capture days, places need the private cells), as DEPLOY.md explains.
//
//   node backfill-counts.js [--dry-run] [--project <id> --production]
'use strict';

const { init } = require('./common');

async function backfillCounts(db, { dryRun = false } = {}) {
  const report = { users: 0, changed: 0 };
  const users = await db.collection('users').get();
  for (const user of users.docs) {
    report.users++;
    const ref = user.ref;
    const [followers, following, capsules, publicCapsules] = await Promise.all([
      ref.collection('followers').count().get(),
      ref.collection('following').count().get(),
      db.collection('capsules').where('ownerId', '==', user.id).count().get(),
      db.collection('capsules')
        .where('ownerId', '==', user.id)
        .where('privacy', '==', 'public')
        .count()
        .get(),
    ]);
    const counts = {
      followerCount: followers.data().count,
      followingCount: following.data().count,
      'stats.capsules': capsules.data().count,
      'stats.publicCapsules': publicCapsules.data().count,
    };
    const stats = user.get('stats') || {};
    const same =
      user.get('followerCount') === counts.followerCount &&
      user.get('followingCount') === counts.followingCount &&
      stats.capsules === counts['stats.capsules'] &&
      stats.publicCapsules === counts['stats.publicCapsules'];
    if (same) continue;
    report.changed++;
    if (!dryRun) await ref.update(counts);
  }
  return report;
}

if (require.main === module) {
  const { db, flags, production, projectId } = init();
  const dryRun = flags.includes('--dry-run');
  backfillCounts(db, { dryRun })
    .then((r) => console.log(`${production ? projectId : 'emulator'}${dryRun ? ' (dry run)' : ''}:`, JSON.stringify(r)))
    .catch((e) => {
      console.error(e.message);
      process.exit(1);
    });
}

module.exports = { backfillCounts };
