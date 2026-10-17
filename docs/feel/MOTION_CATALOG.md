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
2. **Moves are free; scaling text is not.** Slides and lifts move layers without redrawing them. A *scale* is free
   for pictures, but on Impeller text under a changing scale is drawn again at every new size (its letters go into
   the glyph atlas once per size): the centred card's 96 % → 100 % settle kept the capsule dialog at 3.2 % janky,
   rising alone brought it to 0.6 % (`43a1ffa`). Scale icons and photos, not cards full of text. Small scaled text
   (the 0.97 press on buttons, the count badge, a reaction's pop) costs a few letters each time; not measured
   on its own.
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
| **Centred cards** (menus, confirmations, capsule dialog) | `AppCardRoute` (`lib/shared/widgets/app_sheets.dart`) | card rises from below the screen (no fade: a card-sized opacity layer made the capsule dialog 20 % janky; no settle from 96 %: rule 2); scrim darkens; drag down past a third or a flick closes, else springs back | emphasized in, standard out | no animation |
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
| **Map zoom buttons** | `_ZoomButtons` | native camera animation, one level per tap; the pill rises with the card | emphasized | – |
| **Reactions** | `ReactionBurst` (`lib/shared/motion/reaction_burst.dart`) | when a reaction becomes yours: the emoji grows to 135 % and settles while six painted dots fly out and fade | reveal | nothing |
| **Empty states** | `IdleFloat` | the icon drifts 4 dp up and down for two slow breaths, then rests (a loop would draw forever) | 2 × 2.4 s | still |
| **Pull to refresh** | notifications | Material indicator; listens again from scratch and ends with the first result (also on the empty state) | – | – |
| **Waiting → uploaded** | `CapsuleListTile` | the orange "waiting" pill crossfades (with a slight scale) into the green date; the column resizes | standard | instant |
| **Saving a capsule** | `_SubmitButton` (creation) | the button draws in to a green circle with a spinner, turns into a painted check, the page closes 300 ms later; a failure opens it back | emphasized; fast; slow | no morph, no wait |
| **Camera zoom stops** | `_ZoomStops` | tap eases the zoom to the stop in six steps; the nearest stop shows the exact zoom in yellow | ~150 ms | one step |
| **Camera brightness** | `_ExposureSlider` | appears after a tap to focus, hides 3 s after the last touch | fast fade (small) | instant |
| **Achievements** | `achievements_view.dart` | badges come in one after another (cover in the card colour); progress bars fill from empty; the streak flame swells twice | standard + 35 ms steps; reveal; 4 × slow | still |

## Not built, and why
- **Map marker appear/selection animations, heatmap crossfade, a pulsing user marker.** Markers, the heatmap and
  the user's figure are drawn by Google Maps natively. Animating them means sending new marker or heatmap states
  many times a second, and Google Maps applies every update on Android's main thread, where Flutter's vsync comes
  from: exactly what froze the app for 4–10 s before (PERFORMANCE.md). Clusters regrouping at camera stops is the
  motion the map gets. A Flutter overlay that follows the map would need the camera's projection every frame;
  not attempted (IDEAS_NOT_DONE.md).
- **Unlock moments for achievements** (a celebration when one is earned): part B7 (FEATURES_B.md).
