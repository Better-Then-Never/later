# PERFORMANCE.md: measured feel on a real phone

## Budgets (the bar every flow is held to)
| What | Budget | How it is measured |
|---|---|---|
| Steady flows (scrolls, pans, open/close, switches) | **≤ 1 % janky frames**, and **no single frame over 16.7 ms (2× the 8.33 ms budget)** at the start of an animation | per-frame build/raster times from `traceAction` (`tool/dev/perf_summary.dart`), cross-checked with Android's own jank count for the app's layer (SurfaceFlinger TimeStats) |
| Cold start | **< 2 s** to the first frame of the signed-in home screen | `am start -W` TotalTime (process start → first frame) and the test's own "launch → home" timestamp |
| Camera | **< 300 ms** perceived from tap to visible capture feedback | timestamps logged by the app in profile mode (tap → feedback frame → file written) |
| Chat open (600 messages) | **< 400 ms** from tap to the first frame showing the latest message | timestamps measured by the test (tap → latest message laid out) |

Device: Samsung Galaxy S20 FE at 120 Hz (DEVICE.md). Profile builds only. Rig and tools: RIG.md.

"Janky" here means a frame whose build **or** raster took longer than 8.33 ms. Flutter's UI and raster
threads are pipelined, so each has one vsync; a frame over the budget on either thread misses its slot.

## Baseline (Before)
Commit `17125f7` plus the measurement fix below (the night-session app; only measurement code changed), 3 runs on
2026-10-17, battery 80 %, 26–32 °C, seeded with `tool/seed_heavy.js`. Medians over the runs; ✗ = over a budget.

**Semantics off.** `testWidgets` builds the accessibility tree on every frame by default; only people with a screen
reader pay that. A first baseline with it on (`docs/feel/perf/baseline_semantics_on.md`) was 1–7 points worse on
the opening flows (chat open 10.3 % instead of 3.2 %). The table is the normal case; screen-reader cost is a
separate item (IDEAS_NOT_DONE.md).

| Flow | Frames | Janky % (≤ 1) | Worst frame ms (≤ 16.7) | p90 ms | Runs (janky %) | |
|---|---|---|---|---|---|---|
| startup (launch → home, signed in) | 62 | 8.1 | 26.5 | 4.2 | 9.8 / 8.1 / 7.6 | ✗ |
| tab_switches (6 taps) | 317 | 0.3 | 29.6 | 3.5 | 0.3 / 0.3 / 0.3 | ✗ (one 30 ms frame) |
| history_scroll (My capsules, 102, to the end and back) | 336 | 0.0 | 6.4 | 3.7 | 0 / 0 / 0.3 | ✓ |
| settings_open_close | 104 | 12.4 | 33.4 | 9.8 | 15.4 / 12.4 / 9.6 | ✗ |
| theme_switch (dark → light → system) | 129 | 16.8 | 31.6 | 12.7 | 13.2 / 16.8 / 61.3 | ✗ |
| add_friends_transition | 160 | 2.5 | 18.1 | 5.1 | 2.5 / 5.0 / 2.5 | ✗ |
| notifications_tabs (segment switches) | 251 | 10.8 | 15.5 | 8.8 | 10.8 / 12.4 / 7.5 | ✗ |
| chat_open (600 messages, ×3) | 283 | 3.2 | 14.4 | 6.6 | 7.4 / 3.2 / 2.1 | ✗ |
| chat_scroll (back through history and down) | 308 | 0.0 | 6.3 | 4.0 | 0 / 0 / 0 | ✓ |
| chat_options_sheet (open/close ×2) | 251 | 0.0 | 6.4 | 4.0 | 0 / 0 / 0 | ✓ |
| map_focus (fly to a capsule, card) | 174 | 0.6 | 14.1 | 2.7 | 0.6 / 0.6 / 0.6 | ✓ (Flutter side) |
| capsule_dialog | 149 | 0.7 | 14.5 | 3.0 | 1.4 / 0.7 / 0.7 | ✓ |
| photo_viewer | 123 | 0.8 | 13.1 | 6.2 | 0.8 / 2.4 / 0.8 | ✓ |
| map_zoom_out (4 pinches, across the marker threshold) | 327 | 0.0 | 4.1 | 2.7 | 0 / 0 / 0 | ✓ (Flutter side) |
| map_pan_heatmap | 191 | 0.5 | 8.8 | 3.1 | 0.5 / 0.5 / 0 | ✓ (Flutter side) |
| map_zoom_in | 207 | 0.0 | 3.7 | 2.2 | 0 / 0 / 0 | ✓ (Flutter side) |
| map_pan_markers | 188 | 0.0 | 3.6 | 2.6 | 0 / 0.5 / 0 | ✓ (Flutter side) |
| camera_open_close | 165 | 1.2 | 28.4 | 3.3 | 1.2 / 0.6 / 1.2 | ✗ |
| camera_capture | 145 | 1.4 | 19.9 | 2.9 | 1.4 / 1.4 / 2.0 | ✗ |

