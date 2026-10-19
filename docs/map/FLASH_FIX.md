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

## Root causes, one at a time (each change measured, kept or reverted)
| # | Hypothesis (brief §2.2/2.4) | Evidence | Fix | Kept |
|---|---|---|---|---|
| A | MapLibre's own transitions (symbol fade on placement, 300 ms paint transitions) | The style had no `transition`: every newly placed symbol (a pin or bubble at a new place, new tile) faded in from nothing over 300 ms, old tiles' symbols faded out at their old places: the owner's "lighter then solid" frames and fuzzy discs at old positions; the selected pin's paint was eased 300 ms behind its own motion. Blinks 3 → 0 frames, video flashes 3 → 1. | `transition: {duration: 0}` in the style (`7117939`) | yes |
| B | Two sources / layers for the same pieces (still and moving) | Probe: a landed piece drawn twice for ~13 frames (27 / 3 / 6 double frames), a vanished one could leave a gap; the selected pin a second copy over the plain one (78 double frames in the select flow), swapped back with a jump of size and place | One source holds every pin and bubble, at rest and moving; the selected pin is the same marker posed by the pins layer (`f50dba8`) | yes |
| C | Fades squeezed into a fast zoom, and the 60-piece cap | By eye: bubbles vanished in 1–2 frames, pieces came faint; beyond 60 pieces they simply switched ("only some flash") | Nothing see-through in the motion (grow/shrink, under the bubbles); no cap; faster zoom = shorter motion, never skipped (`f50dba8`) | yes |
| D | Counting numbers | Every new number was a new icon; MapLibre re-laid out every tile's symbols for it, the map held 2–3 frames (the slow flow's last event disappeared without it) | The number stays during a move (`f50dba8`) | yes |
| E | Heavy updates on Android's main thread | 400-feature frames took up to 38 ms; with 2,205 capsules the split out of the heat (300 pieces) stalled, then jumped | Compact features, only the screen while moving (`f50dba8`); no flights while the markers are still see-through at the heat's edge (`9154fb2`) | yes |
| – | Sending 30 instead of 60 times a second | No change | – | reverted |
| – | Unstable feature ids (`promoteId`) | Ids were stable already (capsule id; a bubble's level and first capsule); MapLibre does not animate between feature states, so ids do not restart anything | – | not needed |
| – | Animation plan restarted on every camera event | The plan only changes when the shown level changes; a change mid-way starts from what is drawn (tests) | – | not the cause |

Fast zoom out (§2.3): checked frame by frame on the phone: from zoom 15.5, a 130 ms flick out to 13.7: the pins
pair up and fly together, shrinking, while the "2" bubbles grow in under them; nothing vanishes. A flick straight
into the heat (13 → 10.5 in about 40 ms) clears the markers with the zoom (the owner's earlier rule).

Selected pin (§2.4): one marker per capsule (probe: 0 double frames in every select flow). It grows over
`AppMotion.fast` (150 ms, eased out; test: no step over 0.03 of its size per 8 ms frame) while it rises; its shadow is
drawn from the same picture; closing, it lands on the exact resting pose (the last pose sent is the resting one:
no swap, no jump); another pin lands while the new one rises; caught landing, it rises again from where it is.

## Final (`9154fb2`, Galaxy S20 FE, profile, real touches)
| | slow | normal | fast | select |
|---|---|---|---|---|
| Probe, light (`final_probe`): double / missing / ghost frames | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 |
| Probe: torn frames (two consecutive pictures in one frame) | 1 | 3 | 3 | 0 |
| Video flags, three runs (`final_r1..r3`) | 0, 0, 0 | 0, 0, 0 | 1, 1, 1 | 0, 0, 0 |
| Video flags, 2,205 capsules (`final_2200b`) | 1 | 3 | 1 | 0 |
| Probe, dark (`final_dark`): missing frames | 2 | 4 | 5 | 0 |

Looked at frame by frame (not every flag):
- the fast flow's flag in earlier builds of this code (same time, same size as in runs 2 and 3: first flick out of
  the heat, 5 frames) and the 2,205-capsule normal flag (1.83 s): the markers' zoom fade completing in one camera
  jump at the start of a pinch out of the heat (MapLibre catches up the first pixels of a fast pinch at once), then a
  bubble opening and its pieces flying out within 200 ms: real changes the detector cannot tell from a flash;
- run 1, fast (2.3 s): a "7" bubble opening and closing again within about 30 ms at the first flick. Not reproduced
  in a traced run (the shown level only stepped forward). Open (BLOCKERS.md);
- the other 2,205-capsule flags (slow 2.3 s, normal 2.07 s and 2.32 s, fast 1.1 s) were not looked at one by one.

The owner's recording had 17 flags in 70 s by the same detector (the brief's five among them).
