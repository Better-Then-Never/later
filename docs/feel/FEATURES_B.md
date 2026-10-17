# FEATURES_B.md: Part B, feature by feature

Every feature here was built on the Part A foundation (MOTION_CATALOG.md rules, tokens, five languages). Status:
**ON** (shipped in the build), **FLAGGED** (built, off in `lib/core/config/feature_flags.dart`), **NOT BUILT**.
"Phone" means checked on the reference phone (DEVICE.md) against the emulators; everything else is tests only.
Server changes are in BACKEND_CHANGES.md; none is deployed.

## B1. Chat

### Photo messages: ON
- **What**: a camera button in the message field offers the gallery or the camera; a card shows the photo with a
  caption field and Send (it stays between the status bar and the keyboard). The photo appears at once in its
  bubble, in its own proportions, with a turning ring while it uploads; then the time and "Sent". Tapping it opens
  the full-screen viewer (hero). The chat list says "📷 Photo"; a reply quotes "📷 Photo" or "📷 caption"; the
  menu has no "Copy" for a photo without a caption; deleting removes the file too.
- **How**: resized on the phone to ≤ 1600 px JPEG off the UI isolate (`ImageProcessor.chatJpegFromFile`),
  uploaded to `chats/{chat}/{sender}/{messageId}.jpg`, then the message (type `image`, URL, path, width, height)
  in the same transaction as text messages. The uploaded bytes go into the image cache under their URL, and the
  bubble keeps showing the phone's file after the server confirms, so the sender never downloads or reloads it.
  A failed upload is retried with the message; a failed send after a good upload sends without uploading again;
  an upload whose answer was lost is reused (the rules refuse replacing a sent photo).
- **Older app versions** show the caption, or "📷".
- **Tests**: `messages_test.dart` ("Photo messages", "ChatController photos": shown at once, upload once, retry,
  quote, delete with file), `photo_message_test.dart` (shape, caption, ring, tap, the card above a keyboard),
  rules (photo messages, the Storage folder), functions (`chats.test.js`, photo pushes).
- **Phone** (Russian, light): photo button, menu, system camera, the card (with and without the keyboard), a photo
  with a caption and one without sent through the emulators' rules and Storage, the viewer, the chat list preview,
  delete (the cleanup function ran in the emulator).
- **Not done**: no gallery multi-select or albums; no upload progress percentage (a ring only); a photo that
  uploaded but whose message was then deleted while "not sent" leaves its file (rare; no message exists for the
  server cleanup to follow); pushes could not be delivered (no dev project).

### Offline send queue: ON (text in chats that exist; photos retry by hand)
- **What**: a message written without a connection shows at once as "Sending…", stays through closing and
  reopening the app, and goes by itself when the connection is back.
- **How**: in a chat the phone already has, the message and its +1 unread go as one batched write (the unread by
  `FieldValue.increment`, which the existing rule "exactly one more" accepts). Firestore keeps batched writes in its
  local queue, also across restarts. Pending writes show as "Sending…" from the snapshot's `hasPendingWrites`.
  The first message of a new chat still uses the transaction (it creates the chat) and needs a connection; it
  shows "Not sent · Tap to retry" offline, as before.
- **Tests**: rules "in a chat that exists, a message and +1 unread go as one batched write"; repository test on
  fake Firestore (first message creates the chat, later ones add one unread each).
- **Phone**: Firestore cut off (its port mapping removed), a message sent → "Sending…"; the app killed and
  started again, still offline → still "Sending…" and in the chat list; connection back → "Sent".
- **Not done**: photos are not queued across restarts (the upload stops after 45 s offline and the photo shows
  "Not sent · Tap to retry"); groups always use the queued path.

### Typing indicator: ON
- **What**: "typing" with three waving dots under the friend's name; in a group "Anna is typing" or "2 people
  are typing". It shows for 6 s after each hint, ends when their message arrives or they clear the field, and a
  hint left from long ago (an app that died mid-sentence) is ignored. Reduced motion: still dots.
- **How**: `chats/{chat}/typing/{uid}` with a server time, written at most every 4 s while typing and deleted on
  clearing or sending; the receiving phone times it with its own clock, so clocks that disagree do not matter.
- **Cost**: one small write every 4 s per person typing, one read per hint for those in the chat.
- **Tests**: controller (throttling, stop on send and clear, show/fade, stale hint, several people in a group),
  `typing_label_test.dart` (dots stop with reduced motion and when gone; live region for screen readers), rules.
- **Phone**: both directions in a two-person chat; two people at once in a group ("Печатают 2 человека").

### Group chats: ON (text and replies)
- **What**: "New group" at the top of the new-chat sheet: a name and friends to pick (up to 20 people). Groups
  appear in the chat list with their own gradient picture and the first letter of the name, and previews like
  "Ben: Count me in". In the chat, others' messages carry their name over each run; replies, reactions,
  deleting your own messages, typing and read state work as in two-person chats ("Read" once everyone has). The
  menu has search, members, add people, rename, mute and leave. A push says the group's name and "Anna: text".
- **How**: `chats/g_{id}` with `members` (not `participants`, so older apps never list it). A group starts with
  its creator; members invite people (`invites/{uid}`) and the `acceptGroupInvite` function adds those who are
  the inviter's friends and blocked nobody in the group. Unread for a group is "something new since my read
  mark", not a count (no per-member counters to keep).
