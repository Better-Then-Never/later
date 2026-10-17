# PROGRESS.md: Session A log (feel pass on a real phone, then features)

Branch `feature/feel-pass-real-device` (from the tip of `feature/ux-features-night-session`), draft PR #79 stacked
on #78. Never merged, never deployed. Resume here.

## Where things are
| Part | Status |
|---|---|
| Phase 0: rig | done (RIG.md, DEVICE.md) |
| Phase 1: baseline | done (PERFORMANCE.md "Baseline"); tap-target phone audit still to run |
| Phase 2: jank fixes | in progress: fonts, theme crossfade, map restyle + shared pins, route, clustering done |
| Phase 3: motion system | not started |
| Phase 4: layout | not started |
| Phase 5: verification, CHECKPOINT_A | not started |
| Part B (B1..B7) | after CHECKPOINT_A |

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
