# BACKEND_CHANGES.md: server changes in Session A (none deployed)

Rules for every change here: additive and backward compatible (old app versions keep working), covered by
rules or functions tests in the emulator, cost-aware, and **not deployed** by this session. Deploy steps are
written for the owner.

## Summary
| # | Change | Kind | Old apps | Tests | Deploy |
|---|---|---|---|---|---|
| 1 | Functions emulator logs pushes instead of sending them | functions (emulator only) | unaffected | functions 43/43 | with the next functions deploy; no effect in production |
| 2 | Photo messages: rules for type "image", Storage folder per chat, `deleteChatPhoto`, photo pushes, account cleanup | rules, storage rules, functions | unaffected (read photos as text) | rules + functions (see section 2) | IAM grant, rules, one new function (gcloud), functions |

## 1. Pushes are logged, not sent, in the Functions emulator
`functions/index.js`: when `FUNCTIONS_EMULATOR === 'true'` (set only by the Firebase emulator), `services()`
hands the triggers a `loggedMessaging` object with the same `send` / `sendEach` shape instead of
`admin.messaging()`. Production is unaffected: the variable is never set there.

Why: the phone rig (docs/feel/RIG.md) runs the real triggers against the emulators so counters, notifications and
achievements behave as in production. FCM has no emulator; without this, a trigger would send a real push
through FCM with the developer's credentials.

Deploy: nothing to do on its own; it ships with the next `firebase deploy --only functions`.

## 2. Photo messages in chats (Part B1)
**Firestore rules** (`firestore.rules`, `chats/{chatId}/messages`): a message may now have `type: 'image'` with
`imageUrl` (≤ 2,048 characters), `imagePath` and optional `width` / `height` (whole numbers, 1–10,000).
`imagePath` must be `chats/{this chat}/{the sender}/{id}.jpg`. The text stays required (the caption, or "📷"), so
old app versions show a photo message as that text. Nothing else changed; text and capsule messages are checked
exactly as before.

**Storage rules** (`storage.rules`): new folder `chats/{uidA_uidB}/{sender}/{id}.jpg`. The sender creates (JPEG
or any `image/*`, ≤ 5 MB, name of 1–40 letters and digits), nobody replaces, only the sender deletes; both
participants read. The app shows photos through download URLs, like capsule photos.

**Functions**:
- `deleteChatPhoto` (new; `chats/{chatId}/messages/{messageId}` deleted): deletes the message's photo file, so a
  deleted photo, a cleared history or a deleted account leaves no file behind. Only paths inside that chat's
  folder are touched. One invocation per deleted message (cheap; "Clear history" of a long chat runs it once per
  message, and only photo messages do Storage work).
- `cleanupDeletedAccount` (changed): also deletes `chats/{chatId}/` files of every chat of the account.
- `sendMessageNotification` (changed): a photo's push says "📷 caption", or "Sent you a photo" (5 languages) when
  it has none or previews are off.

**Old apps**: unaffected; they never write `type: 'image'` and read photo messages as text.

**Tests**: rules tests "a photo message points at a file of this chat sent by its sender" and the "chat photos"
Storage block; functions tests `chats.test.js` and the photo lines in `notify.test.js` (results in FEATURES_B.md).

**Cost**: one Storage object per photo (≤ 1600 px JPEG, typically 150–400 KB), one function run per deleted
message. Reads unchanged (the photo's size travels in the message).

**Deploy (owner, in this order)**:
1. Grant the functions' service account delete rights on the bucket. It has only *Storage Object Viewer*
   (MIGRATIONS_NEEDED.md), so `deleteChatPhoto` **and the existing account cleanup's file deletion** fail today:
   ```
   gcloud storage buckets add-iam-policy-binding gs://later-da778.appspot.com \
     --member=serviceAccount:later-functions@later-da778.iam.gserviceaccount.com \
     --role=roles/storage.objectUser
   ```
   (check the bucket name with `gcloud storage buckets list`).
2. `firebase deploy --only firestore:rules,storage --project later-da778`
3. Create `deleteChatPhoto` once with gcloud like the other new Firestore triggers (DEPLOY.md, section 2), with
   `--trigger-event-filters=type=google.cloud.firestore.document.v1.deleted` and
   `--trigger-event-filters-path-pattern=document='chats/{chatId}/messages/{messageId}'`, then
   `firebase deploy --only functions --project later-da778` updates it and the two changed functions.
4. Release the app (photos fail with "Not sent" against the old rules, so the rules go first).
