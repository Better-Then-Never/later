# BACKEND_CHANGES.md: server changes in Session A (none deployed)

Rules for every change here: additive and backward compatible (old app versions keep working), covered by
rules or functions tests in the emulator, cost-aware, and **not deployed** by this session. Deploy steps are
written for the owner.

## Summary
| # | Change | Kind | Old apps | Tests | Deploy |
|---|---|---|---|---|---|
| 1 | Functions emulator logs pushes instead of sending them | functions (emulator only) | unaffected | functions 43/43 | with the next functions deploy; no effect in production |
| 2 | Photo messages: rules for type "image", Storage folder per chat, `deleteChatPhoto`, photo pushes, account cleanup | rules, storage rules, functions | unaffected (read photos as text) | rules + functions (see section 2) | IAM grant, rules, one new function (gcloud), functions |
| 3 | Typing hints (`chats/{id}/typing/{uid}`); offline batched send (rules unchanged, test added) | rules | unaffected | rules | rules |
| 4 | Group chats: `chats/g_{id}` rules, invites, `acceptGroupInvite`, group pushes, account cleanup | rules, functions | unaffected (never see groups) | rules + functions | rules, one new function (gcloud), functions |

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

## 3. Offline sending and typing hints (Part B1)
**Firestore rules**: new subcollection `chats/{chatId}/typing/{uid}` `{at}`: the participants (or group members)
read; each writes only their own, with `at` = server time and nothing else; each deletes only their own. The
batched send path (message + `unreadCounts.{to}: increment(1)`) needed no rule change: the existing "exactly one
more" check accepts it (new rules test).

**Old apps**: unaffected (they never read or write `typing`).

**Cost**: a typing hint is one tiny write at most every 4 s per person typing; each other participant reads it.

**Deploy**: with the rules (`firebase deploy --only firestore:rules`).

## 4. Group chats (Part B1)
**Firestore rules** (`chats/g_{id}`):
- create: by a signed-in user, `members == [me]`, `createdBy == me`, a name of 1–60 characters, an empty summary
  and server times; nothing else.
- read (get, and the `members array-contains me` query): members only. The old `participants` query never returns
  groups.
- update by members: send (summary), read mark (own key, server time), rename, roll the summary back after
  deleting the newest message, leave (only yourself, with your read mark). Clients cannot add members.
- `invites/{uid}` `{by, at}`: a member invites someone not in it while the group has room; only the function
  deletes invites.
- messages: members read; members create text messages (replies may quote any member); reactions as in
  two-person chats; each member deletes only their own. No photos or capsules in groups yet.
- `typing/{uid}`: members, each their own.

**Functions**:
- `acceptGroupInvite` (new; `chats/{chatId}/invites/{uid}` created): in a transaction, adds the invited person
  if the inviter is a member, the group has fewer than 20 people, the invited person has the inviter among their
  friends, blocked nobody in the group and is not blocked by the inviter; deletes the invite either way. It runs
  only for invites, never for ordinary chat writes.
- `sendMessageNotification` (changed): a message in a group goes to every other member (at most 20), each by
  their own settings, titled with the group's name ("Anna: text").
- `cleanupDeletedAccount` (changed): removes the account from every group it was in.

**Old apps**: unaffected; groups are invisible to them (no `participants`), and their two-person chats work as
before (`isMember()` now also requires a non-group id, which their chat ids always are).

**Cost**: one function run per invite (up to 20 per group), with bounded reads (the group, the invitee, their
block list, one block document of the inviter). Group pushes: one settings read and one token read per member.

**Tests**: rules 69/69 (groups, invites, typing), functions 48/48.

**Deploy (owner)**:
1. `firebase deploy --only firestore:rules --project later-da778`
2. Create `acceptGroupInvite` once with gcloud like the other Firestore triggers (DEPLOY.md, section 2), with
   `--trigger-event-filters=type=google.cloud.firestore.document.v1.created` and
   `--trigger-event-filters-path-pattern=document='chats/{chatId}/invites/{uid}'`.
3. `firebase deploy --only functions --project later-da778` (updates the changed functions).
4. Release the app. Until step 2 is done, a new group keeps only its creator (invites wait).