- **Tests**: rules (create, list, messages, replies within the group, reactions, own deletes, read marks,
  rename, leave, invites, typing), functions (`acceptGroupInvite`, group pushes, account deletion leaves groups),
  controller and store ("Groups" in `messages_test.dart`).
- **Phone**: created "Weekend trip" with two friends; the function accepted both invites ("3 участника"); a
  message sent; two members typing; their messages with names; the list row; menu, members, rename ("Lake
  weekend") and leave (the chat closed, the group left the list, the server's members updated).
- **Not done (BLOCKERS.md)**: photos and capsules in groups (Storage rules cannot check a group's members
  without cross-service rules); messages from someone you blocked still show in a group you share; no admin
  roles (anyone in it can rename and add their friends); no group picture.

### Voice messages: ON on Android (iOS: button hidden)
- **What**: while the message field is empty, the send button is a microphone. Tapping it (after the system asks
  for the microphone once) replaces the field with a recording bar: a pulsing red dot, the time, the live loudness,
  a cross to throw it away and Send. Up to 5 minutes (then it is sent); under a second is not sent ("Too short to
  send"). The bubble has play/pause, 40 loudness bars that fill as it plays (tap or drag them to jump) and the
  length or position. One message plays at a time; leaving the chat stops it. The list says "🎤 Voice message";
  a reply quotes "🎤 Voice message"; the push says "🎤 Voice message".
- **How**: no new package. The app's own channel `later.app/voice` (`VoiceChannel.kt`: `MediaRecorder` AAC/M4A,
  64 kbit/s mono; `MediaPlayer`) and `VoiceService` on the Dart side. The recording goes to
  `chats/{chat}/{sender}/{id}.m4a`; the message carries its length and the bars. Others' recordings are downloaded
  once into their own disk cache (`later_voice`, 30 days); the sender plays the file on the phone.
- **Permission**: `RECORD_AUDIO` is back in the Android manifest (it had been removed with `tools:node`); the iOS
  microphone string now says it is for voice messages.
- **Tests**: `voice_test.dart` (bars from levels; the player against a mocked channel: play, progress, pause,
  resume, one at a time, the end; sending through the controller; the bubble's labels and stopping on leave),
  rules (voice messages, `.m4a` in the chat folder), functions (cleanup of recordings, push text).
- **Phone** (Russian, light): the microphone button, the bar with the timer and live loudness, a 20-second
  recording sent through the emulators' rules and Storage, played from the phone's file, then after a restart
  played from Storage (downloaded), the list preview.
- **Not done**: iOS (no recorder written; the button is hidden there, BLOCKERS.md); no hold-to-record gesture (a
  tap starts it, which is also easier with a screen reader); voice messages in groups (the same Storage limit as
  photos); playback speed.

### Big emoji and the sticker panel: ON (illustrated packs: owner)
- **What**: a message of one to three emoji alone is shown large (56 / 44 / 36 px) without a bubble, like a
  sticker. The smiley in the message field opens a panel of big emoji in five groups (faces, hands, hearts and
  parties, places and things, nature) and the ones used lately; one tap sends.
- **How**: client only; the messages are ordinary text, so older apps show them as emoji. Recents are kept on the
  phone per account.
- **Tests**: `emoji_only_test.dart` (skin tones, families, flags; digits and words are not emoji; the large
  rendering; the panel sends and remembers).
- **Phone**: the smiley in the field, the panel, a party emoji sent large.
- **Not built**: illustrated sticker packs (they need artwork; BLOCKERS.md, owner decision).

### Smaller chat gaps
| Gap | State | How | Checked |
|---|---|---|---|
| Unread divider | ON | "Unread messages" over the first message unread when the chat opened (from the unread count in two-person chats, the read mark in groups); it stays while the chat is open | test; phone (3 unread from Hugo) |
| Delete for me | ON | any delivered message, kept hidden on this phone per account and chat (500 at most); "Delete for everyone" for your own, as before | test; phone (menu) |
| Forward | ON (text and big emoji) | to a friend or a group, marked "Forwarded" (optional `forwarded: true`, rules test) | test; phone (forwarded to a new chat) |
| Report a message | ON | someone else's message, for a reason (the capsule report picker, shared); `reports` already accepted messages | test; phone (menu) |
| Unread count on delete | ON | taking back a message the friend had not read lowers their count by one in the same batch (new rule: exactly −1, never below 0, never your own); deleting the only message clears the counts | test, rules test |
| Quote jump beyond the loaded page | ON | loads older pages (up to 10) until the quoted message is there; says so when it was deleted | test |
| Swipe actions | ON | in the chat list: right pins / unpins, left mutes / unmutes; the row springs back; the same actions are in the chat menu for screen readers | phone (pin and mute by swipe) |
| Pinned chats | ON | up to 3 at the top, in the order pinned, with a small pin; synced through the settings document (`pinnedChats`) | test; phone |
| Reaction pushes | ON (server) | `sendMessageReactionNotification` tells a message's author about a new reaction | functions test; emulator log on the rig (push built in Russian, not sent) |
- **Not done**: forwarding photos, recordings and capsules (their files belong to the first chat's folder); an
  "unread" jump button; reporting a whole chat.
