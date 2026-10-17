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
