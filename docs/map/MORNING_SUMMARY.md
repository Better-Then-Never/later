# MORNING_SUMMARY.md: the map engine in one page

Branch `feature/map-engine-smoothness` (local commits, **not pushed, not merged**). Nothing was deployed and nothing
touched production: every check ran on the Galaxy S20 FE (120 Hz) against the local Firebase emulators with the
heavy seed (the signed-in account sees 1,205 capsules). Nothing ran on iOS.

## What changed
- **A second map engine, MapLibre, with OpenFreeMap's tiles** (`FeatureFlags.mapLibre`). **On by default since
  the owner's decision of 19 Oct 2026**; a build goes back to Google Maps with `--dart-define=MAP_LIBRE=false`.
- On MapLibre the heat, the bubbles and the pins are layers of the map, drawn on the GPU. Their look follows the
  zoom every frame, the map groups the capsules itself, and Flutter sends nothing while the fingers move.
- The MapLibre page matches the Google page: card, selected pin with its motion, user position, buttons, compass,
  focus from the list and from notifications, taps, filters, dark style, the saved camera, bubble taps that fit
  their capsules.
- Fixed on the way: "Almost there" over the map after a first Google sign-in (M-07); pins that waited for a later
  data change after a cold start on MapLibre.

## Why MapLibre (numbers: DECISION.md)
Google Maps cannot stop the blinks, whatever feeds it: a tile layer goes blank at every whole zoom level, and a
marker cannot fade. Measured with real touches, the same gestures, 3 runs each:

| Per gesture | Google today | MapLibre (spike) |
|---|---|---|
| Heat layer changes | 3–9 | **0** |
| Heat blinks per sweep | 10–16 | **0–1** |
| Markers added / removed | 490–1,570 | **0** |
| Recording gaps ≥ 100 ms | 1–3 | **0** |
| Answer to a finger | 40–86 ms | **30–53 ms** |
| Flutter frames janky | 0–1.5 % | **0 %** |
| Cold start: streets on screen | about 4.5 s after the tap | **1.4–1.8 s** |

## The acceptance criteria
| Criterion | State |
|---|---|
| No heat removals or blinks during a pinch | met in the spike runs (0 changes, 0–1 blinks) |
| No frame with neither heat nor markers | met: the markers are whole before the heat fades (tested); frames checked by eye |
| A crossfade over a zoom band | met: heat 11.6 → 12.3, markers 11.0 → 11.6, eased |
| Clusters animate | partly: bubbles crossfade when they split or merge (MapLibre's 0.3 s); they do not fly apart |
| No stalls ≥ 100 ms, ≤ 1 % janky | met in the spike runs (0 gaps, 0 %) |
| Readable bubbles, a clear selected pin | met: 17 dp bold counts, three disc sizes; the selected pin larger, raised, with a shadow |
| Cold start: no white, the saved camera, "almost ready" never after the map | met |
| No regressions | 454 tests pass; Google Maps is one build switch away; on MapLibre the satellite look is hidden (owner's call) and the flying capsules are missing (BLOCKERS.md) |

## Not done
- **The final 3-run measurement of the finished page** was stopped twice because the computer ran low on memory
  during the profile build. It was not restarted without you. The criteria above rest on the spike's runs. To run it:
  close other apps, then `bash tool/dev/map_gesture.sh after 3`. The 2,000+ capsule check runs with it.
- iOS is untested.

## Commits on this branch
`f61e6b7` rig · `fc86132` baseline and diagnosis · `1d79f6d` MapLibre spike, real touches · `a9adeec` MapLibre page
at parity · `321a4c3` blockers, wider bubbles · `8426062` M-07 · `1f47e6e` bubble tap · `5a340d0` pins after a cold
start · the docs commit with this file · MapLibre on by default (19 Oct).
