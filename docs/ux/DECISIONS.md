# DECISIONS.md: non-obvious decisions and why

## Foundation
**D-01 Localization from per-area fragments.** `tool/l10n/fragments/<area>/<lang>.json` are the source; a script
assembles `lib/l10n/app_<lang>.arb` for gen-l10n. Parallel work on different features never edits the same file,
and a test fails when any language misses a key or a placeholder. Widgets use `context.l10n`; code without a
context (failures, controllers) uses `AppL10n.current`, which `LaterApp` keeps on the app's language.

**D-02 Dark icons by asset swap, not tint.** The hand-drawn icons have black strokes, white fills and colour dots;
tinting would flatten them. `tool/make_dark_icons.dart` inverts only achromatic pixels (black stroke becomes
light, white fill dark) and keeps colours; white icons drawn over photos get no variant. `ThemedAssetBundle`
serves the variants through `DefaultAssetBundle`, so no `Image.asset` call changes. Contact sheet:
`icons_light_dark.png`.

**D-03 Dark palette: charcoal.** Three candidates (`AppPalette.darkCharcoal`, `darkForest`, `darkSlate`) were
rendered on the emulator on the map, history, messages and profile tabs (`docs/ux/dark_candidates/sheet.png`: rows
charcoal, forest, slate; repeat with `--dart-define=DARK_PALETTE=forest|slate`). Charcoal wins: the app's colour
lives in its illustrations, capsule colours, pills and the brand green, and a neutral grey keeps all of them true.
Forest's green tint makes green avatars, green pills and the green nav icon sink into the surface; slate's cool cast
fights the warm yellow and orange pills and flattens the blue profile header. The dark map style (D-07) is neutral
too, so charcoal continues it without a seam.

**D-07 Dark map.** The light map keeps the owner's cloud style (map ID). Cloud styles on Android have no dark
variant in google_maps_flutter (`colorScheme` is web-only), so in dark mode the map is created without the map ID and
with a local JSON style (`lib/features/map/map_styles.dart`) that follows the light one: blue water, green parks,
quiet roads, no business POIs. A theme change recreates the map at the same camera position. Mobile map loads cost
the same either way. The map now has padding for the floating navigation bar, so the Google logo and toolbar stay
visible above it; the zoom buttons, which were hidden under the bar, are off (pinch zooms).

**D-04 UI size scales the whole interface.** Most sizes are fractions of the screen, so a text-size setting alone
would leave icons and cards unchanged. `UiScaleView` lays the app out on a virtual screen of `size / scale` and
paints it scaled (crisp, touches mapped through the transform). Small 0.9, standard 1.0, large 1.12.

**D-05 What the emulator can measure.** Raster time on this emulator is ~110 ms per frame for any screen with both
Impeller and Skia, so only UI-thread build times are used as budgets here; device raster is a manual check.

**D-06 Launch = first frame.** Native splash (page background + logo at 132 dp) on Android 6-15 and the
Android 12 splash API, the window background behind Flutter is the same picture, and the first Flutter frame
(`SplashLogo`) draws it again: no white flash, no jump.

## Backend (additive, old app versions keep working)
**D-10 Settings document grows, never breaks.** `users/{uid}/settings/app` gains `language` and notification
categories `friendRequests`, `reactions`, `comments`, `achievements`, `news` (default on) and `streakReminder`
(default off). Missing fields mean the defaults, on the client and in `functions/lib/prefs.js`.

**D-11 Pushes are localized on the server** by the recipient's stored `language` (`functions/lib/i18n.js`,
English fallback). The app writes its language to the settings document when it changes.

**D-12 Reactions:** `capsules/{id}/reactions/{uid}`, one per person (document id = uid, so a retry or a second
tap cannot duplicate), six playful types. Counts live on the capsule (`reactionCounts`, `reactionTotal`), kept by
a function with `FieldValue.increment`: lists never count documents.

**D-13 Comments:** `capsules/{id}/comments/{id}` with at most one level of replies (`replyTo` must point at a
top-level comment), 1-500 characters, deleted by their author or the capsule owner, never edited. `commentCount`
on the capsule is kept by a function. Comments and reactions respect capsule visibility, the capsule's
`allowComments` / `allowReactions`, and blocks (rules).

**D-14 Counters are server-owned.** `followerCount`, `followingCount`, `stats.*` (streaks, totals) and `verified`
are written only by functions or admin scripts; the user rules list the keys a client may change, so clients can
never set them (rules tests prove it).

**D-15 Streaks use the capture day.** A capsule carries `capturedAt` and the device's `utcOffsetMinutes`; the
streak day is the local date of the capture, accepted when the capture is at most 48 h old on arrival (offline
capsules from the mountains count, back-dating does not). Days earlier than the last streak day do not change
the streak.

**D-16 Achievements are data.** One registry (`functions/lib/achievements.js`): id, metric, tiers, icon key.
Functions update metrics and unlock tiers idempotently (`users/{uid}/achievements/{id}` keeps the highest tier),
then write an in-app notification and push. The app shows them with `AchievementIcon`
(`assets/achievements/<id>.png` if present, else a Material placeholder icon). "Explorer" counts distinct
~5 km places (geohash cells) and "Traveler" the distance between consecutive capsules: no geocoding API needed.

**D-17 Announcements:** an admin-only callable (`request.auth.token.admin == true`) writes
`announcements/{id}` (readable by everyone signed in, shown in the notifications tab) and sends one topic push per
language (`news_<lang>`), optionally limited to a platform (`platform_android` / `platform_ios` topic conditions).
No per-user fan-out, so the cost does not grow with the user base.

**D-18 Reports go to a write-only collection** `reports/{id}` (reporter, target path, reason); nobody can read it
from the app; the owner reviews them in the console.