| Timed | Median | Budget | |
|---|---|---|---|
| Cold start, process → first frame (= signed-in home) | **867 ms** (885, 867, 865, 923, 866) | < 2 s | ✓ |
| Launch → home inside the test (bootstrap, warm process) | 397 ms | | |
| Camera: tap → shutter feedback frame | 26 ms | | ✓ |
| Camera: tap → picture file written | 1,053 ms | | |
| Camera: tap → first frame of creation | **1,070 ms** | < 300 ms perceived | ✗ |
| Chat (600 messages): tap → first frame with the latest messages | **21 ms** to the frame, 34 ms test-side (first open of a run ~100 ms) | < 400 ms | ✓ |

**Reading it.**
- The steady flows (scrolls, pans, tab switches) are already within budget on this phone. The jank sits at the
  **start of things**: opening a page (settings, add friends), the first frames of a chat, switching notification
  segments, the theme switch, startup, the camera. Those are first-build and work-at-animation-start costs.
- The theme switch is slow for its whole length (p90 12.7 ms): `MaterialApp` lerps the theme for 300 ms, so every
  themed widget in all five tabs rebuilds on every frame, and the map is recreated (its light style needs the map
  ID, the dark one must not have it).
- The camera answers at once (22 ms) but the picture takes 1.1 s inside CameraX; the creation page waits for it.
- The map's own rendering is native (Google Maps), so Flutter's numbers above show only the Flutter overlay;
  Android's frame stats for the map and camera runs are below.
- The baseline also found a crash path: after a theme switch the old map's idle callback used its disposed
  controller (fixed in `17125f7`, a guard; the real fix is not recreating the map).

