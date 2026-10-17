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
| 7 | Profiles: about, name search (nameLower), pinned friends, privacy switches; contacts index and requests (flagged) | rules, functions, data | unaffected | rules, functions 55/55 | rules; two new functions (gcloud) only with the contacts flag; optional backfill |
| 8 | Creation: thumb.jpg storage rule; WorkManager (app build only) | storage rules | unaffected | storage rules test | storage rules |
| 9 | Notifications: `notifications.vibrate`, channels without vibration; achievements checked where stats change (`unlockAchievements` removed); follower fan-out capped at 500 | rules, functions | unaffected (see section 9) | rules 79/79, functions 58/58 | rules, delete one function, functions |
| 10 | Gamification: capsules viewed (`viewed` markers, `onCapsuleViewed`, "Curious"), the world summary (`countryCode`, `world/summary`), `entitlements/limits` | rules, functions, data | unaffected (see section 10) | rules 82/82, functions 62/62 | rules, one new function (gcloud), functions, one config document |

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

## 7. Profiles (Part B3)
**Firestore rules**:
- `users/{uid}`, owner update: `about` (a string of at most 100 characters) and `nameLower` (only equal to
  `name.lower()` when written; may be removed; a rename without it is still accepted, so older apps keep working).
- settings: `pinnedFriends` (a list of at most 10); `privacy.findByName` and `privacy.findByContacts` (booleans).
- `contactIndex/{hash}`: closed to apps (functions only).
- `contactMatches/{uid}`: the owner writes `{hashes (≤ 1000), at (server time), status: 'pending'}` at most once an
  hour, reads it and may delete it.

**Functions** (`functions/lib/contacts.js`, new):
- `syncContactIndex` (new; `users/{uid}/settings/app` written): when `privacy.findByContacts` changes, adds or
  removes the user's entry: the hash of their **verified** Auth email. Runs on every settings write but reads
  nothing unless that switch changed.
- `matchContacts` (new; `contactMatches/{uid}` written): answers a pending request in place and drops the hashes.
  Reads at most 10 batched `getAll` of 100 index entries, then three small reads per person found.
- `cleanupDeletedAccount` (changed): also removes the user's index entry and last request.

**Data**: the seed writes `nameLower`; `tools/admin/backfill-name-search.js` (optional) writes it for accounts that
have not opened the new version yet, skipping anyone who switched "Find me by name" off (tried on the emulator:
written 1, up to date 103).

**Old apps**: unaffected; they never write the new fields (a rename by an old app leaves `nameLower` behind, which
the new app corrects on its next start).

**Cost**: the name search is a bounded prefix query (20); the contacts look-up is capped by the rules (one an hour).

**Tests**: rules (about and name search, pinned friends, privacy switches, contacts index and requests; the final
count is in FEEL_QA.md), functions 55/55.

**Deploy (owner)**:
1. `firebase deploy --only firestore:rules --project later-da778`
2. Only when the contacts flag is to be switched on: create `syncContactIndex`
   (`--trigger-event-filters=type=google.cloud.firestore.document.v1.written`,
   `--trigger-event-filters-path-pattern=document='users/{uid}/settings/app'`) and `matchContacts`
   (`document='contactMatches/{uid}'`) once with gcloud like the other Firestore triggers (DEPLOY.md section 2),
   then `firebase deploy --only functions --project later-da778`. The service account needs Firebase Auth read
   (it already reads users for account cleanup).
3. Optional: `cd tools/admin && node backfill-name-search.js --dry-run --project later-da778 --production`, then
   without `--dry-run`.
4. Release the app.

## 8. Creation (Part B4)
**Storage rules**: `userdata/{uid}/capsules/{capsuleId}/thumb.jpg`, an image of at most 512 KB, written by the
owner (the 400 px thumbnail of every capsule). The app tolerates rules without it (the capsule is saved without a
thumbnail).

**App build**: `androidx.work:work-runtime-ktx:2.9.1` (Google AndroidX) for uploads while the app is closed; no
server side.

**Old apps**: unaffected (they never write `thumb.jpg`; capsules without `thumbUrl` show their photo as before).

**Tests**: storage rules (thumbnail: owner, size).

**Deploy (owner)**: `firebase deploy --only storage --project later-da778`, then release the app.

## 9. Notifications (Part B6)
**Firestore rules**: settings `notifications.vibrate` (a boolean; missing means on).

**Functions**:
- `lib/prefs.js`: `alertOf(settings)` (`sound`, `vibrate` or `silent`) and `channelFor(kind, alert)`. People who
  switched vibration off get their pushes on `messages_novibrate` / `activity_novibrate`. Every sender now asks
  `alertOf` instead of reading `notifications.sound` itself.
