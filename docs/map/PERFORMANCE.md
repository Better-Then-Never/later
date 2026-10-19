# PERFORMANCE.md: the map under the fingers

How it is measured: `tool/dev/map_gesture.sh <label> 3` (profile build, Galaxy S20 FE, 120 Hz, the heavy seed: the
signed-in account sees 1,205 capsules, about 1,100 of them in Warsaw). Two gestures, each recorded on screen:

- **map_pinch_sweep**: from the city (zoom 13) out to the country (about 5.4), in to the street (about 16.7), out to
  the country and back to the city: 20 pinches of 1.9 zoom levels in 0.6 s each, 0.35 s between them.
- **map_pinch_wave**: fingers held down, in and out four times across the heat / bubble band (zoom 10.8 to 12.7),
  then four times across bubble splits (12.7 to 14.6).

Columns:
- **Flutter frames, janky %**: frames whose build or raster took over 8.3 ms. *Caution*: the map is a native view;
  frames in which only the map moves do not appear in Flutter's numbers, so 0 % here does not mean smooth.
- **heat mutations**: changes to the heat layer (created, removed, made visible or hidden, emptied).
- **heat tiles**: heat tiles drawn (each a gap in the heat until it arrives).
- **markers + / −**: markers added and removed on the native map; **largest update** in one go.
- From the recording (`map_gesture_report.py`, about 114 recorded frames a second during the gesture):
  **gaps ≥ 100 ms** (no new frame: a stall), **frozen ≥ 150 ms** (the map part did not change while the app drew),
  **dropout frames** (the map suddenly bare: heat and markers below a quarter of what showed in the half second
  before), **heat blinks** (heat gone and back within a second).

## Baseline (`e12f7e8` + the rig `f61e6b7`; `build/perf/map_baseline`)
| Flow | run | Flutter janky % | worst ms | heat mut. | heat tiles | markers + / − | largest upd. | gaps ≥100 | longest gap | frozen ≥150 | dropout frames | heat blinks |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| sweep | 1 | 0.0 | 4.9 | 3 | 80 | 601 / 734 | 136 | 1 | 117 | 3 | 173 | 12 |
| sweep | 2 | 0.0 | 4.0 | 3 | 80 | 603 / 736 | 136 | 1 | 116 | 3 | 189 | 12 |
| sweep | 3 | 0.0 | 5.1 | 3 | 80 | 598 / 731 | 136 | 2 | 332 | 1 | 193 | 12 |
| wave | 1 | 0.4 | 9.3 | 9 | 3 | 1,613 / 1,560 | 121 | 0 | 0 | 2 | 333 | 0 |
| wave | 2 | 0.0 | 6.0 | 9 | 3 | 1,611 / 1,558 | 121 | 0 | 0 | 1 | 361 | 0 |
| wave | 3 | 0.0 | 4.8 | 9 | 3 | 1,606 / 1,553 | 121 | 0 | 0 | 1 | 349 | 1 |

Other counts per run (medians): heat tile 26 ms each (drawn in an isolate, sent over the plugin channel);
clustering 15 runs, 6 ms in all, slowest 2.2 ms; map widget builds 107 (sweep) and 196 (wave); style changes 0;
camera moves about 2,870 (sweep) and 3,225 (wave), i.e. one per frame.

**The owner's recording** (`build/dev/video/owner4.mp4`, the **debug** build of `e12f7e8`, by hand): 21 gaps of
100 ms or more (longest 299 ms), 57 dropout frames, 5 heat blinks. The gaps come mostly from debug mode: the same
gestures in profile mode show 0 to 2. The blinks, bare frames and marker churn are the same in both.

### Cold start (profile build, 3 launches, `build/dev/video/cold_*.mp4`)
The same six stages each time: white window (0.9 s) → loading logo (0.6 s) → the page's buttons over an off-white
area, no map yet (0.9 s) → a beige map with no streets, the user's figure, pins popping in (1.0 s) → streets drawn
(about 4.5 s after the tap) → clusters settle.

## After (MapLibre on, `5a340d0`)

### Under the fingers: not measured yet
The 3-run measurement (`tool/dev/map_gesture.sh after 3`) was stopped twice because the computer
ran low on memory during the profile build (BLOCKERS.md). The latest MapLibre numbers with the same harness and
gestures are the spike's, before the page reached parity (DECISION.md): 0 heat layer changes, 0–1 heat blinks per
sweep, 0 markers added or removed, 0 recording gaps of 100 ms or more, 0 frozen spans, answer to a finger 30–53 ms,
Flutter 0 % janky in texture mode.

