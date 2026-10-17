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

## B2. Capsule interactions

### Share a capsule as a link: ON (public and friends-only capsules)
- **What**: a share button on the capsule card (not on private ones). The link is the existing web page with
  `?capsuleId=…`; on a phone it hands the id to the app as `later://capsule/<id>`, which opens the capsule over
  the map for someone allowed to see it, and says "This capsule isn't shared with you" otherwise.
- **How**: no Firebase Dynamic Links (shut down). The page shows nothing of the capsule (it may be for friends
  only) and accepts only an id of letters, digits, `_` and `-`. Android intent filter `later://capsule`.
- **Tests**: `capsule_social_test.dart` (who gets the button), `session_and_auth_test.dart` (link parsing, ids
  refused).
- **Phone** (Russian): the share sheet with "Капсула времени в Later: Festival" and the link;
  `adb shell am start -d later://capsule/<id>` opened the capsule over the map; an id the account cannot see
  showed "Эта капсула вам не открыта" (only after the toast fix below).
- **Not done**: the web page needs a hosting deploy (BACKEND_CHANGES.md §6); no preview image on the page by
  design; iOS universal links (none existed for profiles either).

### Quick reply to the author: ON
- **What**: on someone else's capsule a reply button opens a small card with a field; the text goes to the
  author's chat with the capsule attached, shown as a "Capsule" quote that opens it. A toast says "Sent to Anna".
- **How**: an ordinary text message with `capsuleRef {id, title}` (rules: `validCapsuleRef`); opening it still
  goes through the capsule's own rules. A centred card covered by another no longer makes room for the keyboard
  (the dialog under the reply card overflowed by 48 px on the phone).
- **Tests**: `messages_test.dart` (quick reply), rules (capsuleRef shape).
- **Phone**: the card over the capsule with the keyboard (the 48 px overflow was found here), sent, "Отправлено:
  Leo Ivanova" (only after the toast fix), the quote in Leo's chat opened the capsule.

### Who left it (`showAuthor`): ON
- **What**: under the title of someone else's capsule, their picture and name, which open their profile.
  Creation has a "Show my name" switch; when it is off, others see no name.
- **How**: the `showAuthor` field existed (F-60) but nothing set or read it; now creation writes `false` only
  when switched off (old documents read as shown).
- **Tests**: `capsule_social_test.dart`, `capsule_creation_test.dart`.
- **Phone**: Bob's and Leo's capsules showed their names, which opened the profile. The creation switch: tests
  only.

### Co-authors: ON
- **What**: a "Co-authors" row in creation picks up to five friends (the group picker). Others see "Anna with
  Ben, Carl" (unless the author hides their name); the owner sees "With Ben, Carl"; a co-author sees the owner
  and the other co-authors, never themselves. Co-authored capsules join My capsules and the map; deleting one
  there, or "Remove me as co-author" in the capsule's menu, only takes the user off it. Co-authors get a
  notification "Anna made a capsule with you" (in-app and push), whatever the capsule's privacy.
- **How**: `coAuthors: [uid]` on the capsule, checked by the rules on create (friends of the owner, unique, at
  most five, never the owner); co-authors can read it; a co-author may only remove themselves. The app follows
  `coAuthors array-contains me` (newest 100). The outbox keeps co-authors for capsules waiting for a connection.
- **Tests**: `history_test.dart` (merge, order, delete = leave), `map_test.dart` (visibility),
  `capsule_creation_test.dart` (five at most), `capsule_outbox_test.dart` (kept across a restart),
  `capsule_social_test.dart` (who sees whom), `notifications_test.dart` (the sentence), rules (co-authors),
  functions (`notify.test.js`: private capsule, strangers and duplicates dropped, a follower who is a co-author
  hears once).
- **Phone**: picker (two friends, "2 friends"), the capsule saved through the emulator's rules, both co-authors
  got the `coAuthor` notification from the function, the owner's card "With Anna Fischer, Ben Ivanova" (two
  lines); as a co-author: Bob's capsule in My capsules and on the map, the menu's "Remove me as co-author", the
  card closed, "You are no longer a co-author", the list dropped it.
- **Not done**: co-authors cannot be changed after creation (capsules are not editable); co-authors are not
  shown on the small map card (only in the opened capsule); the push itself could not be delivered (no dev
  project).

