# DEPLOY_LOG.md: production deploy, night of 17–18 Oct 2026

Run at the owner's request ("deploy, then release"), project `later-da778`, from the night-session branch with
#79 merged into it (`ce75af7`). Order: backend first, then the release (merging #78). Times are CEST.

## What was done
| # | Step | Result |
|---|---|---|
| 1 | Storage delete rights for `later-functions` (BACKEND_CHANGES.md §2) | Already in place: `roles/storage.objectAdmin` on `gs://later-da778.firebasestorage.app` (granted on 17 Oct). Nothing changed. |
| 2 | `firebase deploy --only firestore:rules,firestore:indexes,storage` | ✓ 00:59. Rules of #77 + #78 + #79 (additive; the released app keeps working). |
| 3a | Cloud Scheduler API | Enabled by the Firebase CLI during the functions dry run (needed by `sendStreakReminders`). |
| 3b | 14 new Firestore-triggered functions, first created with gcloud | ✓ 01:03–01:10, `europe-west1` with an `eur3` trigger, `later-functions` as the run and build account (the default build account no longer exists): acceptGroupInvite, sendMessageReactionNotification, deleteChatFile, countFollowerAdded, countFollowerRemoved, countFollowingAdded, countFollowingRemoved, onReactionWritten, onCommentCreated, onCommentDeleted, onFriendRequestCreated, onFriendRequestUpdated, updateCapsuleStats, onCapsuleViewed. |
| 3c | `sendStreakReminders` (scheduled) and `sendAnnouncement` (callable), first created with gcloud | ✓ 01:17, `us-central1`, as HTTP functions carrying the labels the CLI expects (`deployment-scheduled`, `deployment-callable`). The first attempt of `sendStreakReminders` failed on a mistake in my script (a wrong entry point) and was fixed by the redeploy; without the labels the CLI refused to take them over. |
| 3d | `firebase deploy --only functions:<21 names>` | ✓ 01:19: the 5 existing and the 16 new functions updated by the CLI; Cloud Scheduler job `firebase-schedule-sendStreakReminders-us-central1` (every 60 minutes, enabled). No errors in the functions' logs afterwards. |
| 4 | `firebase deploy --only hosting` | ✓ `/`, `privacy.html`, `terms.html` answer 200; `/?capsuleId=<id>` serves the new share page. |
| 5a | `tools/admin/backfill-counts.js` (dry run, then for real) | ✓ 35 accounts written; a second dry run finds nothing to change. |
| 5b | `tools/admin/backfill-name-search.js` (dry run, then for real) | ✓ 35 accounts written (none had "Find me by name" off); a second dry run: 35 up to date. |
| 5c | `entitlements/limits` | ✓ created with today's numbers `{capsulesPerWeek: null, loopFrames: 10, coAuthors: 5, groupMembers: 20, pinnedFriends: 3}`. |
| 6 | Merge #78 into `main` | Publishes the release (`release.yml`), after its CI is green. |

The data scripts used the owner's gcloud login as application default credentials through an environment variable
for the run only; nothing was written to disk or to the repository.

## Not done, on purpose
- `syncContactIndex` and `matchContacts`: not deployed while `FeatureFlags.contactSuggestions` is off
  (BACKEND_CHANGES.md §7 has the steps for when it goes on).
- `unlockAchievements`: never reached production, so there was nothing to delete.
- `tools/admin/set-admin.js` (the admin claim for announcements): needs your account's email:
  `node set-admin.js <your-email> --project later-da778 --production` (from `tools/admin`, after
  `gcloud auth application-default login`).
- `tools/admin/set-verified.js`: your decision ("amo b3", docs/ux/BLOCKERS.md).
- Streaks, places and distance start counting from tonight (not rebuilt from history, as DEPLOY.md says).

## Morning checks
1. The release: install the APK from the newest GitHub release, sign in with a real account.
2. Pushes, the list in `docs/feel/BLOCKERS.md`: a message, a reaction, a comment, a friend request and an achievement,
   with the app in the foreground, in the background and closed; vibration off; quiet hours.
3. Features against production: a photo message, a group, a voice message, a co-authored capsule, a share link, a new
   capsule's stamp in the passport, the streak on the map.
4. The Firebase console: function errors, Firestore reads (the new functions add a few reads per event:
   BACKEND_CHANGES.md "Cost" lines).
5. The CLI warns that `firebase-functions` is outdated in `functions/package.json`: upgrade in a later change, not
   during a deploy.

## Rollback
- Rules: `git show 8e16d84:firestore.rules > firestore.rules && firebase deploy --only firestore:rules` (and the same
  for `storage.rules`); the app falls back to the older document shapes.
- Functions: the new ones only react to new documents; delete any in the console. The five older ones run the
  new code; redeploying from `8e16d84` brings back #77's version.
