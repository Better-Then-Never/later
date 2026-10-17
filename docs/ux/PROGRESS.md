# PROGRESS.md: overnight UX and features mission (resume from here)

Branch: `feature/ux-features-night-session`, based on `feature/polish-motion-messages-settings` (PR #77, not yet
merged into `main` when this branch was created; its CI fix is merged in). Mission text: the owner's prompt
"Mission (Overnight, Unattended): UX, Design Consistency, Animations and Features for Later".

## Rules in force (short)
- Never `firebase deploy`, never touch production data, never print or commit secrets. Emulators only
  (`firebase emulators:start --project later-da778 --only auth,firestore,storage`; functions tests use
  `demo-*` projects).
- No releases, no tags, no version bumps. Never commit to `main`, never force-push.
- Style is law: extend the existing language (DESIGN_SPEC, DESIGN_DECISIONS), never replace it.
- Feel beats feature count. Every claim needs evidence (test, screenshot, recording, timing).
- Do not build: ads, capsule music, publics/channels, video circles, web version, payments.
- Merge policy: `release.yml` publishes a release on every push to `main`, so **this PR must stay open**
  (Section 14 condition "no automation that releases on merge" fails). Say so at the top of the report.

## How to run things
- Emulators + seed: see docs/polish/PROGRESS.md (alice@later.test etc., password `emulator-only-123` unless
  `TEST_ACCOUNT_PASSWORD` is set).
- App: `flutter run -d emulator-5554 --dart-define=USE_FIREBASE_EMULATOR=true`.
- Gates: `dart format --output=none --set-exit-if-changed lib test tool`, `flutter analyze`,
  `flutter test` (goldens are Windows-only: CI uses `--exclude-tags golden`), `dart run tool/check_design_tokens.dart`,
  `cd tools/rules-tests && npm run emulate`, `cd functions && npm run test:emulate`.

## Log
- Branch created; PR #77 CI fix (goldens only on Windows) pushed to the polish branch and merged here.
- **Phase 1 done:** STYLE_BIBLE, AUDIT (all F-xx mapped), PLAN, PERFORMANCE baseline (profile mode, emulator;
  raster unusable on this emulator, build times are the budget), baseline = docs/polish/after.
- **Foundation done (Tier 0 infra):** l10n fragments + gen-l10n, AppPalette (light identical; 3 dark candidates),
  dark icons via ThemedAssetBundle, appearance controller (theme/language/UI size, loaded before first frame),
  UiScaleView, edge-to-edge transparent bars, splash = first frame; shared/core/app layers on the palette.
- **Conversion done:** all 8 areas merged (messages, friends+users, settings, auth, profile,
  history+notifications, capsules+map); data-layer strings localized; theme-dependent members removed from
  AppColors (only theme-invariant colours remain). Worktrees removed (branches kept).
- **Backend done (not deployed):** localized pushes, reactions, comments, follower counts, friend request
  notifications, stats/streaks/places/distance, achievements registry + unlocks, streak reminders, admin
  announcements, reports, rules for all of it, account cleanup. Functions 43/43, rules 53/53. Admin scripts in
  tools/admin (self-test passes), ADMIN.md.
- **Client data layer done:** settings (new categories, privacy, language synced for pushes), profile counters,
  verified, stats + streakAt, capsule fields (capturedAt, loop frames, counters...), SocialRepository
  (reactions, comments, reports, achievements, announcements) + fakes. Writes fall back once to the older shape
  when rules predate the new fields (`legacyCapsule`, notification keys).
- **Settings done:** Appearance (theme, size), Language, Privacy (default visibility, approximate location,
  read receipts honoured both ways, show achievements), notification categories. FeatureFlags
  (lib/core/config/feature_flags.dart): reactions, comments, achievements, streaks, news are **false** until
  their UI ships; flip each when done and verified.
- **Notifications:** new types (reaction, friendRequest, friendAccepted, achievement) with names looked up by id,
  localized sentences, tap routing; Android channel names localized.
- **Draft PR #78** opened (base main, includes #77's commits since #77 is not merged). Keep its body updated.
- Next: emulator checks (dark candidates D-03, all screens in dark + ru/de), then Tier 0 images (F-01..F-03),
  consistency (F-30..F-45), motion; then Tier 1/2 features (default visibility + approximate location in
  creation, reactions/comments UI, achievements UI, news topic subscription).
