# FLASH_FIX.md: flashing bubbles, ghosts and the double selected pin (mission 3)

Branch `fix/map-flash-ghosts-selection` (from `feature/map-maplibre-polish` at `aced9e8`). The owner's recording:
`build/dev/video/owner6.mp4` (copy of `video_2026-10-19_16-20-40 today2.mp4`, 70.6 s, 576×1280 at 30.6 fps, the
mission 2 build, "show touches" and "pointer location" on).

## The detector
- **Engine side** (`lib/features/map/engine/maplibre_flash_probe.dart`, `--dart-define=MAP_FLASH=true`): every frame
  the map moves or animates, `queryRenderedFeaturesInRect` over the whole map for the marker layers, compared with
  what was sent to the map. Counts (MapStats, `flash_*` in perf_numbers.json, `MAPFLASH` lines in the log):
  - **double**: the same marker drawn twice in one frame;
  - **missing**: sent, on screen (40/60 dp margins), clearly visible (opacity × zoom opacity ≥ 0.3, size ≥ 0.3)
    in the last three probes, and not drawn: a blink;
  - **ghost**: drawn, but in none of the last three probes' sent markers.
  The three-probe window allows a source update a frame or two to show. It cannot see a marker drawn
  see-through by MapLibre's own fade: the video check does.
- **Video side** (`tool/dev/map_flash_video.py`, run on every recording by `tool/dev/map_gesture.sh`): every frame
  at the recorder's rate; the solid brand-green area (bubbles, green pins) and the see-through green on the line to
  the ground colour (35–80 %; parks, woods and heat are mixed at 26 % or less). A flash: the solid area jumps by
  more than 25 % (and 60 px at 180×400) and comes back within 200 ms, compared about 33 ms apart (sample-and-hold
  at 30 Hz, two phases) so 120 fps recordings and the owner's 30 fps are judged alike.
- **Flows** (`integration_test/perf_test.dart`, real touches): `map_flash_slow`, `map_flash_normal`,
  `map_flash_fast` (from the heat at zoom 11 in to 15 and back, two levels a pinch in 1.5 s, 0.6 s, 0.18 s, about
  20 s each) and `map_flash_select` (select, close by tapping the map, select another, close and reselect within
  150 ms, tap a pin twice, close).

## Baseline (`build/perf/flash_base`, mission 2 code, MAP_FLASH build)
| Flow | probes | double frames (ids) | missing frames (ids) | ghost frames (ids) | video flashes |
|---|---|---|---|---|---|
| slow | 1608 | 27 (327) | 0 | 1 (4) | 0 |
| normal | 1641 | 3 (13) | 2 (4) | 0 | 2 |
| fast | 1568 | 6 (33) | 1 (2) | 3 (3) | 1 |
| select | 525 | 78 (78) | 0 | 0 | 0 |
| owner's recording | – | – | – | – | **17 in 70 s** (incl. the brief's five: 2.9, 5.2, 12.3, 14.6, 15.6 s) |

- The doubles of the zoom flows are landed pieces drawn by both the still and the moving source for about 13
  frames each; the selection flow's are the selected copy over the plain pin.
- The ghosts are level-11 bubbles still drawn after the level was replaced.
- By eye (owner's 12.3 s and 14.55 s): on a level change the old bubbles vanish in one frame, nothing replaces
  them for two frames, then the capsules come faint and grow solid over about 5 frames (160 ms) at fixed places.
- Our flows flash less than the owner's hands: his zooms are mostly double taps out of the heat band, where several
  level changes follow each other within one animation.
