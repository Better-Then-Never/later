# PROGRESS.md: Session A log (feel pass on a real phone, then features)

Branch `feature/feel-pass-real-device` (from the tip of `feature/ux-features-night-session`), draft PR #79 stacked
on #78. Never merged, never deployed. Resume here.

## Where things are
| Part | Status |
|---|---|
| Phase 0: rig | done (RIG.md, DEVICE.md) |
| Phase 1: baseline | done (PERFORMANCE.md "Baseline"; tap-target audit on the phone, FEEL_QA.md) |
| Phase 2: jank fixes | done (PERFORMANCE.md "Phase 2"); remaining first-frame costs are engine-level (glyph atlas) |
| Phase 3: motion system | done (MOTION_CATALOG.md); native map marker motion deliberately not built |
| Phase 4: layout | done (F-15, F-30, F-31, F-33, F-34, F-39, F-40, F-43, map controls, card, camera, tap targets, sweep) |
| Phase 5: verification, CHECKPOINT_A | done (CHECKPOINT_A.md, PERFORMANCE.md "After", STATUS_REVIEW §13) |
| Part B (B1..B7) | B1..B7 done (FEATURES_B.md; contacts flagged, icon badge not built) |
| Final | measured (PERFORMANCE.md "Final", 1 run), gates green, MORNING_SUMMARY.md written, PR ready for review |

## Log
### 2026-10-17
- Branch and draft PR #79 created; `docs/ux/STATUS_REVIEW.md` committed as the starting point.
- Phone: Galaxy S20 FE, Android 13, 120 Hz (DEVICE.md).
- Rig (RIG.md): `tool/dev/emulators.sh` (Auth, Firestore, Storage, Functions + `adb reverse`),
  `tool/seed_heavy.js` (2,002 capsules, 104 people, a 600-message chat, 40 notifications; refuses non-local hosts;
  pauses triggers while seeding), `tool/dev/{run,ctl,screen,shot,perf,coldstart}.sh`,
  `tool/dev/perf_summary.dart` (jank at 8.33 ms).
- Safety for the emulator rig: functions log pushes instead of sending them in the Functions emulator; emulator
  builds do not subscribe to FCM topics.
- Found and fixed: FlutterFire maps `127.0.0.1` to `10.0.2.2` on Android by default, so a USB phone could never
  reach the emulators (`automaticHostMapping: false` in bootstrap).
- Perf test rewritten: 18 flows, language-independent labels, `PERF_FLOWS` filter, `PerfMarks` timeline marks for
  tap → shutter feedback → file → creation, and chat open → messages shown. `StartupReport` calls Android's
  `reportFullyDrawn` when the signed-in home first draws (cold start to home; also Android vitals).
- Baseline (3 runs, 19 flows): first with semantics on by mistake (`testWidgets` default), then with it off (the
  normal case). Over budget: theme switch, settings, notifications segments, startup, add friends, chat first
  frames, camera; camera tap → creation 1.07 s.
- Diagnostics: `KEEP_TIMELINE=1 DETAIL=1` runs + `tool/dev/slow_frames.dart` (self time per event) named the causes:
  first text layout (Inria Sans has no Cyrillic), page-wide fades drawn offscreen on Impeller, the page underneath
  rebuilding, the map recreated on a theme switch.
- `tool/dev/measure.sh`: measures a commit from a worktree (`../later-measure`), so editing continues meanwhile.
- Fixes, each measured: font warm-up (chat open 3.2 → 1.4 %); theme crossfade (theme switch 16.8 → 0.7 %); map
  restyled in place (no recreation; local light style, owner to review, D-22); one capsule pin set for both themes;
  `AppPageRoute` (slide + painted scrim, interruptible, edge back swipe; settings 12.4 → 2.4 %, notifications
  10.8 → 3.9 %, camera open worst frame 28 → 8.5 ms); 44 dp tap targets (D-24).
