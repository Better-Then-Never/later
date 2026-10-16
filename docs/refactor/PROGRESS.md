# PROGRESS.md — running log (resume from here)

## How to resume
- Branch `refactor/architecture-and-stabilization`. Plan: `REFACTOR_PLAN.md` §3. Bugs: `BUGS.md`.
- Emulators: `cd <scratch>/emu_baseline` style config is only for the *baseline*; the repo `firebase.json` has an `emulators` block. Start with `JAVA_HOME="C:/Program Files/Android/Android Studio/jbr" firebase emulators:start --project later-da778 --only auth,firestore,storage` (use `demo-*` for functions), seed with `cd tools/emulator && node seed.js`, run the app with `flutter run --dart-define=USE_FIREBASE_EMULATOR=true`.
- Seeded accounts: alice/bob/carol/dave/erin/frank `@later.test`, password = `TEST_ACCOUNT_PASSWORD` or the emulator-only default in `tools/emulator/seed.js`.
- Android emulator `Medium_Phone` (16 GB data partition), GPS fix `adb emu geo fix -122.084 37.4219983`.

## Log
- **2026-10-16 — Phase 0/1/2.** Branch created; committed build fixes (Kotlin 2.3.10, compilerOptions, incremental off), gitignore of Firebase config, deprecated API replacements, emulator support + seed tooling. Read the whole repo (notes in `audit/`). Baseline gates recorded in AUDIT.md §5. 55 baseline screenshots captured against the emulators (`screenshots/before/`). Wrote AUDIT, FIREBASE_AUDIT, BUGS, DESIGN_SPEC, SECURITY_FINDINGS, BLOCKERS, IDEAS_NOT_DONE, REFACTOR_PLAN.
- **Step 1 (tooling)** done: lints active (442 → 85 after dart fix; remaining are print/context/unawaited, fixed per feature), unused deps removed, dead files deleted, lockfile tracked.
- **Steps 2-3 (core + assets)** done: tokens/theme/logger/failures/route transitions; assets reorganised with typed accessors + test.
- **Step 4 (data layer)** done: models with tolerant mappers, repository interfaces + Firebase impls (auth, users+username reservation, friends, capsules, notifications, push tokens, image storage), services (image processing in isolates, geolocator location, cached geocoding, uid-scoped prefs). 27 unit tests (fake_cloud_firestore). Not wired to the UI yet.
- **Step 5 (app shell) + step 11 (auth)** done in 7518612: bootstrap, AppScope, SessionController + SessionScoped, AuthGate, AppRoutes, AppLinkHandler (+ Kotlin cold-start fix), auth feature with AuthController. Verified on emulator: logout -> login page, clean error text, cold-start deep link opens profile after home is ready.
- **Step 6 (notifications)** done in 7fd29c8: PushMessagingService, NotificationsStore, PushRegistration, NotificationRouter, ProfileImageCache, MapFocus (consumed by the new map in step 7), Android icon/manifest, iOS plist/entitlements. Verified: list after login, token doc, follow tap.
- IMPORTANT for step 13: functions must read users/{uid}/fcmTokens (+ legacy fcmToken); deploy functions before releasing the app.
- Next: step 7 (map).

## Final-report checklist (verify before writing REPORT.md)
- SECURITY_FINDINGS.md and BLOCKERS.md describe some fixes in the present tense ("moved", "fixed in code"): confirm each one actually landed, or reword.
- verify watchPublicInBand latitude-band query against the Firestore emulator (tools/rules-tests)