### Report everywhere: ON
- **What**: the friend menu's Report (a dead item until now) asks why and files a report on the profile. A
  stranger's profile (reached from a public capsule) had no menu at all; it now has one with Report and Block.
  The capsule card's menu button was invisible (the profile's white icon on a white card); it now shows, with
  Report (and "Remove me as co-author" for co-authors).
- **Tests**: `report_user_test.dart` (the flow; the stranger's menu, none on your own profile),
  `capsule_social_test.dart`.
- **Phone**: a capsule report and a stranger's profile report (reason, thank-you toast, the report in Firestore).
  The friend menu's Report: test only.

### Comments: pages and taps from notifications: ON
- **What**: comments load 200 at a time, newest first, with "Show earlier comments" at the top. A tap on a
  reaction, comment, reply or co-author notification opens the capsule over the map, and for comments and
  replies its thread (also for capsules without a place, which used to open nothing).
- **Tests**: `capsule_social_test.dart` (paging; the dialog opened for comments shows the thread).
- **Phone**: the first tap on a comment notification showed an error screen instead of the thread (the wait read
  MediaQuery in `initState`); fixed, then it opened the capsule and its thread. Paging: tests only (the seed has
  few comments per capsule).

### Fixed on the phone while building B2
| Bug | Cause | Fix |
|---|---|---|
| Creation page blank, button in the middle | Part A's save-morph button wrapped itself in a `Center`, which filled the bottom bar | `heightFactor: 1`; the button is its own widget with a test that fails without the fix |
| No toast after a card closed itself ("Sent to Anna", "not shared", leaving) | the toast looked for an Overlay above the root navigator | the service uses the navigator's overlay; test |
| Comment notification: error screen instead of the thread | the dialog started the sheet's wait in `initState`, reading MediaQuery | started once in `didChangeDependencies`; test that fails without the fix |

## B3. Profiles

### Profile tab redesign: ON
- **What**: under the header, the user's "about me" line (or "Add a few words about you", which opens its editor);
  a capsules card with three numbers (capsules, places about 5 km apart, made with friends; a tap opens My
  capsules) and two green buttons "+ For friends" / "+ For everyone" that open the camera with that visibility;
  Add friends; the friends card; achievements. The two odd rows "To the map | For friends / For everyone" are gone.
- **Tests**: `profile_tab_test.dart` (the counts, about me).
- **Phone** (Russian, light): the tab, the numbers with Russian plurals ("102 капсулы", "69 мест"), the buttons.

### Pinned and recent friends with quick actions: ON (F-56)
- **What**: the friends card shows "Friends · 60", a pin button (choose pinned) and "All". Five friends with first
  names: the pinned ones (green pin mark) first, then the people the user chatted with lately, then the rest in a
  stable order (the random fill is gone). A tap opens quick actions: Message, Send a capsule, Profile, Pin/Unpin;
  a long press pins or unpins with a toast. At most three pins.
- **How**: pins moved from one phone (SharedPreferences) to the settings document (`pinnedFriends`), so they follow
  the account; pins kept on a phone move over once. Recent friends come from the two-person chats already loaded.
- **Tests**: `friends_test.dart` (order, former friends dropped, the limit, the one-time move).
- **Phone**: quick actions for Bob, "Закрепить", a long press pinned Hugo ("Hugo Garcia: закреплено"), pin marks.

### About me: ON (F-59, F-85)
- **What**: Settings > Customize profile > About me (100 characters, a counter), also reached from the profile;
  shown under the header on the user's own profile and on friends' and strangers' profiles.
- **How**: `users/{uid}.about` (rules: a string of at most 100 characters; empty deletes it).
- **Tests**: `profile_tab_test.dart`, rules ("a few words about yourself").
- **Phone**: written on the phone ("Collecting sunsets in Warsaw"), shown on the profile. The Save button first
  sat under the keyboard (a bottom bar); it now follows the field. The name page has the same bottom bar
  (IDEAS_NOT_DONE.md).

### People search by name, from the chat search too: ON (F-57)
- **What**: Add friends searches names as well as @usernames ("Name or @username"); usernames first, never the
  user or someone they blocked. The Messages search adds "Find people: «anna»" under the chats it found (or instead
  of "nothing found"), which opens Add friends with that text.
- **How**: a lower-case copy of the name (`users/{uid}.nameLower`), kept by the app (`SearchNameSync`): written
  when missing or stale, removed when Settings > Privacy > "Find me by name" is off (on by default; the username
  always finds the user). The rules accept it only equal to the name in lower case; older apps rename without it
  (the search then lags until the new app runs). Prefix search on the whole name ("anna f…", not "fischer").
- **Tests**: `friends_test.dart` (by name and username, never yourself), `profile_tab_test.dart` (the sync writes
  once, follows the switch, never indexes the loading placeholder), rules.
- **Phone**: the sync wrote "alice walker" for the signed-in account; Messages search "anna" → "Найти людей:
  «anna»" → Add friends found "Anna Rossi" by name. The seed now writes `nameLower` (the rig's people were
  written by the seed, not by the app).
