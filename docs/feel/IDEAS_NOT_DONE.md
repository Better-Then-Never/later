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