- Found by flow wall times and Android's "Skipped N frames": the app **froze 10 s after every theme switch** and
  **4–5 s after startup** (marker updates on Android's main thread, where Flutter's vsync comes from). Theme freeze
  gone (theme flow 22 s → 4.8 s). Startup: markers now viewport-bounded and clustered (≤ 150), measuring.
- Phase 2, later fixes: rows enter under a painted cover (notifications 6.6 → 0.7 %); tabs stop hidden tickers;
  settings rows without ListTile; the centred-card route first regressed the capsule dialog to 20 % (a card fade),
  fixed by rising without a fade (3.9 → ~2–3 %); glyph-atlas warm-up tried and reverted after an A/B.
- Phase 3: route, cards with drag to close, tabs, heroes (card → dialog → viewer, creation → viewer), reaction
  bursts, idle float on empty states, pull to refresh that refreshes, pending → uploaded morph, save morph,
  achievements and streak, focus ring ≤ 350 ms, toasts and ring honour reduced motion, translated badge label.
- Phase 4: pill 68 dp with fixed tab slots; header from the real inset; history controls and search on the
  shared scale; friends card; per-user gradient placeholders; sharp compose icon; share icon (SVG for review);
  zoom pill; map card with photo; camera zoom stops, brightness slider, torch, real pinch test (3.8× on the phone);
  tap targets fixed from the phone audit; "On this day" overflow at 130 % fixed; light/dark, ru/en, 130 % sweep.
- Phase 5: `AchievementIcon` artwork override (D-16 now true); stale REPORT/ACHIEVEMENTS lines fixed; after stills;
  FEEL_QA.md. Incident: running the rules tests next to the dev emulators took them down mid-measurement (a
  Functions worker held a rules-test port); re-seeded and re-measured (RIG.md gotchas).
- Final measurement (`measure.sh after 3`): run 3 stopped in camera_pinch when the app went to the background
  mid-flow (no flash button found); the flow now records -1 and goes on (`9bbe55d`), and one more full run replaced
  run 3. One more finding from it: right after a re-seed the phone's Firestore cache slowed the first minutes
  (limbo documents; RIG.md), reproduced and confirmed by clearing the app's data.
- Map compass with the other controls (F-11), checked on the phone with a two-finger twist in the perf test.
- Regressions after Phase 3 named from a detailed timeline: the capsule dialog's card scale made Impeller re-draw
  its letters per size (3.2 → 0.6 % after removing it); the others explained (PERFORMANCE.md).
- Cold start at the end of Part A: 958 ms. CHECKPOINT_A.md written.
- Part B1 started: photo messages (app, rules, storage folder, cleanup function, pushes); rules 61/61,
  functions 45/45. The functions' service account has no Storage delete rights in production (also breaks
  account deletion's file cleanup today): deploy step in BACKEND_CHANGES.md §2.
- B1 done: photos, offline queue, typing, groups, voice (Android), big emoji and the sticker panel, unread
  divider, delete for me, forward, report a message, unread drop on delete, deep quote jump, swipe actions,
  pinned chats, reaction pushes. Each checked on the phone where it has a screen (FEATURES_B.md). Rules 73/73,
  functions 51/51.
- B2 done: report profiles, reaction/comment/reply notifications open the capsule (and its thread), comments in
  pages of 200, `showAuthor` (F-60) shown and set, share links through the web page (`later://capsule`), quick
  reply to the author (`capsuleRef`), co-authors (rules, index, notifications, My capsules and map, leave).
  Rules 75/75, functions 52/52, Flutter 352.
- Found on the phone during B2: the creation page was blank since Part A's save-morph button (its Center filled
  the bottom bar); toasts after a card closed itself never showed (no Overlay above the root navigator); a comment
  notification showed an error screen instead of the thread (MediaQuery read in initState). All fixed with tests
  that fail without the fix. Strangers' profiles got Report and Block.
