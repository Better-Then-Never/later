# PROGRESS.md — running log (resume from here)

## How to resume
- Branch `refactor/architecture-and-stabilization`. Plan: `REFACTOR_PLAN.md` §3. Bugs: `BUGS.md`.
- Emulators: `cd <scratch>/emu_baseline` style config is only for the *baseline*; the repo `firebase.json` has an `emulators` block. Start with `JAVA_HOME="C:/Program Files/Android/Android Studio/jbr" firebase emulators:start --project later-da778 --only auth,firestore,storage` (use `demo-*` for functions), seed with `cd tools/emulator && node seed.js`, run the app with `flutter run --dart-define=USE_FIREBASE_EMULATOR=true`.
- Seeded accounts: alice/bob/carol/dave/erin/frank `@later.test`, password = `TEST_ACCOUNT_PASSWORD` or the emulator-only default in `tools/emulator/seed.js`.
- Android emulator `Medium_Phone` (16 GB data partition), GPS fix `adb emu geo fix -122.084 37.4219983`.

## Log
- **2026-10-16 — Phase 0/1/2.** Branch created; committed build fixes (Kotlin 2.3.10, compilerOptions, incremental off), gitignore of Firebase config, deprecated API replacements, emulator support + seed tooling. Read the whole repo (notes in `audit/`). Baseline gates recorded in AUDIT.md §5. 55 baseline screenshots captured against the emulators (`screenshots/before/`). Wrote AUDIT, FIREBASE_AUDIT, BUGS, DESIGN_SPEC, SECURITY_FINDINGS, BLOCKERS, IDEAS_NOT_DONE, REFACTOR_PLAN.
- Next: plan step 1 (tooling).

## Final-report checklist (verify before writing REPORT.md)
- SECURITY_FINDINGS.md and BLOCKERS.md describe some fixes in the present tense ("moved", "fixed in code"): confirm each one actually landed, or reword.
