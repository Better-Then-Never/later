# IDEAS_NOT_DONE.md: considered, not done (Session A)

| Idea | Why not (yet) |
|---|---|
| Animated map markers (appear, selection), heatmap crossfade, pulsing user marker | Every native marker update runs on Android's main thread, which also drives Flutter's vsync; animating them re-creates the freezes this session removed. A Flutter overlay positioned by the map's projection each frame could do it; it would need projection calls per frame and careful testing. |
| Pre-filling Impeller's glyph atlas | Tried (`56d2fee`) and reverted after an A/B on the phone: glyphs drawn offscreen do not spare the screen's atlas updates (6–9 ms raster frames when a page with new letters opens). Engine-level; revisit with a newer Flutter. |
| A Cyrillic cut of the app font | Would remove ~5 ms from first frames in Russian and the mixed typefaces; "no new fonts" this session (owner decision, BLOCKERS.md). |
| Screen-reader performance | With the accessibility tree built every frame (TalkBack on), the opening flows were 1–7 points jankier (`docs/feel/perf/baseline_semantics_on.md`). Not optimised: reducing semantics nodes on hot pages is its own pass. |
| Snowfall overlay cost | `SnowFallAnimation` draws over every screen from 31 Dec to February; out of season during this session, so not measured on the phone. Measure before the next winter (it animates every frame). |
| Predictive back (Android 14+) | The reference phone runs Android 13. `AppPageRoute` has its own edge swipe; wiring the system's predictive back animation to it needs a 14+ device to verify. |
| Splitting a page's first build over two frames | The first frame of Settings (10–15 ms) could build the visible rows first; deferred because a half-built page sliding in would show, and the remaining cost is mostly text layout. |
| Camera capture faster than ~1.1 s | The time is inside CameraX (`takePicture` with the plugin's defaults). The preview now freezes at the tap, so the moment is caught at once; a faster pipeline would need a plugin fork or a lower capture resolution. |
| Hidden tabs building their lists at startup | The slowest startup frame (41.9 ms) is My capsules and Messages laying out their rows when their data arrives about a second after launch, while the map is shown. Building a tab only on its first visit would remove it, but moves that cost to the first tab switch (measured in tab_switches); spreading the rows over several frames is the better fix and was not done. |
| Pressed buttons and badges that scale text | On Impeller a changing scale re-draws text at each size (MOTION_CATALOG rule 2). The card settle was removed (measured); the 0.97 press, the badge pop and the reaction pop scale only a few letters and were not measured on their own. |
| Save buttons above the keyboard | The name and username pages keep Save in a bottom bar, under the keyboard while typing (the new About page puts it under the field). Same fix there, not done to keep B3 small. |
| Search by last name | Needs a word index (`nameWords` array) and an `array-contains` query; the prefix on the whole name covers most searches. |
| Co-authors on the small map card | The opened capsule names them; the map's info panel has no room without a redesign. |
