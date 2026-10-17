# PROGRESS.md: Session A log (feel pass on a real phone, then features)

Branch `feature/feel-pass-real-device` (from the tip of `feature/ux-features-night-session`), draft PR #79 stacked
on #78. Never merged, never deployed. Resume here.

## Where things are
| Part | Status |
|---|---|
| Phase 0: rig | in progress: emulators + seed + dev scripts + docs written; first phone runs |
| Phase 1: baseline | not started |
| Phase 2: jank fixes | not started |
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
