# MOTION_CATALOG.md: every motion in Later, and the rules behind it

Tokens (`lib/core/theme/app_motion.dart`): quick 100, fast 150, standard 200, emphasized 250, slow 300, reveal 350 ms;
curves `enter` (ease out), `exit` (ease in), `standardCurve`, `emphasizedCurve`. `AppMotion.reduced(context)` is the
phone's "remove animations" setting; every motion below honours it (instant, or a still equivalent).

## Rules learned on the phone (docs/feel/PERFORMANCE.md)
1. **No opacity on anything large.** On Impeller an `Opacity`/`FadeTransition` draws its subtree offscreen on every
   frame of the fade: a page-wide fade cost 10–13 ms of raster per frame. Fade by painting instead:
   `TintPainter` (`lib/shared/motion/tint_painter.dart`) covers a widget with its background colour and thins the
   cover (looks identical over a plain background), or dims with a scrim. Opacity is fine on small things (a button,
   a card).
2. **Transforms are free**: slides, scales and lifts move layers without redrawing them.
3. **Nothing heavy at the start of a motion.** The first frame of a page builds it; keep that frame light (no
   `ListTile` intrinsic layouts, no per-row `ThemeData`), and never send native views (the map) a burst of updates
   mid-animation.
4. **Interruptible.** Route animations reverse from where they are; gestures drive the same controllers.
5. **Short.** Nothing longer than `reveal` (350 ms) except continuous feedback.

## Catalogue
| Motion | Where | How | Duration / curve | Reduced motion |
|---|---|---|---|---|
| **Page push/pop** | `AppPageRoute` (`lib/app/router/app_page_route.dart`), all pages | new page slides in from the right; the page under slides 25 % left and dims (painted scrim); 12 dp gradient shadow on the new page's edge | emphasized in, standard out; `emphasizedCurve` / `standardCurve` | no animation |
| **Back swipe** | same, horizontal pages | drag from the left 24 dp follows the finger (linear), pops past half the width or on a flick (> 1 width/s), else springs back; blocked by `PopScope(canPop: false)` | finger-driven | swipe still pops (no follow motion) |
| **Sheet-like pages** | camera, Add friends (`appSheetRoute`) | rise from the bottom over a painted scrim | emphasized / standard | no animation |
| **Tabs** | `TabStack` (`lib/app/shell/tab_stack.dart`) | incoming tab rises 6 dp out of the page background (cover thins); hidden tabs' tickers off | fast, `enter` | instant |
| **Centred cards** (menus, confirmations, capsule dialog) | `AppCardRoute` (`lib/shared/widgets/app_sheets.dart`) | card rises 24 dp and grows from 92 %, card-only fade; scrim fades; drag down past a third or a flick closes, else springs back | emphasized in, standard out | no animation |
| **Edge sheets** (lists, threads) | `showEdgeSheet` | Material bottom sheet with the app tokens; drag down closes | emphasized / standard, `emphasizedCurve` | no animation |
| **Photo viewer** | `PhotoViewer.show` | the photo flies as a `Hero` from the capsule card or the creation page; black behind it is painted in; Back button fades alone; drag up/down closes with the black thinning | emphasized / standard | no animation |
| **Theme, language, size switch** | `AppearanceCrossfade` (`lib/app/appearance/`) | a still of the old screen fades out over the new one (one rebuild under it) | slow, `standardCurve` | instant |
| **New rows / messages** | `AppEnter`, `AppStaggerItem` | row lifts 15 % of its height while a background-coloured cover thins (no opacity); first 10 rows of a fresh list 35 ms apart | standard, `enter` | shown at once |
| **Camera shutter** | `camera_page.dart` | white blink over the preview, and the preview **holds still** (a still of its last frame) until the photo is ready | blink 120 ms | blink only |
| **Camera focus ring** | `_FocusRing` | shrinks from 125 % in 40 % of the time, holds, fades through its border colour | reveal (350 ms) | still ring for 350 ms |
| **Toasts** | `PopupNotification` | slide + fade (small) | slow | appear and leave at once |
| **Count badge** | `CountBadge` | scales in on first appearance | standard, `enter` | instant |
| **Button press** | `AppPressable` | scales to 0.97 while pressed | quick | none |
| **Map card** | `map_page.dart` | fade + slide of the card (small) | emphasized | instant |
| **Map clusters** | `map_clusters.dart` | bubbles regroup when the camera stops (no motion while it moves) | – | – |

## Not built yet (Phase 3 list, tracked in PROGRESS.md)
Reaction bursts, marker appear/selection, heatmap crossfade, pulsing user marker, creation steps, pending →
uploaded morph, achievement unlock and streak flame, pull to refresh that works, empty-state idle motion.
