# RIG.md: how the phone is measured and iterated on

Everything runs against the **local Firebase Emulator Suite** on this computer; the phone reaches it over USB.
No production project, data or push is involved.

## 1. Emulators and data
```bash
tool/dev/emulators.sh        # Auth 9099, Firestore 8080, Storage 9199, Functions 5001 (+ UI 4000)
node tool/seed_heavy.js      # once it is up (about 20 s); replaces everything in the emulators
```
- `emulators.sh` maps the four ports on the phone with `adb reverse`, so the app reaches them at
  `127.0.0.1`. Builds for the phone use `--dart-define=USE_FIREBASE_EMULATOR=true
  --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1` (the Android emulator default `10.0.2.2` does not work on a
  phone).
- **Functions run in the emulator too**, so counters, notifications, achievements and the chat summary behave as in
  production. Two guards make that safe:
  - In the Functions emulator, pushes are **logged instead of sent** (`functions/index.js`, `loggedMessaging`). FCM
    has no emulator, and a real send would go out with this computer's credentials.
  - Builds that use the emulators **do not subscribe to FCM topics** (`PushMessagingService.subscribeToTopic`),
    because topics would be the real project's. The app still gets an FCM token from the real project (that
    cannot be emulated); nothing is sent to it.
- `seed_heavy.js` refuses to run unless every emulator host is local. It **pauses the Functions triggers while
  seeding** (Emulator Hub `disableBackgroundTriggers`), so the data is exactly what it says:
  - 104 people. alice@later.test is the main account (password `TEST_ACCOUNT_PASSWORD` or the emulator-only
    default); she has **60 friends**, 6 incoming and 1 outgoing request, 30 followers, and follows 20.
  - **2,002 capsules**: 1,500 within about 25 km of `SEED_CENTER` (default Warsaw 52.2297, 21.0122), 500 in 40
    other cities. 102 are Alice's (including two "on this day"); about 30 % carry reactions and comments. One busy
    capsule has 50 reactions and 30 comments with replies.
  - A **600-message chat** Alice ↔ Bob over 30 days: every tenth message is a capsule photo, every seventh is a
    reply with a quote, some have reactions. There are 20 shorter chats as well.
  - **40 notifications** of every kind; stats, streak and achievements on Alice's profile.
  - Photos are 8 shared 1200×1600 images, so Storage stays small; avatars are small per-user gradients (Frank and
    every seventh person have none, so placeholders show too).

## 2. The app on the phone, fast loop
```bash
tool/dev/run.sh              # debug + hot reload; returns when the app is up (log: build/dev/run.log)
tool/dev/ctl.sh r            # hot reload (R: restart, q: quit); prints flutter's answer
tool/dev/screen.sh [--log]   # what is on screen, as text: labels with bounds (uiautomator), app log
tool/dev/shot.sh name        # one screenshot downscaled to 540 px: build/dev/shots/name.png
tool/dev/run.sh --profile    # profile build for feel checks by hand (no hot reload)
```
- The Dart MCP server is not available in this environment, so `run.sh` keeps `flutter run` reading key commands
  from a control file (`build/dev/control`); `ctl.sh` appends to it.
- Order of looking: text first (`screen.sh`, logcat, widget tests); a screenshot only for looks, at most one per
  change; contact sheets (`tool/contact_sheet.dart`) for many screens.
- Sizes, text scales (1.0, 1.3, 2.0) and the five languages are covered by widget and golden tests, not by
  screenshots.

## 3. Numbers
```bash
tool/dev/perf.sh <label> [runs]                 # profile build, every flow, N runs (default 3)
FLOWS=chat_open,chat_scroll tool/dev/perf.sh chat 3   # only these flows (startup always runs)
dart run tool/dev/perf_summary.dart build/perf/<label>
```
- `integration_test/perf_test.dart` drives the flows with `traceAction` (`flutter drive --profile --no-dds`;
  without `--no-dds` the test cannot reach the VM service on a physical phone). Labels come from the app's
  translations, so the phone's language does not matter.
- **Janky frame** = build **or** raster over **8.33 ms** (120 Hz). `perf_summary.dart` computes it from the
  per-frame arrays, because flutter_driver's own "missed budget" counts assume 16.7 ms.
- **Timed moments**: `PerfMarks` (`lib/core/logging/perf_marks.dart`) put named instants in the timeline (shutter
  feedback frame, picture file written, first frame of creation, first frame of a chat with messages). The driver
  reports each as milliseconds after the test's `later.tap` (`perf_numbers.json`).
- **Android's view**: each run also saves `dumpsys gfxinfo <app> framestats` and SurfaceFlinger TimeStats.
  gfxinfo counts only frames Android's own renderer (HWUI) draws; Flutter draws into a SurfaceView with its own
  engine, so gfxinfo sees only a handful of frames per run (see the validation below). TimeStats measures the
  app's layers at the compositor and is reported as the cross-check.
- Cold start: `tool/dev/coldstart.sh` (`am start -W`, 5 launches of the profile app, force-stopped between).
- Fair state before runs: DEVICE.md. `perf.sh` grants camera, location and notification permissions so no system
  dialog interrupts a flow, force-stops the app between runs and rests 20 s.

## 4. Not available here
- **ffmpeg** is not installed, so screenrecord videos cannot be cut into stills on this machine. Stills for
  `docs/feel/after/` come from `screencap` at chosen moments instead (see BLOCKERS.md).
- **Dart MCP server**: not available; replaced by the control-file loop above.

## 5. Gotchas met on this rig (Windows)
- **Rules tests next to the dev emulators**: the Functions emulator's workers listen on dynamic ports and can hold
  the rules tests' ports (8180, 9299). The rules tests then fail to start, and stopping "whatever holds 9299" took the
  dev emulators down mid-measurement. Run the rules tests with the dev emulators stopped (or before starting them).
- **Stopping a `flutter drive` run by force** can leave the adb server hung (`adb devices` never returns; dozens of
  adb processes). Kill every `adb.exe` and `adb start-server` again.
- **Re-seeding** (`node tool/seed_heavy.js`) makes new accounts with new ids: the app on the phone is signed out on
  its next start, and the perf test signs in again. **Clear the app's data after a re-seed**
  (`adb shell pm clear com.btn.later`): the phone's Firestore cache still holds the old seed's capsules, and the SDK
  checks one by one each cached document that a query no longer returns ("limbo" documents). For 1–2 minutes after
  the start the map then re-sorted its capsules ~3 times a second and the first chat open waited over 10 s. Seen in
  the final run (run 1, first chat open) and reproduced; with the data cleared the same open took 176 ms. A real
  backend never deletes thousands of documents at once, so this is the rig, not the app.
- **Background emulators**: stopping the shell that started them leaves `node` (the Firebase CLI) and the Firestore
  `java` running; stop those two processes before starting again.
- **Functions tests** (`npm run test:emulate`) leave their Firestore `java` on port 8280 after finishing; the next
  run then fails with "port taken". Stop it after each run (as the rules tests do with 8180).
- The app keeps its language and theme on the phone between runs; the perf test sets a `PERF_LANG` back when it ends.
