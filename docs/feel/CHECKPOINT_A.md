# CHECKPOINT_A.md: Part A done (feel on a real phone)

Branch `feature/feel-pass-real-device`, draft PR #79 (stacked on #78). Part A ends at `7ae4f65`; Part B work starts
in the same branch after it (the first B1 commits, photo messages, landed while the final measurements ran and
are listed in FEATURES_B.md). Nothing merged, nothing deployed, no tags or version bumps.

## What Part A did
| Phase | Result | Where |
|---|---|---|
| 0. Rig | Phone over USB against the local emulators (Auth, Firestore, Storage, Functions); heavy seed (104 people, 2,002 capsules, a 600-message chat); pushes logged, never sent; scripts for run, reload, screen text, shots, perf runs, cold start, measuring a commit from a worktree | RIG.md, DEVICE.md, `tool/dev/`, `tool/seed_heavy.js` |
| 1. Baseline | 19 flows × 3 runs in profile mode at 120 Hz; hit-area audit on the phone | PERFORMANCE.md "Baseline", FEEL_QA.md |
| 2. Jank, by cause | Font warm-up; theme crossfade; map restyled in place; one page route without page fades; on-screen clustered markers (the freezes); rows under a painted cover; hidden tabs' tickers off; settings rows without `ListTile`; card rise without fade or scale | PERFORMANCE.md "Phase 2", "Regressions" |
| 3. Motion | One route with edge back swipe, cards with drag to close, tabs, photo heroes, reaction bursts, idle empty states, morphs, achievement and streak motion; every motion honours reduced motion | MOTION_CATALOG.md |
| 4. Layout | F-34 pill, F-33 headers, F-31 controls, F-39 friends card, F-40 gradients, F-30 compose icon, F-43 share icon, F-15 light map, zoom pill and compass, richer map card, camera zoom stops / brightness / torch / real pinch, 44 dp targets, sweep in light/dark, ru/en, 130 % | FEEL_QA.md, DECISIONS D-22..D-24 |
| 5. Verification | Final 3-run measurement, stills, FEEL_QA, achievement artwork override, stale docs fixed, STATUS_REVIEW addendum | PERFORMANCE.md "After", `docs/feel/after/`, `docs/ux/STATUS_REVIEW.md` §13 |

## Numbers (medians of 3 runs, Galaxy S20 FE, 120 Hz)
Most improved:
1. **Theme switch**: 16.8 % → 0.4 % janky, and the ~10 s freeze after every switch is gone (flow 22.1 s → 4.9 s).
2. **Freezes**: 4,351–6,548 skipped main-thread frames per run (10–12 s stalls after startup) → 0–150, only
   during the launch.
3. **Settings open/close**: 12.4 % → 3.3 % (worst frame 33 → 14 ms); **notification segments** 10.8 % → 1.1 %.

Still the weakest:
1. **Startup**: 6.6 % janky, worst frame 41.9 ms (hidden tabs lay out their lists when their data arrives).
2. **Settings open/close**: 3.3 % (first text layout and glyph atlas, ~5 ms worse in Russian: the app font has no
   Cyrillic).
3. **Camera tap → creation page**: 1,111 ms (CameraX `takePicture`); the tap itself answers in 24 ms with a frozen
   preview.

Cold start to the signed-in home: 958 ms (was 867; budget 2 s). Chat with 600 messages: 23 ms from tap to the
frame with messages.

## Gates
| Gate | Result |
|---|---|
| `tool/dev/checks.sh`: format, analyze, tests, design tokens, unused strings | ✓, 315 tests passed, 1 pre-existing skip (at `7ae4f65`) |
| Rules tests (Firestore + Storage, emulator) | ✓ 61/61 (57 before B1's photo rules) |
| Functions tests (emulator) | ✓ 45/45 |
| Perf flows on the phone | PERFORMANCE.md "After" (all flows ran 3 times; one camera run was repeated, see PROGRESS.md) |

## Not done or not verified in Part A (details in BLOCKERS.md)
- Reduced motion was checked in widget tests only, never switched on on the phone.
- Pushes: none delivered (no dev project); the server code is tested in the emulator only.
- iOS: nothing run.
- No video: ffmpeg is not installed; stills only.
- Engine-level costs left: first text layout and Impeller's glyph atlas on the first frame of a page.
- F-35 (jitter at the end of My capsules) was not reproduced, so nothing was changed.

## Owner decisions waiting
Cyrillic font (mixed typefaces and slower first frames in Russian); the local light map style (D-22) against the
cloud style; 44 dp settings rows (D-24); the new share icon (F-43, SVG for a designer); the functions' service
account needs Storage delete rights (BACKEND_CHANGES.md §2: account deletion cannot delete files today either).

## Next: Part B
In order: B1 chat (photos started; then the offline queue, typing, groups, voice, stickers, smaller gaps), B2
capsule interactions, B3 profiles, B4 creation, B5 map filters, B6 notifications, B7 gamification. Each feature:
smooth, five languages, tested, flagged if unfinished, written up in FEATURES_B.md.
