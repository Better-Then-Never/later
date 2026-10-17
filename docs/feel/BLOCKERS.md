# BLOCKERS.md: what is not finished, not verified, or needs the owner

Anything listed here was **not** checked on the device, or could not be done in this environment.

## Environment
- **ffmpeg is not installed.** Screen recordings cannot be cut into stills here; stills come from `screencap` at
  chosen moments instead. Installing ffmpeg was not done (no unvetted installs).
- **Dart MCP server is not available.** Hot reload runs through a control file (`tool/dev/run.sh`, `ctl.sh`).
- **No CI on PR #79**: `pr-build.yml` runs only for PRs into `main`. All gates run locally (FEEL_QA.md).

## Push delivery (cannot be verified without a dev Firebase project)
- FCM has no emulator. In the Functions emulator, pushes are logged instead of sent (`functions/index.js`), so the
  server side is covered by the functions tests and the emulator log, never by a real push. On-device push checks
  still to do with a dev project:
  - [ ] a new message, a reaction, a comment, a friend request and an achievement each arrive as a push, in the
    phone's language, and open the right screen when tapped;
  - [ ] quiet hours and per-category switches hold back the right pushes;
  - [ ] announcements arrive on the topic of the account's language;
  - [ ] with Settings > Notifications > Vibration off, pushes arrive on the `*_novibrate` channels and do not
    vibrate; with Sound off they are silent.
- Builds that use the emulators skip FCM topic subscriptions (`PushMessagingService`), so topic pushes are not
  testable with the emulator rig at all.

## Part B, not finished (details in FEATURES_B.md)
- **Groups**: no photos or capsules yet (Storage rules would need cross-service rules to read a group's members);
  messages from someone you blocked still show in a group you share; no admin roles (any member renames and adds
  their friends); no group picture.
- **Voice messages on iOS**: no recorder is written for iOS (it would be an AVAudioRecorder channel like
  `VoiceChannel.kt`, and there is no iOS device or Mac here to build and check it), so the button is hidden on iOS.
  Voice and photos are not offered in groups either (Storage cannot check group members yet).
- **Photos offline**: a photo waits only while the app runs ("Not sent · Tap to retry" after 45 s offline); text
  messages queue across restarts.
- **Production IAM**: the functions' service account has *Storage Object Viewer* only, so it cannot delete files:
  `deleteChatFile` and **the existing account deletion's file cleanup** fail in production until the grant in
  BACKEND_CHANGES.md §2 is made.

- **Contacts suggestions (flagged off)**: the look-up was never run on a phone: the reference phone's address book
  is the owner's own, and the manifest has no `READ_CONTACTS` yet (a declared-but-unused contacts permission is a
  store-review and privacy question). Before the flag goes on: add the permission, run it on a test phone, deploy
  the two functions (BACKEND_CHANGES.md §7). iOS has no native reader yet. Matching is by verified email; matching
  by phone number would need phone verification (an owner decision).
- **App icon badge (B6)**: not built. Android shows its own mark from the notifications in the tray (not checked on
  the phone). An unread count on the icon needs a third-party package (flutter_app_badger is no longer maintained;
  no other was vetted) or a count query on the server per push. Owner to decide.
- **Not seen on the phone (B4)**: the camera photo's hero flight into the creation card (too quick for screenshots;
  the photo is in the card afterwards); the background upload job with the app's process killed (Android keeps
  WorkManager jobs across process death by design; `am kill` could not kill the app while the job ran); a loop's
  motion from the real camera (the camera saw only black during that check; seed frames played).
- **Passport (B7)**: capsules made before this version have no country, so they are not in it (the page says so). A
  backfill would need a paid geocoding API on the server or a pass over each phone's own capsules (IDEAS). Offline
  capsules upload without a place. iOS shows country codes instead of names (no native reader written, no Mac here).
- **Not seen on the phone (B7)**: the burst of dots and the flame's swell (too quick for screenshots); the moment
  cards with TalkBack (they are a live region; test only).
- **Weekly limit vs daily streak (B7)**: a product decision (FEATURES_B.md, B7). Nothing is limited today.
- **Name search** finds prefixes of the whole name only ("anna f", not "fischer"); existing accounts are found by name
  after they open the new version or after the optional backfill (BACKEND_CHANGES.md §7).

## Owner decisions
- **Illustrated sticker packs** need artwork (a designer or licensed packs). Big emoji work as stickers for now.
- **Russian text uses the phone's font.** Inria Sans (the app font) has no Cyrillic, so every Russian string falls
  back to the system font: the typefaces mix, and the first frame of a page costs ~5 ms more in Russian than in
  English (settings: worst frame 18.4 ms in Russian, 13.3 ms in English; PERFORMANCE.md). "No new fonts" is the rule
  of this session, so nothing was changed; a Cyrillic-capable cut of the same family (or a matching font) would fix
  both. Owner to decide.
- **Light map style** (D-22): the local JSON follows the cloud style's idea; compare it with the cloud style before
  release.
- **Settings rows are 44 dp** (were 36) to meet the tap-target minimum (D-24); rows with a subtitle are unchanged.
- **Share icon** (F-43): the profile's share button showed a paper plane, the same picture as "send". It is now the
  usual share sign (three linked nodes) in the profile icons' ring and stroke weight, drawn by
  `tool/make_share_icon.dart`; the same drawing is in `docs/feel/icons/share.svg` for review or a designer's
  redraw. Not rendered from SVG in the app: that would need a new package (flutter_svg), which this session does not
  add.
