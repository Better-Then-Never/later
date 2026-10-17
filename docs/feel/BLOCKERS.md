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
  - [ ] announcements arrive on the topic of the account's language.
- Builds that use the emulators skip FCM topic subscriptions (`PushMessagingService`), so topic pushes are not
  testable with the emulator rig at all.

## Part B, not finished (details in FEATURES_B.md)
- **Groups**: no photos or capsules yet (Storage rules would need cross-service rules to read a group's members);
  messages from someone you blocked still show in a group you share; no admin roles (any member renames and adds
  their friends); no group picture.
- **Photos offline**: a photo waits only while the app runs ("Not sent · Tap to retry" after 45 s offline); text
  messages queue across restarts.
- **Production IAM**: the functions' service account has *Storage Object Viewer* only, so it cannot delete files:
  `deleteChatPhoto` and **the existing account deletion's file cleanup** fail in production until the grant in
  BACKEND_CHANGES.md §2 is made.

## Owner decisions
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
