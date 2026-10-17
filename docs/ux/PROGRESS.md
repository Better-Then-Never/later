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
- **Emulator session (dark, ru):** D-03 charcoal chosen (sheet in docs/ux/dark_candidates), dark map style
  without map ID (D-07), map padding (logo above the bar), Russian labels shortened after on-device check.
- **Images done (F-01..F-03):** cached_network_image disk cache, decode buckets, skeleton while avatar lookups
  run, avatar URLs remembered per account, chats reopen from their last messages. Verified after cold restart.
- **Fixes:** F-57 suggestions = friends of friends (no strangers), F-30 round list avatars, F-42 three optional
  permission steps (mic/contacts removed incl. manifest), F-18 invalid places, F-25 description 2000, privacy
  defaults applied in creation (+ capturedAt/utcOffset), F-13 my-location button (dark user figure), F-17 own
  capsule card (closes on tap/swipe/back/tab/zoom-out; logo never covered; package removed).
- **Done since:** F-10 memoized markers (perf mid-run in docs/ux/perf/mid), reactions + comments + reports
  (capsule detail dialog; flags on), per-capsule switches in creation, camera permission fix, pinned creation
  header, news topics (flag on), achievements + streak on profiles (flags on; loop capsules flag off), verified
  badge + follower counts, nav tab labels, admin count backfill (self-test), all docs (REPORT, MORNING_SUMMARY,
  DEPLOY, MIGRATIONS_NEEDED, COST_NOTES, PRIVACY, ACHIEVEMENTS, FEATURES, COMPONENTS, BLOCKERS, IDEAS_NOT_DONE,
  TEST_REPORT, FEEL_QA). Functions 43/43, rules 53/53, flutter 224.
- Dev Firebase emulators were stopped to run the functions/rules suites; restart with the command above and
  re-seed (tools/emulator: npm run seed) before more on-device checks.
- Next candidates (IDEAS_NOT_DONE.md): friend's capsules list (F-54), history controls (F-31), one sheet system
  (F-32), requests toggle (F-41), share icon (F-43), Add Friends transition (F-38), camera controls, loop capsules.
- **Offline capsules (F-26), done:** per-account outbox (photo + draft JSON in the documents folder), pending
  capsules in My Capsules with an orange "Waiting for connection" pill and the local photo, uploads at sign-in,
  on resume and every minute with the id fixed when queued (repository `create` is idempotent), refusals capped at
  3 per sign-in (each attempt re-uploads the photo). Creation asks for the location permission itself (found on
  the device: skipped onboarding left "No location"). Verified on the emulator: airplane mode → saved instantly as
  pending → network back → uploaded on the next retry (the first one hit the emulator's after-reconnect denial,
  BLOCKERS.md). Unused strings `achievementsProgress`, `commonClose`, `commonDone` removed. Flutter 231.
- **One sheet system (F-32/F-37), done:** `app_sheets.dart` (centred cards + edge sheets), every launcher moved
  onto it; grab handles on new chat and the pinned-friends picker; history Sort/Filter rebuilt on the menu card
  (current choice in green, animated levels); permission dialogs → confirmation card with a message; password
  reset rises above the keyboard; pinned-friend menu on `OptionsMenu`. Verified on the emulator (screens in the
  session, not kept). Found on the way: two friend-menu entries that did nothing (removed), silent icon buttons
  (labelled), empty place pills after a system restart (fallback text). Flutter 235.
- **Chat message actions, done:** hold a message → menu card (Copy; Delete for own messages after a
  confirmation). Optimistic removal, restored on failure; unsent ones dropped locally. Summary rollback to the
  previous message (sender and time) via the new additive rule `isUndo` (rules 54/54), with a text-only fallback for
  the old rules. Verified on the emulator with a message from Bob injected by an emulator-only admin script.
  The dev emulators crashed once because the post-build cleanup killed every big `java.exe` (the storage
  emulator's too): the cleanup now targets Gradle/Kotlin daemons only. Emulators restarted and re-seeded.
- **Chat replies, done:** `MessageReply` quote on messages (rules `validReply`, 55/55; fallback without the quote
  for the old rules), reply bar, quote in bubbles, swipe-to-reply with a haptic tick. Verified on the emulator
  (Bob's long question → swipe → reply with quote). Found why the dev emulators crashed twice: the rules-test run
  shares `%TEMP%\firebase\storage` with them (TEST_REPORT has the fix). The Android emulator was cold-restarted once
  (launcher ANR after hours of reinstalls). Flutter 239.
- **Creation choices, done:** privacy, colour and open date open `showChoiceMenu` (current in green, colour pins,
  date presets with calendar-correct months, "open right away"); the cycling pills are gone. Verified on the
  emulator. Flutter 241.
- **Heatmap (F-16), done:** single brand green, 40 px, 70 %, hidden at marker zoom (D-19). Verified on the
  emulator at three zoom levels. DECISIONS D-19, D-20 (chat deletes/replies) written.
- **One short date format, done:** `AppDates.short` (dd.MM.yyyy, the pills' format) replaces five formats (list,
  pills, map card, notifications, chat list, creation). CI's format check had failed on cad27e1 (an unformatted
  test file, hidden by cancelled runs before); fixed, and `dart format --set-exit-if-changed` is now part of the
  pre-commit checks.
- **"On this day" (Tier 3), done:** `OnThisDay.from` + `OnThisDayStrip` at the top of My Capsules when the list is
  not narrowed; `FeatureFlags.memories`. Verified on the emulator with two capsules dated one and two years ago
  (added to the local emulator by an admin script). Flutter 243.
- **Light-theme pass on tonight's UI:** menus, On this day, chat quotes. Found and fixed: the quote sat at the
  right edge of the friend's bubble. **Quote jump, done:** tap a quote → the list scrolls to the message (also
  far up and not yet built) and highlights it; verified with 40 messages in between.