### Cold start (profile build, 3 recorded launches `build/dev/video/mlcold_*.mp4`, 5 timed)
Four stages: the launch window in the page background (#F6F6F6, about 0.9 s; no pure white; in one launch of three
the launch logo for up to 0.2 s) → the page's buttons over the map's ground colour (#F3F3F0, 0.3 to 0.6 s) →
**streets at the saved place 1.4 to 1.8 s after the tap** (baseline: about 4.5 s, after a beige map without
streets) → the pins once the capsules arrive, 4.0 to 4.4 s after the tap (the local emulator answers 3.2 to 3.8 s
after the tap; the map shows them about 0.5 s later).

Process start to the first frame of the signed-in home (`tool/dev/coldstart.sh`): median **963 ms** (938–998),
budget 2 s. The feel pass ended at 820 ms on the Google page at an earlier commit; Google was not timed again at
this commit, so the two are not a comparison.

Offline (Wi-Fi off, the emulators over USB): the streets at the saved place come from MapLibre's tile cache.

## After 2: the finished MapLibre map (mission 2, branch `feature/map-maplibre-polish`, 19 Oct 2026)

`tool/dev/map_gesture.sh` run three times one by one (`build/perf/after_r1`, `after_r2`, `after_r3`), then twice
with 2,205 capsules (`after_2200`, `after_2200b`; 1,000 extra friends' capsules on the local emulator, removed
afterwards). The harness now also reports, under two fingers, how far the map's scale strays from the fingers'
spread (zoom levels) and how far the place under their middle drifts (dp), and a third flow, `map_tap_zoom`.

### Under the fingers (1,205 capsules)
| Flow | run | Flutter janky % | worst ms | heat mut. | markers +/− | in-app gaps ≥100 | answer ms avg/max | scale error avg/max (levels) | anchor drift (dp) | video gaps ≥100 | frozen ≥150 | heat blinks |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| sweep | r1 | – | – | 0 | 0 | – | – | – | – | 0 | 0 | 1 |
| sweep | r2 | 0.0 | 5.9 | 0 | 0 | 0 | 41/53 | 0.023/0.228 | 0 | 0 | 0 | 0 |
| sweep | r3 | 0.4 | 8.7 | 0 | 0 | 0 | 50/71 | 0.027/0.430 | 0 | 0 | 0 | 0 |
| wave | r1 | – | – | 0 | 0 | – | – | – | – | 0 | 0 | 0 |
| wave | r2 | 0.0 | 6.6 | 0 | 0 | 0 | 67/83 | 0.018/0.114 | 0 | 0 | 0 | 0 |
| wave | r3 | 0.0 | 7.7 | 0 | 0 | 0 | 57/69 | 0.020/0.100 | 0 | 0 | 0 | 0 |

Run 1's in-app numbers are missing: its `map_tap_zoom` step failed (below) and the test then records nothing; its
recordings are read.

- **Dropout frames** (the report's "map suddenly bare") count 112–223 per flow in these runs. They are the heat
  handing over to the bubbles in the narrowed band (zoom 11.0–11.85): checked frame by frame (`after_r2` wave at
  4.1 s), the heat thins while bubbles and pins grow in; never a frame with neither. The rule compares with the
  half second before, which a fast handover now always triggers; it no longer measures a fault.
- **Heat blinks**: one in r1's sweep and one in `after_2200b`'s wave (at 4.46 s): there the heat leaves while the
  markers come, as designed; not a blink of the heat.
- **Scale error**: the map's zoom follows the fingers' spread to 0.02 of a level on average; the largest single
  difference (0.1–0.43 of a level) is at the start of a fast pinch, where MapLibre ignores the first few pixels of
  movement (its gesture threshold). **Anchor drift: 0 dp** in every run (the place under the fingers' middle stays
  under it).

### Tap zooms (`map_tap_zoom`, real touches)
| run | double tap | two-finger tap | + button | − button |
|---|---|---|---|---|
| r1 | 36 zooms, largest step 0.058 | 36, 0.098 | **failed**: 0.306 in one step | – |
| r2 | 36, 0.059 | 31, 0.104 | 54, 0.090 | 50, 0.108 |
| r3 | 36, 0.058 | 29, 0.098 | 48, 0.131 | 47, 0.180 |
| 2,205 capsules | 34, 0.069–0.077 | 30–33, 0.107 | 41–46, 0.140–0.153 | 37–41, 0.155–0.157 |

Every step one level (±0.000), over about 300 ms. **Before** (the owner's recording, animator scale 0): one camera
position per tap, a whole level in one frame. Run 1's + button had one step of 0.31 of a level (a 42 ms gap in the
camera's reports) in the first seconds after the app started; it did not come back (BLOCKERS.md).

### 2,205 capsules
| Flow | janky % | worst ms | >16.7 ms | video gaps ≥100 | frozen ≥150 |
|---|---|---|---|---|---|
| sweep, heat on the UI thread | 2.3 | 20.2 | 1 | 0 | 1 |
| sweep, heat in an isolate (`1c700e2`) | 0.8 | 13.1 | 0 | 0 | 0 |
| wave, heat in an isolate | 0.0 | 7.6 | 0 | 0 | 0 |

### The owner's recording (`owner5.mp4`, before this mission)
8 gaps of 100 ms or more in 92 s (165, 101, 151, 121, 136, 235, 202, 170 ms). At 0:59 the map stands still over
the Warsaw heat with one touch dot, then is at city zoom with bubbles at 1:00, with no frames between; at 1:26 the
heat jumps a level the same way. Both look like the instant tap zooms of DIAGNOSIS.md §9 (animator scale 0); the
Google page's clustering also ran on every camera stop then (now off on MapLibre). Not proven from the video
alone. With the scale back at 1.0, the harness shows no gap of 100 ms or more in any run.

### Tiles
OpenFreeMap answers a vector tile in 60–150 ms (computer and phone, `curl`, Warsaw, zoom 10–14: 2–130 kB). The
blurred frames while zooming in are MapLibre drawing the level it has, scaled, until the next level's tiles arrive
(a fraction of a second on a warm connection); on a cold cache the first zoom into a new area shows them longer.
MapLibre keeps the tiles it drew in its own disk cache (its default size, not changed), which is what made the
offline start work; nothing is prefetched (BLOCKERS.md).

### Cold start (`build/dev/video/m2cold_*.mp4`)
Unchanged: no white frame, streets at the saved place about 1.6 s after the tap, the pins as soon as the capsules
are read.
