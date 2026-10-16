# PROGRESS.md — running log (resume from here)

Branch: `feature/polish-motion-messages-settings` (from main 5b30770). Plan: POLISH_PLAN.md.

## How to run things (emulator only)
- Firebase emulators: `firebase emulators:start --project later-da778 --only auth,firestore,storage`
  (needs `JAVA_HOME=C:\Program Files\Android\Android Studio\jbr`). If a port is taken, an orphaned
  `cloud-firestore-emulator` java process is still alive: stop it first.
- Seed: `cd tools/emulator && npm run seed` (accounts alice/bob/carol/dave/erin/frank @later.test, password
  `TEST_ACCOUNT_PASSWORD` or the emulator-only default in seed.js).
- App: `flutter run -d emulator-5554 --dart-define=USE_FIREBASE_EMULATOR=true`.
- Rules tests: `cd tools/rules-tests && npm run emulate`. Functions tests: `cd functions && npm test` (emulators).

## Log
- **Phase 1 (orientation)**: baseline gates clean (format, analyze 0, 108 tests). Plan written.
