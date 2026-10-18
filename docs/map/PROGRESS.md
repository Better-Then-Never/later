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
| 1.1 | Long pinch harness (`map_pinch_sweep`, `map_pinch_wave` in perf_test) | |
| 1.2 | In-app instrumentation (`MapStats`) | |
| 1.3 | Recording analyzer `tool/dev/map_gesture_report.py` + driver `tool/dev/map_gesture.sh` | |
| 1.4 | Baseline × 3, cold start stages | |
| 1.5 | DIAGNOSIS.md | |
| 2 | Spikes A (Google, fixed) and B (MapLibre), DECISION.md | |
| 3 | Implement behind `FeatureFlags` | |
| 4 | Verify, PERFORMANCE "After", MORNING_SUMMARY.md | |

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
- Next: Phase 3, the MapLibre map page to parity (card, selected pin, user position, buttons, compass, focus, taps,
  filters, dark style, cold start), then measure 3 runs.
