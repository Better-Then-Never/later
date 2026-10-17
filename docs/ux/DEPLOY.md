# DEPLOY.md: putting this branch live (owner only)

Nothing in this branch has been deployed. Everything below changes the real project `later-da778` and must be
run by the owner, in this order. The app on this branch also works against the **old** backend (it falls back
to the older document shape once, see "Compatibility"), but the new features only work once steps 1-3 are done.

## 0. Before
- Merge order: PR #77 (polish) is contained in this branch. Merging #78 into `main` **publishes a release**
  (`release.yml`), so deploy the backend (steps 1-3) first, then merge.
- Check `firebase projects:list` shows `later-da778` and `gcloud config get-value project` is `later-da778`.

## 1. Firestore rules and indexes
```
firebase deploy --only firestore:rules,firestore:indexes --project later-da778
```
- Rules: additive (new optional fields and subcollections; old app versions keep working). Tested by
  `tools/rules-tests` (53/53).
- Indexes: field overrides for `reactions.uid`, `comments.authorId` (collection-group queries used by account
  deletion) and `settings.notifications.streakReminder` (collection group, streak reminders). Wait until the
  console shows them as "Enabled" before step 2's scheduled function runs (a few minutes).
- Storage rules: unchanged.

## 2. Cloud Functions
The project's default compute service account was deleted, so **every new function must be created once with
gcloud** (as was done for the previous release), then `firebase deploy` updates them. New functions:

| Function | Trigger |
|---|---|
| countFollowerAdded / countFollowerRemoved | users/{uid}/followers/{x} created / deleted |
| countFollowingAdded / countFollowingRemoved | users/{uid}/following/{x} created / deleted |
| onReactionWritten | capsules/{id}/reactions/{uid} written |
| onCommentCreated / onCommentDeleted | capsules/{id}/comments/{id} created / deleted |
| onFriendRequestCreated / onFriendRequestUpdated | friend_requests/{id} created / updated |
| updateCapsuleStats | capsules/{id} created |
| unlockAchievements | users/{uid} updated |
| sendStreakReminders | schedule, every 60 minutes (needs the Cloud Scheduler API) |
| sendAnnouncement | callable (admin claim only) |

For each, the first creation (example for one Firestore trigger; adjust the event filters per the table and
`functions/index.js`):
```
gcloud functions deploy countFollowerAdded --gen2 --region=europe-west1 --runtime=nodejs22 \
  --source=functions --entry-point=countFollowerAdded \
  --trigger-event-filters=type=google.cloud.firestore.document.v1.created \
  --trigger-event-filters=database='(default)' \
  --trigger-event-filters-path-pattern=document='users/{uid}/followers/{followerId}' \
  --trigger-location=eur3 \
  --service-account=later-functions@later-da778.iam.gserviceaccount.com \
  --build-service-account=projects/later-da778/serviceAccounts/later-functions@later-da778.iam.gserviceaccount.com
```
Regions: the Firestore-triggered functions go next to the database, `europe-west1` with an `eur3` trigger, as
`sendMessageNotification` did in the last release; the callable `sendAnnouncement` and the scheduled
`sendStreakReminders` have no database trigger and take the CLI default `us-central1` like the older functions.
Check with `gcloud functions list` after the first one and keep the same pattern. For the callable use
`--trigger-http` instead of the event filters; for the scheduled one, let `firebase deploy` create the
Cloud Scheduler job after a `gcloud functions deploy ... --trigger-topic=firebase-schedule-sendStreakReminders-us-central1`
first-create (the topic name the CLI uses), or create it from the console with the same build service account.
Then:
```
cd functions && npm ci && npm test   # 43/43 against the emulators
firebase deploy --only functions --project later-da778
```
Existing functions are only updated (localized pushes, new notification categories). The push texts now come in
the user's language (`settings.language`, written by the app).

## 3. One-off data steps (owner's machine, `gcloud auth application-default login` first)
```
cd tools/admin && npm ci
node backfill-counts.js --dry-run --project later-da778 --production   # look at the counts
node backfill-counts.js --project later-da778 --production             # follower/following/capsule totals
node set-admin.js <your-email> --project later-da778 --production       # admin claim for announcements
node set-verified.js --dry-run --project later-da778 --production       # see BLOCKERS.md about "amo b3"
node set-verified.js --project later-da778 --production
```
Streaks, places and distance are not rebuilt from history: they start counting from the deploy.

## 4. App
Merge PR #78 into `main` when the backend is live (this creates the release). Store listings: the app no
longer asks for microphone or contacts (removed from the Android manifest).

## Compatibility
- Old app + new backend: works (all additions are optional fields; old documents read with defaults).
- New app + old rules: the first capsule save with the new fields is rejected, the app retries once without them
  (`FirestoreMappers.legacyCapsule`); notification settings fall back to the old keys the same way. Language,
  privacy and reactions/comments need the new rules.
- Rollback: redeploy the previous rules (`git show main:firestore.rules`); the new functions can stay (they only
  react to new documents) or be deleted in the console.

## Not deployed, on purpose
- `tools/admin` scripts never run against production by default (they need `--project <id> --production`).
- No App Check, no new Storage rules.