**Causes, by name** (`KEEP_TIMELINE=1 DETAIL=1` run, `tool/dev/slow_frames.dart`, self time per event):
| Flow | Slowest frame | Where the time went |
|---|---|---|
| theme_switch | 86 ms UI | map platform view recreated (`RenderAndroidView` 22 ms); every tab rebuilt (64 ListTiles, 135 Images, 206 animated text styles), and again on each of the 36 lerp frames |
| settings_open_close | 26 ms UI, 23 ms raster | first text layout 9.6 ms (30 paragraphs: first use of a weight, and of the phone's font for Cyrillic, which Inria Sans lacks); 16 Material `ListTile`s; raster: 13 `saveLayer`s 10.2 ms (the route's whole-page fade draws the page offscreen) and a glyph atlas upload 9.3 ms |
| notifications_tabs | 19 ms UI, 18 ms raster | 53 `Image`s on the profile page underneath rebuild (`TickerMode` flips when a page covers or uncovers them); raster: 2 `saveLayer`s 13 ms (fading list items and the page fade) |
| chat_open | 21 ms UI | first build of the chat (12.6 ms build, 28 paragraphs, the composer's `EditableText`) |
| add_friends_transition | 19 ms UI, 12 ms raster | the 53 profile `Image`s again on return; raster submit 10.7 ms on the first frame |
| startup | 20 ms UI ×3 | first text layout 5.6–6.7 ms per frame (37–47 paragraphs), the map view's first build |
| camera_open_close | 10 ms raster | 2 `saveLayer`s 8.3 ms (route fade over the preview) |

Recurring: **first text layout** (fonts loaded on first use), **whole-page opacity** (fades render the page
offscreen on Impeller), and **rebuilding the page underneath** when a route covers or uncovers it.

**Android's view of the native parts** (`dumpsys gfxinfo`, which counts the frames Android's renderer draws for
the window: here the platform views, i.e. the Google map and the camera preview, not Flutter's own frames). Three
runs per subset; a startup-only subset gives the frames to subtract (launch: 18–33 frames, 10–11 janky).

| Subset (3 runs) | Window frames | Janky | Janky minus startup |
|---|---|---|---|
| startup only | 19 / 33 / 18 | 10 / 11 / 11 | – |
| map flows (focus, dialog, photo, zooms, pans) | 438 / 375 / 347 | 17 / 17 / 12 | 6 / 6 / 1 of ~330–420 → **1.4 / 1.7 / 0.3 %** |
| camera flows (open/close, capture) | 36 / 35 / 28 | 12 / 14 / 13 | 1–3 of ~10–17 (too few frames to judge) |

The map is at the edge of the budget on Android's side (median 1.4 %).

Raw: `docs/feel/perf/baseline.md` (generated by `tool/dev/perf_summary.dart`).

## Phase 2: fixes, each measured (3 runs, medians)
| Fix (commit) | Flow | Before → after |
|---|---|---|
| Fonts laid out before the first frame (`f9e6c3e`) | chat_open | 3.2 → 1.4 % janky |
| | add_friends_transition | 2.5 → 1.3 % |
| | launch → home (test) | 397 → 472 ms (the warm-up costs ~75 ms before the first frame; cold start still < 1 s) |
| Theme crossfade instead of a 300 ms lerp (`462d07e`, `4969966`) | theme_switch | 16.8 → 2.6 % janky, p90 12.7 → 2.7 ms |
| Map restyled in place + one pin set for both themes (`c9bf471`, `b75da0a`) | theme_switch | 2.6 → 0.7 % janky; **flow 22.1 s → 4.8 s: the ~10 s freeze after each switch is gone** |
| One page route: slide + painted scrim, no page-wide fade (`365b8a0`) | settings_open_close | 12.4 → 2.4 %, worst 33.4 → 18.2 ms |
| | notifications_tabs | 10.8 → 3.9 % |
| | camera_open_close | worst frame 28.4 → 8.5 ms |
| | photo_viewer | 0.8 → 0 % |
| Markers: on-screen only, clustered, ≤ 150 (`0262430`) | Android main-thread stalls per run | **4,351–6,548 skipped frames (longest 10–12 s) → 44–77 (the launch only)** |

| Rows enter under a painted cover, not opacity (`9d0b227`) | notifications_tabs | 6.6 → 0.7 % janky (ten fading rows had cost 9–13 ms of raster per frame) |
| Tabs: hidden tabs' tickers off, incoming tab rises (`0f5d1a8`) | add_friends_transition | 1.8 → 1.2 % |
| | camera_open_close | 0.6 → 0 % |
| Settings rows without `ListTile` (`261e6df`) | settings_open_close | worst frame 18.4 → 15.1 ms; janky unchanged at 2.4 % (see below) |
| Centred cards on `AppCardRoute`, first with a card fade (`f7025e4`) | capsule_dialog | **1.3 → 20 % (regression)**: a fade of a big card is an offscreen layer per frame |
| … then rising without a fade (`c0cabda`) | capsule_dialog | 20 → 3.9 % |
| Glyph atlas warm-up (`56d2fee`, **reverted**) | A/B, 3 runs each | dialog 3.2 vs 3.3 %, settings 2.4 vs 3.2 %, startup worst 36.9 vs 49.9 ms: no gain, removed |

**What is left in the open/close flows** (1–3 frames per open on this phone): the first frame of a page builds
it (settings 10–15 ms, mostly text layout; ~5 ms more in Russian, whose letters come from the phone's font), and
one or two raster frames where Impeller adds new letters to its glyph atlas (`UpdateAtlasBitmap`, 6–9 ms). Drawing
the letters offscreen beforehand does not help (A/B above). These are engine-level costs; see BLOCKERS.md.

**The freezes.** Two problems no frame time showed, because a frozen app draws no frames: ~10 s after each
theme switch and 4–5 s after startup. Both were Google Maps applying ~1,200 marker updates on Android's main
thread, which is also where Flutter's vsync comes from. They were found from the flows' wall-clock times and
Android's "Skipped N frames" reports, which `tool/dev/perf_summary.dart` now prints for every run.

Full table at `0262430`: `docs/feel/perf/fix4.md`.

## After
Pending: Phase 5.