- `lib/notify.js`: `capsuleRecipients` reads at most 500 followers (`MAX_FOLLOWER_FANOUT`); before, a capsule
  read every follower and every follower's `following` document.
- `lib/gamification.js`: `checkAchievements(services, uid)` reads the user once and unlocks what their stats
  reached; a catch-up notifies once (`notifyAtMost: 1`).
- `index.js`: `updateCapsuleStats`, `onReactionWritten`, `onCommentCreated` and `onFriendRequestUpdated` call
  it after their work. **`unlockAchievements` (a trigger on every `users/{uid}` update) is no longer exported.**
- `lib/social.js`: the reaction trigger returns the capsule's owner (for the check above).

**Old apps**: unaffected. They never write `vibrate` (pushes keep vibrating); they create only the old channels.
A push sent to an old app on a `*_novibrate` channel (only after the owner of that account switched vibration
off in a new app on another phone) falls back to Android's default channel. Achievements unlock as before, at the
moment a stat changes instead of on the next profile write.

**Cost**: fewer invocations (no trigger on every profile write; one user read per changed stat); the fan-out of one
capsule is bounded.

**Tests**: functions 58/58 (alert and channel per setting, the fan-out cap, `checkAchievements`, the single notice);
rules (`vibrate` accepted as a boolean, refused otherwise; the final count is in FEEL_QA.md).

**Deploy (owner)**:
1. `firebase deploy --only firestore:rules --project later-da778`
2. `firebase functions:delete unlockAchievements --region us-central1 --project later-da778` (the CLI would
   otherwise ask about it during the next step).
3. `firebase deploy --only functions --project later-da778`
4. Release the app (the new channels are created by the app on its first start).

## 10. Gamification and exploration (Part B7)
**Firestore rules**:
- `users/{uid}/viewed/{capsuleId}` (new): the owner creates a marker `{at: server time}` once (id ≤ 64
  characters); nobody updates or deletes it from an app; the owner reads it.
- `users/{uid}/world/{doc}` (new): written by the functions only; read by the owner, and by friends unless
  `showAchievements` is off (as achievements).
- `capsules` create: optional `countryCode`, two capital letters (ISO 3166).
- `entitlements/{doc}` (new): read by every signed-in app, written by nobody (console or the team's tools).

**Functions** (`functions/lib/gamification.js`, `functions/index.js`):
- `onCapsuleViewed` (new; `users/{uid}/viewed/{capsuleId}` created): counts the marker once in
  `stats.capsulesViewed` if the capsule is someone else's, already open, and one the user could open (public,
  shared with them, or a friend's friends-only capsule), records `counted` on the marker (a retried event counts
  nothing), then checks achievements.
- `updateCapsuleStats` (changed): a capsule with `countryCode` also updates `users/{uid}/world/summary` (per
  country: capsules, towns, first and last visit; at most 300 countries and 100 towns each) and
  `stats.countries` / `stats.cities`, in the same transaction.
- The achievement registry gains `curious` (`capsulesViewed`: 10, 50, 250, 1000), titles in five languages.

**Data**: `entitlements/limits`, a document to create once (today's numbers; the app uses its defaults while it is
missing):
```
{ capsulesPerWeek: null, loopFrames: 10, coAuthors: 5, groupMembers: 20, pinnedFriends: 3 }
```

**Old apps**: unaffected. They write no markers and no `countryCode`, and never read the summary or the limits.
Their capsules count as before; they just add no stamps. A new app against the old rules: the marker write is
refused quietly, the passport stays empty, and a capsule with `countryCode` is retried without this session's
fields, then in the legacy shape (`FirebaseCapsuleRepository._setNew`).

**Cost**: a view costs one write the first time a user opens a given capsule, one invocation, one or two reads, and
the achievement check (two reads). Opening it again costs nothing (the app keeps a set per run; a refused write is
not billed). The world summary adds one read to the capsule transaction, only for capsules with a country. The
passport is one document read; the limits are one read per sign-in.

**Tests**: functions 62/62 (views counted once and only when allowed, Curious, the summary: towns, first visit,
bounds, odd codes); rules (markers once, the summary read like achievements, the country code, the limits).

**Deploy (owner)**:
1. `firebase deploy --only firestore:rules --project later-da778`
2. Create `onCapsuleViewed` once with gcloud like the other new Firestore triggers (DEPLOY.md section 2), with
   `--trigger-event-filters=type=google.cloud.firestore.document.v1.created` and
   `--trigger-event-filters-path-pattern=document='users/{uid}/viewed/{capsuleId}'`, then
   `firebase deploy --only functions --project later-da778` (also updates `updateCapsuleStats`).
3. Create `entitlements/limits` in the console with the values above (optional: the defaults are the same).
4. Release the app.
