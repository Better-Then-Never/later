# COLD_START.md: the full map with every capsule, at once (M-06)

Mission of 19 Oct 2026, branch `feature/map-instant-start` (from `fix/map-flash-ghosts-selection` at `c7f3e37`).
Galaxy S20 FE (Android 13, 120 Hz), profile builds against the local emulators (`docs/feel/RIG.md`), the heavy
seed (alice: 102 own capsules, 60 friends, 1,205 visible on the map).

## The rig
`tool/dev/coldstart.sh [launches] [--no-build] [label]` (`VIDEO=1` films launch 1): force-stops the app, launches it
as the home screen does (`am start -W --splashscreen-show-icon`), waits for the frame summary and reads the device
log with `tool/dev/coldstart_report.js`. Every number is **milliseconds from Android's launch of the activity**
(the moment "Displayed" and "Fully drawn" count from; a finger's tap on the icon comes about 0.1 s before it).
- `ttid`: Android's first frame (`am start -W` TotalTime).
- The app's marks (`LATERSTART <name>`, `lib/app/shell/startup_report.dart`, debug and profile builds only):
  `dart` (first Dart line), `run` (runApp), `home` (first frame of the signed-in home), `shell` (first frame of the
  map page with its buttons), `map_created`, `style_native` (MapLibre loaded the style), `images_made` /
  `images_added` (the marker pictures), `style` (our layers added), `streets` (the map idle for the first time: all
  tiles drawn), `data_own` / `data_co` / `data_friends` / `data_public` / `data_all` (each capsule source answered
  once), `pins_first` (the first pins drawn), `full`.
- `full` = **TTFD**: Android's `reportFullyDrawn`, called by the app once the picture holding every source has been
  drawn by the map (the map's next idle after it was sent). FlutterActivity reported "fully drawn" at Flutter's
  first frame, which made Android's TTFD equal to TTID; `MainActivity.onFlutterUiDisplayed` no longer does.
- `jank`: frames whose build or raster took over 8.3 ms, from the first frame to two seconds after `full`, and
  the worst one (`FrameTiming`).

## Baseline (`c7f3e37` plus the marks; `build/perf/coldstart_base.txt`, `coldstart_base_b.txt`)
Medians of 5 launches (TTFD: of 3, once Android's number was fixed). The phone's Firestore cache as the owner had it:
3,727 cached capsules and 468 cached queries, mostly from earlier test seeds.

| ttid | shell | streets | own answered | first pins | all answered | **full (TTFD)** | janky frames |
|---|---|---|---|---|---|---|---|
| 1,113 | 1,198 | 2,856 | 3,675 | 3,883 | 4,327 | **4,262** (4,062–4,938) | 48 of ~200 (worst 38 ms) |

Where the time goes (launch 3 of `base_b`, typical):

| ms | What |
|---|---|
| 0–754 | Android starts the process and Flutter's engine (`dart` at 754) |
| 1,030 | `runApp` (Firebase, settings, fonts in parallel before it) |
| 1,150 | first frame (TTID); the map page's buttons at 1,226 (a saved camera: no wait for it) |
| 1,408 / 1,423 | the native map view created; MapLibre has parsed the style |
| 1,191 → 1,646 | the map controller: marker icons (Google's, unused on MapLibre) 350 ms, then the location |
| 1,423 → 3,172 | **the 107 marker pictures drawn one by one (1.75 s)**, then handed to the map one by one (260 ms) |
| 2,578 | the streets drawn (the map's first idle), our layers not yet added |
| 1,646 → 3,398 | **Firestore answers the first capsule query (1.75 s)**; friends at 3,828, public at 3,909 |
| 3,527 / 4,262 | the first pins drawn; every pin drawn (TTFD) |

What a launch looks like (`build/dev/video/coldstart_base.mp4`, first launch, frames 1/6 s apart): the launch
window in the page grey for about 0.9 s (no logo); the Later logo for one frame; the buttons with the navigation
bar's white pill **empty for one frame**, then its icons; **the empty map behind the buttons for 1.2 s**; the
streets all at once; 1.8 s later the heat and the person (that launch opened zoomed out, in the heat).
