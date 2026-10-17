# PERFORMANCE.md: frame timings, before and after

## How it is measured
`integration_test/perf_test.dart` drives the app through the key flows in **profile mode** against the local
Firebase emulators and records each flow with `traceAction`; `test_driver/perf_driver.dart` writes one
`*.timeline_summary.json` per flow, and `dart run tool/perf_table.dart <dir>` prints the table. The run script
builds the profile APK, installs it with all permissions granted (`adb install -r -g`), then runs
`flutter drive --profile --no-dds --use-application-binary=...` (DDS breaks `traceAction` on this setup).

Device: Android emulator (Medium Phone, API 36, host GPU GeForce GTX 1060, Impeller).

**Limitation, measured:** on this emulator the raster thread takes about 110 ms per frame for every screen,
with Impeller *and* with Skia (`perf/skia_check`), so it renders at about 8 frames per second whatever the app
does. Raster numbers here describe the emulator's GPU bridge, not the app, and are not used as budgets. The
**build (UI thread) times are meaningful**: they are what makes an animation start late or hitch, and they are the
budget used below (worst frame under 16.7 ms, p90 under 8 ms). Raster time on a real phone is a manual check
(BLOCKERS.md).

## Baseline (start of the mission, commit 9cb4be8)
| Flow | Frames | Build avg / p90 / worst (ms) | Raster avg / p90 / worst (ms) | Over 16.7 ms (build / raster) |
|---|---|---|---|---|
| add_friends_transition | 20 | 3.0 / 5.0 / 21.3 | 113.9 / 132.5 / 145.7 | 1 / 19 |
| camera_open_close | 17 | 1.8 / 1.6 / 18.2 | 225.1 / 499.6 / 887.1 | 1 / 15 |
| history_scroll | 138 | 1.1 / 1.9 / 6.1 | 116.0 / 139.3 / 219.3 | 0 / 136 |
| map_pan | 55 | 0.8 / 1.7 / 2.9 | 109.6 / 133.5 / 136.9 | 0 / 54 |
| notifications_tabs | 38 | 2.1 / 5.4 / 6.6 | 104.3 / 134.4 / 168.0 | 0 / 35 |
| open_chat | 18 | 3.5 / 7.0 / 23.2 | 153.7 / 142.1 / 637.9 | 1 / 17 |
| settings_open_close | 20 | 1.7 / 4.2 / 9.7 | 115.1 / 136.1 / 202.4 | 0 / 19 |
| startup | 20 | 19.4 / 52.4 / 116.0 | 177.5 / 264.9 / 342.2 | 6 / 17 |
| tab_switches | 42 | 7.5 / 15.1 / 89.1 | 147.8 / 212.4 / 579.8 | 4 / 41 |

{
  "startup_ms_to_home": 2938
}

Jank sources visible in the baseline (UI thread):
- **startup**: 116 ms worst frame, p90 52 ms (first build of the home shell, map controller, icons).
- **tab_switches**: 89 ms worst frame (first build of a tab inside the IndexedStack).
- **open_chat**: 23 ms first frame; **add_friends_transition**: 21 ms first frame (non-lazy list + 50 avatars);
  **camera_open_close**: 18 ms.

## Mid-mission run (commit 25b5a85, data in `perf/mid`)
Same harness and account, profile mode, emulator started with `-gpu host` this time: **raster times are not
comparable with the baseline** (the baseline emulator rendered ~110 ms per frame for any screen; here ~40-55 ms).
More frames per flow mostly reflect that faster raster. Build (UI thread) times are the comparable budget.

| Flow | Frames | Build avg / p90 / worst (ms) | Raster avg / p90 / worst (ms) |
|---|---|---|---|
| add_friends_transition | 49 | 3.9 / 12.2 / 25.9 | 36.3 / 50.2 / 63.8 |
| camera_open_close | 63 | 3.6 / 7.5 / 54.6 | 53.7 / 78.2 / 321.1 |
| history_scroll | 216 | 2.1 / 3.8 / 75.9 | 42.9 / 59.9 / 103.8 |
| map_pan | 135 | 1.5 / 2.5 / 18.0 | 41.8 / 54.3 / 112.6 |
| notifications_tabs | 100 | 4.1 / 12.3 / 24.4 | 40.8 / 53.3 / 78.6 |
| settings_open_close | 45 | 5.1 / 17.3 / 46.4 | 40.5 / 55.5 / 101.9 |
| startup | 43 | 10.1 / 13.2 / 148.3 | 57.5 / 89.9 / 406.5 |
| tab_switches | 95 | 5.8 / 17.8 / 51.9 | 51.9 / 77.2 / 165.1 |

Startup to home: 2792 ms (baseline 2938 ms). open_chat drew no frame: the test account has no chat yet (the
driver now reports such a flow instead of aborting). Reading: build p90 stays under one frame (16.7 ms) except
tab switches and settings, whose p90 is 17-18 ms from the first build of a tab/page; worst frames are first
builds (startup, first history frame with the new photo decode, camera open). Map pan: build p90 2.5 ms with the
memoized markers (F-10).

## After
(filled at the end of the mission)