- **Not done**: search by the last name alone (needs a word index); existing accounts are found by name only after
  they open the new version (or after the owner backfills, BACKEND_CHANGES.md §7).

### Report and block strangers: ON
- See B2 "Report everywhere": a stranger's profile now has Report and Block.

### Settings gaps
| Gap | State | How | Checked |
|---|---|---|---|
| Sign-in methods | ON | Account shows "Email and password · Google" from Auth | phone ("Email and password") |
| Distance unit | ON | Map and camera > Distances: kilometres or miles; My capsules says "3.4 mi from you" | test; phone ("6.8 mi from you") |
| Photo quality | ON | Map and camera > Photos: Standard (1600 px, JPEG 85) or High (2560 px, JPEG 90, within the 10 MB rule); kept for waiting capsules. The camera opens at 1080p for High (720p before, so High alone changed nothing) | test; phone (upload 720×1280 at Standard, 1080×1920 at High) |
| Save to gallery | ON (Android 10+) | Map and camera > Photos: capsule photos also go to Pictures/Later once the capsule is made or kept for later, through the app's own channel (no permission on Android 10+; older phones answer no); hidden on iOS | test (mocked channel); phone (Pictures/Later/Later_<id>.jpg after two capsules) |
| Download my data | ON | Data and storage: profile, settings, capsules (photos as links), friends, blocks and chats (last message) as one JSON file in the share sheet | test; phone (share sheet with later-data-2026-10-17.json: 104 capsules, 60 friends, 23 chats) |
| Find me by name | ON | Privacy (see the search above) | test, rules |
| Mobile data for uploads | moved to B4 | belongs with the background uploads | |
| Who can message me | not needed | chats are between friends only | |
| Last seen | not built | the app keeps no presence | |

### Friend suggestions from contacts: FLAGGED (`FeatureFlags.contactSuggestions = false`)
- **What**: Add friends > "From your contacts" explains what is sent and kept, then shows the people found (with the
  usual add and hide buttons). Privacy > "Found by people with my email" lets others find the user this way.
- **How**: matching by email, not phone number (accounts have no numbers and nothing could verify one). The phone
  reads only its contacts' email addresses and hashes them in native code (`ContactsChannel.kt`: SHA-256 of a
  versioned salt and the lower-case address), so no contact reaches Dart or the server. One request an hour
  (`contactMatches/{uid}`, rules), at most 1000 hashes; the function answers with people who still allow it, never
  the user, no blocks either way, and drops the hashes. The index (`contactIndex/{hash}`) holds only the verified
  email of each user who opted in, written by a function from Auth.
- **Tests**: functions (`contacts.test.js`: hash, index on/off, unverified emails refused, matching with blocks and
  former opt-ins), rules (index closed, one request an hour, own only), `contact_suggestions_test.dart`.
- **Phone** (flag switched on locally, not committed): the button and the explanation sheet; "Look for friends"
  answered "Later needs access to your contacts for this" (the manifest has no `READ_CONTACTS`). The look-up itself
  was not run: this phone's address book is the owner's own (BLOCKERS.md).
- **To switch on**: add `READ_CONTACTS` to the Android manifest (and the Play data safety form), run the look-up
  on a test phone, deploy the rules and the two functions (BACKEND_CHANGES.md §7), then set the flag. iOS needs a
  native reader (only the Android one exists).

## B4. Creation

