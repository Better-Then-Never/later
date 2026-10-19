# PROGRESS.md: map engine smoothness (resume from here)

Mission: the owner's "Rebuild the Map So Zooming, Pinching, the Heatmap, and Clusters Feel Perfectly Smooth"
(18 Oct 2026). Branch `feature/map-engine-smoothness`, based on `polish/interactive-fixes` at `e12f7e8` (it holds
the unmerged map work M-01..M-11; `main` is contained in it). Never push, merge, deploy or release unless the owner
asks in chat.

Evidence: the owner's recording `build/dev/video/owner4.mp4` (copy of the desktop file
`video_2026-10-18_18-44-32 send.mp4`, 43.6 s, 576×1280, recorded with the **debug** build of `e12f7e8` on the
phone).

## Steps
| # | Step | State |
|---|---|---|
| 0 | Branch, read STYLE_BIBLE, MOTION_CATALOG, CHECKPOINT_A, RIG | done |
| 1.1 | Long pinch harness (`map_pinch_sweep`, `map_pinch_wave` in perf_test) | done |
| 1.2 | In-app instrumentation (`MapStats`) | done |
| 1.3 | Recording analyzer `tool/dev/map_gesture_report.py` + driver `tool/dev/map_gesture.sh` | done |
| 1.4 | Baseline × 3, cold start stages | done |
| 1.5 | DIAGNOSIS.md | done |
| 2 | Spikes A (Google, fixed) and B (MapLibre), DECISION.md | done |
| 3 | Implement behind `FeatureFlags` | done |
| 4 | Verify, PERFORMANCE "After", MORNING_SUMMARY.md | done except the 3-run gesture measurement (BLOCKERS.md) |

## Log
- Branch created; `maplibre_gl` 0.27.1 (Sep 2026, Flutter ≥ 3.29) is compatible with Flutter 3.38.4 here;
  `maplibre` 0.3.6 needs Flutter 3.44 (not usable). OpenFreeMap reachable.
- 1.1–1.5 done: rig `f61e6b7`, baseline + diagnosis `fc86132` (build/perf/map_baseline).
- Spike A (Google, heat tiles drawn ahead and served from memory, 3D buildings off; `build/perf/spike_a`, code not
  kept): tiles 6 ms instead of 26, heat blinks 13 per sweep (baseline 12): Google Maps shows a tile layer blank
  after every level change however fast the tiles come. Markers cannot fade on Google (plugin re-sets the bitmap).
- Harness moved to **real touches** (`tool/dev/touch/Pinch.java` through Android's input, played by
  `map_gesture.sh` from the test's `MAPFINGERS` lines; the test binding must pass device touches on). Baseline
  again with real touches: `build/perf/baseline_real` (3 runs).
- Spike B (MapLibre, `lib/features/map/engine/`, flag `MAP_LIBRE`): `build/perf/maplibre_real` (3 runs),
  `build/perf/maplibre_tlhc` (texture mode, 1 run). Decision: B (DECISION.md). Two MapLibre traps fixed: slow
  closing pinch ignored (gesture speed resource override), SurfaceView → hybrid composition (texture mode).
- Phase 3: the MapLibre page at parity behind the flag (`a9adeec`): card, selected pin with its motion, user
  position, buttons, compass, focus from the list and notifications, taps, filters, dark style, saved camera.
- Open items inspected (`321a4c3` onwards): M-07 fixed (`8426062`); bubble tap fits the bubble's capsules
  (`1f47e6e`); pins after a cold start no longer wait for a later data change (`5a340d0`); Russian at 130 %,
  offline, cold start, APK size and iOS checked (BLOCKERS.md "Verified"); satellite sources listed for the owner.
- The final 3-run gesture measurement was stopped twice for low memory on the computer (profile build); not
  restarted without the owner. To run it: close other apps, then `bash tool/dev/map_gesture.sh after 3`
  (and stop the Gradle daemon afterwards: `cd android && ./gradlew --stop`).
- 19 Oct: the owner chose OpenFreeMap and MapLibre as the map; the flag is on by default (`MAP_LIBRE=false` for
  Google; `MAP_GOOGLE=1` in the perf scripts). Attribution checked on the phone. The owner chose to hide the
  satellite look: no map-look choice in Settings while MapLibre is on.
- 19 Oct: the capsule creation pin picker on MapLibre too (the 1 km circle as a GeoJSON polygon). Fixed the owner's
  report that the pin could not move: the sheet's drag-to-close took every vertical drag on the map; the map now
  claims every touch that starts on it (Google's picker too). Checked on the phone: drags in every direction, the
  snap back onto the 1 km edge, "use this spot", back to me, and closing the sheet by its top.

# Mission 2: finish the MapLibre map (19 Oct 2026, branch `feature/map-maplibre-polish`)

From `feature/map-engine-smoothness` at `55cba7a`. MapLibre with OpenFreeMap is the default (owner, 19 Oct);
`MAP_LIBRE=false` builds the Google map. Never push, merge, deploy or release unless the owner asks in chat.

| # | Step | State |
|---|---|---|
| 2.0 | Instant tap zooms: cause, shared camera helper, `map_tap_zoom` test | done |
| 2.1 | Bubble split and merge animation | |
| 2.2 | Continuous heat / bubble / pin handover | |
| 2.3 | Zoom feel: tiles, minimum zoom and bounds, finger-dot check, stalls | |
| 2.4 | Base map in the app's look | |
| 2.5 | Countdown seconds (M-10), selected emphasis (M-02) | |
| 4 | Measure on the phone, PERFORMANCE, MORNING_SUMMARY | |

## Log
- 2.0: the tap zooms jumped because the phone's animator scale was 0 (our own M-02 check of 18 Oct; DIAGNOSIS.md
  §9), restored; every app camera move now goes through one helper (`_animate`, traced as `MAPMOVE`), the Google
  clustering no longer runs on the MapLibre page, `map_tap_zoom` proves the animation on the phone (all four
  steps: 36–39 positions for a tap zoom, the largest step at most 0.13 of a level; the recording 0 gaps at 126 fps).
