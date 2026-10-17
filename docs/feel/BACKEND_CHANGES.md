# BACKEND_CHANGES.md: server changes in Session A (none deployed)

Rules for every change here: additive and backward compatible (old app versions keep working), covered by
rules or functions tests in the emulator, cost-aware, and **not deployed** by this session. Deploy steps are
written for the owner.

## Summary
| # | Change | Kind | Old apps | Tests | Deploy |
|---|---|---|---|---|---|
| 1 | Functions emulator logs pushes instead of sending them | functions (emulator only) | unaffected | functions 43/43 | with the next functions deploy; no effect in production |
| 2 | Photo messages: rules for type "image", Storage folder per chat, `deleteChatFile`, photo pushes, account cleanup | rules, storage rules, functions | unaffected (read photos as text) | rules + functions (see section 2) | IAM grant, rules, one new function (gcloud), functions |
| 3 | Typing hints (`chats/{id}/typing/{uid}`); offline batched send (rules unchanged, test added) | rules | unaffected | rules | rules |
| 4 | Group chats: `chats/g_{id}` rules, invites, `acceptGroupInvite`, group pushes, account cleanup | rules, functions | unaffected (never see groups) | rules + functions | rules, one new function (gcloud), functions |
| 5 | Voice messages (rules, `.m4a` storage, cleanup), forwarded mark, unread drop on delete, `pinnedChats`, `sendMessageReactionNotification` | rules, storage rules, functions | unaffected | rules + functions | rules, one new function (gcloud), functions |
| 6 | Capsules: quick reply (`capsuleRef` on messages), co-authors (rules, index, notifications), share links on the web page; the groups index | rules, indexes, functions, hosting | unaffected (see section 6) | rules 75/75, functions 52/52 | rules, indexes, functions, hosting |

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
- `deleteChatFile` (new; `chats/{chatId}/messages/{messageId}` deleted): deletes the message's photo file, so a
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
   (MIGRATIONS_NEEDED.md), so `deleteChatFile` **and the existing account cleanup's file deletion** fail today:
   ```
   gcloud storage buckets add-iam-policy-binding gs://later-da778.appspot.com \
     --member=serviceAccount:later-functions@later-da778.iam.gserviceaccount.com \
     --role=roles/storage.objectUser
   ```
   (check the bucket name with `gcloud storage buckets list`).
2. `firebase deploy --only firestore:rules,storage --project later-da778`
3. Create `deleteChatFile` once with gcloud like the other new Firestore triggers (DEPLOY.md, section 2), with
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

## 5. Voice messages and the smaller chat changes (Part B1)
**Firestore rules**:
- messages: `type: 'voice'` with `audioUrl` (≤ 2,048 characters), `audioPath` (`chats/{this chat}/{sender}/{id}.m4a`),
  `durationMs` (1–300,000) and an optional `waveform` list (≤ 64 entries); an optional `forwarded` that may only be
  `true`.
- chats: the sender may lower the other participant's unread count by exactly one (alone, or with the summary
  rollback after deleting the newest message); never below zero, never their own.
- settings: an optional `pinnedChats` list (≤ 10).

**Storage rules**: the chat folder also takes `.m4a` audio up to 5 MB (same owner, read and delete rules as photos).

**Functions**:
- `deleteChatFile` (was `deleteChatPhoto` before any deploy): also deletes a voice message's recording.
- `sendMessageReactionNotification` (new; `chats/{chatId}/messages/{messageId}` updated): pushes a new reaction to
  the message's author (their message settings, mutes and blocks apply; one push per change).
- `sendMessageNotification`: a voice message says "🎤 Voice message".

**Old apps**: voice messages show as "🎤", forwarded ones as plain text; old apps never lower counts or pin.

**Cost**: one function run per message update (reactions, and the read status older apps still write).

**Tests**: rules 71/71 at the voice commit, plus the forwarded, unread-drop and pinned additions (see the final
count in FEEL_QA.md); functions 51/51.

**Deploy (owner)**: rules and storage rules with the rest; create `sendMessageReactionNotification` once with
gcloud (`--trigger-event-filters=type=google.cloud.firestore.document.v1.updated`,
`--trigger-event-filters-path-pattern=document='chats/{chatId}/messages/{messageId}'`); `deleteChatFile` replaces
`deleteChatPhoto` in step 3 of section 2 (it was never deployed under either name).

## 6. Capsule interactions (Part B2)
**Firestore rules**:
- messages: an optional `capsuleRef {id, title}` (id 1–200 characters, title ≤ 140) for a quick reply to a
  capsule's author. Opening the capsule still goes through the capsule's rules.
- capsules, create: an optional `coAuthors` list: at most five, unique, never the owner, each a friend of the
  owner (one check per place: the rules have no loops).
- capsules, read: also for the capsule's co-authors (`canSee` and `canSeeCapsule`, so reactions and comments
  follow).
- capsules, update (was `if false`): only a co-author taking themselves off `coAuthors`; nothing else changes.

**Indexes** (`firestore.indexes.json`):
- `capsules`: `coAuthors` CONTAINS + `createdAt` DESC (the co-author's list).
- `chats`: `members` CONTAINS + `lastUpdated` DESC. The groups list from B1 needs it; it was missing (the
  emulator does not ask for indexes).

**Functions** (`sendCapsuleNotification`, changed): co-authors get an in-app notification
(`type: 'coAuthor'`, `message: 'made a capsule with you'`) and a push in their language, whatever the capsule's
privacy; followers who are also co-authors get only that one. At most five co-authors are read from the capsule
and each must be a friend of the owner.

**Hosting** (`public/index.html`): `?capsuleId=…` shows a neutral "A capsule for you" card (nothing of the capsule)
and opens `later://capsule/<id>` on phones. Only ids of letters, digits, `_` and `-` (≤ 64) are used.

**Old apps**: they ignore `capsuleRef` (the message text shows), never write `coAuthors`, and show the
`coAuthor` notification with its stored message (unknown types fall back to it). A co-authored capsule is not in
an old app's lists, but its push still arrives. The profile links on the web page work as before.

**Cost**: one more query per signed-in app (co-authored capsules, ≤ 100). Capsule creation: at most five more
notification writes and pushes.

**Tests**: rules 75/75 (co-authors: friends only, five, unique, not the owner, read, leave only; capsuleRef shape),
functions 52/52 (co-author notifications).

**Deploy (owner)**:
1. `firebase deploy --only firestore:indexes --project later-da778` first, and wait until both new indexes show
   "Enabled" in the console (the co-author query fails until then; the app logs it and goes on).
2. `firebase deploy --only firestore:rules --project later-da778`
3. `firebase deploy --only functions:sendCapsuleNotification --project later-da778`
4. `firebase deploy --only hosting --project later-da778` (the share links; without it a shared link opens the
   profile page's "Join Later" without opening the capsule).
5. Release the app.
