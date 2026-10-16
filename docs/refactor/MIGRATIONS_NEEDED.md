# MIGRATIONS_NEEDED.md

Nothing in this file has been run against the production project
(`later-da778`). Every step below is a decision for the project owner. All of it
was exercised on the local emulators only.

## 1. Deployment order

The refactored app, the Cloud Functions and the security rules depend on each
other. Deploy in this order:

| # | What | Command (run by the owner) | Why this order |
|---|---|---|---|
| 1 | Composite indexes | `firebase deploy --only firestore:indexes` | History (`ownerId` + `createdAt desc`) and the public map band (`privacy` + `location`) fail with `FAILED_PRECONDITION` without them. Safe for old app versions. Wait until the indexes show **Enabled** in the console. |
| 2 | Cloud Functions | `cd functions && npm ci && firebase deploy --only functions` | The new app stores push tokens in `users/{uid}/fcmTokens`. The old functions only read `users/{uid}.fcmToken`, so pushes would stop for users of the new app. The new functions read both. |
| 3 | App release | store release of this branch | |
| 4 | Data migration | §2 below | Removes private fields, reserves usernames, fixes legacy capsules. |
| 5 | Security rules | `firebase deploy --only firestore:rules,storage` | Last. Old app versions write things the new rules refuse: they store `email` and `fcmToken` on the user document, upload images without a content type, and write notifications for themselves when a push arrives. Deploy once most users run the new version, or after forcing an update. |

Before step 5, run the rules tests (`tools/rules-tests`, `npm run emulate`). Ideally also replay a sample of production documents against the rules in a staging project (BLOCKERS.md B-06). The repo never contained the rules production actually runs (FIREBASE_AUDIT.md §2.7).

## 2. Data migration (`tools/migrations/migrate.js`)

A dry run is the default. It refuses to run without `FIRESTORE_EMULATOR_HOST` unless it is given `--production`.

```sh
cd tools/migrations && npm install
# Rehearse on an emulator loaded with an export of production (recommended):
#   gcloud firestore export gs://<bucket>/backup   (owner)
#   firebase emulators:start --import <exported dir>
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node migrate.js            # dry run
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node migrate.js --apply
# Production (owner decision, after a backup):
GOOGLE_APPLICATION_CREDENTIALS=<service account json, never committed> \
  node migrate.js --project later-da778 --production            # dry run
  node migrate.js --project later-da778 --production --apply
```

What it does. It is idempotent: a second run finds nothing to do (tested in `migrate.test.js`).

| Collection | Change | Reason |
|---|---|---|
| `users/{uid}` | `username` lower-cased | Search is by lower-case prefix (BUG-072); the new rules accept only `^[a-z0-9._-]{3,30}$`. |
| `usernames/{username}` | created as `{uid}` for every user without one | Uniqueness (BUG-083): signup and username changes check these reservations. |
| `users/{uid}` | `email`, `fcmToken`, `fcmTokenUpdatedAt` removed | Every signed-in user can read user documents, so these leaked to everyone (BUG-071). The email is now read from Auth. |
| `users/{uid}/fcmTokens/{token}` | created from the legacy `fcmToken` | No device loses push before it opens the new app. |
| `capsules/{id}` | `ownerId` from legacy `creatorId`; missing `privacy` → `friends`; missing `createdAt` → document create time | The rules decide visibility from `ownerId`/`privacy`; history sorts by `createdAt`. |

It does not fix the following. They are reported as `conflicts` for a person to decide:
- usernames that become equal after lower-casing (e.g. `Alice` and `alice`),
- usernames that are not valid under the new pattern.

## 3. Manual clean-ups

- **Chat (from `main`) has no security rules yet.** The deployed `chats` index (participants array-contains + lastUpdated desc) belongs to the chat feature that exists only on `main`. `firestore.rules` on this branch has no `match /chats/...` block, so deploying these rules would block chat. Add chat rules (participants-only read/write) when porting `main` onto this branch, before step 5 of §1.

- **Public profile images.** The old `getUserData` function called `makePublic()` on profile images it served (BUG-103). Those objects stay world-readable, under a URL without a token, until their ACL is removed. For example: `gsutil -m acl ch -d AllUsers -r gs://later-da778.firebasestorage.app/userdata` (owner; check the bucket name first).
- **Old thumbnails.** `profile_image_small` files uploaded by old versions are 128×128 and squashed. They are replaced the next time the user changes their picture. No action is needed.
- **Functions region.** The functions run in `us-central1`, while Firestore is in `europe-central2`. Moving them is a deployment decision (FIREBASE_AUDIT.md §2.6). The landing page calls the `us-central1` URL.
- **Friend lists out of sync.** The old cross-user writes could leave one side of a friendship behind. The app copes. A query for users who list someone that does not list them back would find these cases (not automated).