- Incident, again: the rules tests next to the dev emulators took them down (their port cleanup stopped a process
  the dev emulators used). The emulators keep no data, so a re-seed followed. RIG.md says to stop them first;
  the helper now refuses to run while 8080 is busy.
- B3 done: profile tab redesign (about me, capsules in numbers, pinned and recent friends with quick actions, pins
  synced), people search by name (and from the chat search), settings gaps (units, photo quality with the 1080p
  camera, save to gallery, sign-in methods, download my data), contacts suggestions behind a flag. Functions 55/55,
  Flutter 366.
- Someone else used the phone during B3 (a group "Debils" created at 20:15 and pins changed at 20:27 while no adb
  command ran). Nothing of it was undone; the pin check had already passed (Bob and Hugo) before the change.
- Mistake caught: a test file of the same name already existed (profile_test.dart) and was overwritten; restored from
  git, the new tests live in profile_tab_test.dart.
- B4 done: loop capsules finished and switched on (mode switch, frame strip, speed, loop mark), thumbnails, drafts,
  own calendar, pin on a map, creation steps, composer, camera hero, friend capsules queued, backoff, Wi-Fi only,
  uploads in the background (WorkManager). Rules 78/78 before the thumbnail rule (its test runs with the next rules
  run), Flutter 374.
- B5 done: the map filter (whose, open or later, colours; kept per account on the phone). Mine only left 105 of
  1,208 capsules, Mine + red 17. The B5 commit (`0994c86`) left out the generated strings (`lib/l10n`); they
  came with the next commit, so `0994c86` alone does not compile. History is not rewritten on this branch, so it
  stays.
- B6 done: days, the team's announcements in the tab, swipes, friend requests answered in place, the vibration
  switch (two new Android channels), the router turned into tested destinations; on the server achievements are
  checked where stats change (`unlockAchievements` removed) and a capsule's follower fan-out stops at 500. The B6
  commit missed `functions/index.js`; `6eef251` adds it. Functions 58/58, Flutter 385.
- Found on the phone during B6: one accept in place unlocked five seeded achievements and sent five notifications
  at once; a catch-up now tells once.
- Rig: a stale `flutter run` session kept pushing old code, and opening the app again from the launcher ran the
  installed APK instead of the reloaded code (RIG.md §5).
- B7 done: the streak on the map with its at-risk variant and card; unlock and milestone moments from real events
  (Part A item 8); capsules viewed and "Curious"; the passport (world summary on the server, country names from
  Android); `entitlements/limits`; the weekly-limit vs daily-streak note (FEATURES_B.md). Functions 62/62.
- Found on the phone during B7: a server catch-up of four seeded tiers showed four cards in a row (now one card for
  a burst, checked again on the phone); "Соединенные Штаты" overflowed its stamp (fixed, with a test).
- Test gotcha: awaiting a stream subscription's `cancel()` inside a widget test resumes outside the test's fake
  time, and the next pump never returns (the moments test hung for minutes). `MomentsController.dispose` cancels
  without waiting.
- Rig: rapid zooming on the map against the emulators ended the Firestore watch stream with RESOURCE_EXHAUSTED
  (HTTP/2 ENHANCE_YOUR_CALM); markers came back after a pause. Opening capsules by link (`later://capsule/<id>`) was
  the reliable way to view many on the phone.

### 2026-10-18
- Final measurement, one run at the owner's request (all 27 flows; the first attempt stopped at camera_capture:
  B4 changed the shutter's label, the perf test now taps the new one). Cold start 820 ms. PERFORMANCE.md "Final".
- The owner skipped the last phone pass (Part B in dark, at 130 % and the tap audit of its screens): BLOCKERS.md.
- Gates: checks.sh green (404 tests, 1 pre-existing skip), rules 82/82, functions 62/62.
- MORNING_SUMMARY.md, the STATUS_REVIEW ratings, the Part B still sheet (`docs/feel/after/partb.png`).
