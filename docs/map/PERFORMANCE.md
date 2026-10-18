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

## After
(to be filled with the same columns)