### Loop capsules: ON (flag switched on after the phone check)
- **What**: a Photo | Loop switch above the shutter (Loop: a tap starts, a second tap ends; Photo: a long press
  still records one). Creation shows the frames in a strip (hold and drag to reorder, a cross takes one out, two
  stay at least) and a Speed row (slow 500, normal 300, fast 150 ms per frame); the preview plays at that speed.
  Loops carry a loop mark on their picture in My capsules and on the map card; they play in the capsule and full
  screen as before.
- **How**: frames upload as before (≤ 10, 1080 px). The emulator's http download links are now accepted for frames
  in emulator builds (only https was, so loops never showed on the rig).
- **Tests**: `capsule_creation_test.dart` (remove, move, speed, two at least), `achievements_test.dart` (the
  Animator follows the flag), `loop_picture_test.dart`.
- **Phone**: a loop recorded by taps (4 frames), one removed, speed set to fast, sent: 3 frames, 150 ms and a
  thumbnail in Firestore; the loop mark in the list and on the map card; a loop of three different seed photos
  changed frames in the capsule (screenshots 1.6 s apart). Not judged: motion from the real camera (it saw only
  black at the time).
- **Not done**: loops in chat bubbles (the chat message carries only the picture).

### Thumbnails: ON
- Every capsule uploads a 400 px `thumb.jpg` next to its photo (storage rule added; refused by older rules, the
  capsule is then saved without one). Lists, the map card and chat bubbles use it. **Phone**: `thumbUrl` set on new
  capsules; **Tests**: storage rules.

### Drafts (autosave): ON
- **What**: a capsule being made is kept as left: its photo or frames are copied into the documents folder and what
  was typed and chosen is saved a second after each change and when the page closes. The camera then shows
  "Unfinished capsule: Continue / ×"; made or kept for later, the draft goes.
- **Tests**: `capsule_creation_test.dart` (left, taken up again with title, colour and pin, gone once made).
- **Phone**: a title typed, the page closed; the camera offered "Draft test · Продолжить"; continued, the pin moved
  (the draft JSON on the phone had the pin), saved: the capsule at the pin, the draft folder gone.

### Own calendar: ON (F-27)
- "Pick a date…" opens the app's calendar: a month at a time (arrows or a swipe), the language's first weekday,
  days before tomorrow greyed, today ringed; a tap chooses. **Tests**: `open_date_calendar_test.dart` (choice, greyed
  days, Russian week). **Phone**: Russian (weeks from Monday), November 4 chosen.

### Pin on a map: ON
- A tap on the place opens a map under a fixed pin; dragging the map moves the capsule's spot, at most 1 km from
  the phone (the places a user has been count for the Explorer achievement); "Back to where I am". **Tests**: the
  1 km limit and the pin reaching the draft. **Phone**: the sheet, a drag, "Поставить здесь", the capsule saved at
  the pin.

### Steps, composer, hero: ON
- The settings title and cards come in one after another; the description opens a composer sheet (large field,
  2000 counter) instead of the narrow column; the camera's frozen photo is a hero into the capsule card.
- **Phone**: the cards caught mid-entrance; the composer with "23/2000" and the text live behind it; the photo in
  the card after the shutter. The hero flight itself is too quick for screenshots (not seen).

### Uploads: friends, backoff, Wi-Fi only, in the background: ON
- **What**: a capsule for a friend made offline waits too and goes to the chat after its upload. Waits grow: 30 s,
  doubling to 15 min, back to the start when the app returns. Map and camera > "Upload on Wi-Fi only" ("Waiting for
  Wi-Fi" in My capsules). In the background (and with the app closed) Android's WorkManager runs the outbox in an
  engine of its own with its own backoff; leaving the app hands the uploads over, returning takes them back.
- **Tests**: `capsule_outbox_test.dart` (friend's capsule kept across a restart and posted, the waits and the cap,
  Wi-Fi only, the hand-over).
- **Phone**: emulator ports blocked, a capsule queued, the app sent to the background: the job tried (1 still
  waiting), the ports came back, a minute later the job uploaded it ("0 still waiting"). The first try, before the
  hand-over existed, showed the app and the job racing (the job's create was refused): that race is gone. Not seen:
  the job with the app process killed (Android keeps WorkManager jobs across process death by design; `am kill`
  could not kill the app while the job ran).
