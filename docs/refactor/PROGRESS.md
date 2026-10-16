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
- **Step 7 (map)** done in b7a6ac2 (see commit). Maps key moved to local.properties / Secrets.xcconfig.
- **Step 8 (camera + capsule creation)** done in 560afff: camera lifecycle/flash/error state/capture guard; CapsuleCreationController (re-entrancy, location fallback, clean errors, temp photo cleanup). Verified: double tap -> 1 capsule, upload image/jpeg 99 KB (was octet-stream 151 KB).
- **Step 9 (history)** done in 59daac4: OwnCapsulesStore, FavoritesStore, HistoryController, null-safe tile; legacy CapsuleDataService/FavoriteCapsuleService/HistoryPageController removed. Verified: newest first, favourite persisted, delete removes doc + Storage image.
- **Step 10 (profile, friends, share, settings)** done in 2e33d45 (friends: FriendsStore, UserDirectory, FriendActions, bounded search, pinned friends), 18a8c1f (profile images: ProfileImageEditor, one options sheet, header offsets), 7e51a90 (settings: username transaction, mounted checks, permissions resume, share from session). All legacy services are gone except PopupNotificationService and SharingService (stateless helpers). BUG-071 privacy part (email/fcmToken readable in users docs) and BUG-076 (cross-user friends write) still need the rules + migration of step 13.
- Emulator data was changed by manual checks (alice is @alice.w, bob unfriended, alice background deleted, alice profile picture set, dave is a friend): re-run `tools/emulator/seed.js` on a fresh emulator before the "after" screenshots.
- **Step 12 (cleanup)** done: fb6fc31 (0 analyzer issues, page_transition + location removed, dead files), 0f55a5e (views/services/controllers moved into app/shell, features, shared; lib/ = app, core, data, features, shared), f4cd9ef (AppColors tokens for identical literals), a5108bc (isScheduled). Shared modal option rows were not merged: their splash behaviour differs slightly (kept as is).
- Next: step 13 (Firebase backend: rules + rules tests, indexes, functions fixes + tests, firebase.json, MIGRATIONS_NEEDED.md).

## Final-report checklist (verify before writing REPORT.md)
- SECURITY_FINDINGS.md and BLOCKERS.md describe some fixes in the present tense ("moved", "fixed in code"): confirm each one actually landed, or reword.
- verify watchPublicInBand latitude-band query against the Firestore emulator (tools/rules-tests)
