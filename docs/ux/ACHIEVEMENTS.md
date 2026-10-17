# ACHIEVEMENTS.md

Achievements are unlocked by the server only (`functions/lib/gamification.js`, `unlockAchievements`), never by the
app and never by paying. The app shows them (`lib/features/achievements`), with the level taken as the higher of
the server's unlock document and the user's stats.

## Registry
| Id | Metric (`users/{uid}`) | Levels | Icon (Material) |
|---|---|---|---|
| first_capsule | stats.capsules | 1 | photo_camera |
| collector | stats.capsules | 5, 25, 100, 500 | collections |
| open_book | stats.publicCapsules | 1, 10, 50 | public |
| animator | stats.loopCapsules | 1, 10 | animation (hidden while loop capsules are behind `FeatureFlags.loopCapsules`: built, not switched on) |
| streak | stats.streakLongest | 3, 7, 14, 30, 100 | local_fire_department |
| explorer | stats.places (≈5 km cells) | 3, 10, 25, 100 | explore |
| traveler | stats.distanceKm between consecutive capsules | 100, 1000, 10000 | flight_takeoff |
| crowd_pleaser | stats.reactionsReceived | 10, 100, 1000 | favorite |
| chatterbox | stats.commentsWritten | 1, 25, 100 | chat_bubble |
| friendly | friends (array length) | 1, 10, 50 | group |
| night_owl | stats.nightCapsules (00:00-05:00 local) | 1, 10 | nightlight |
| early_bird | stats.morningCapsules (05:00-08:00 local) | 1, 10 | wb_twilight |

## Streak
A day counts when a capsule is **captured** that day in the user's local time (`capturedAt` + `utcOffsetMinutes`
of the capsule), within 48 h of the capture (offline capsules uploaded later still count). The streak continues
when the previous counted day was yesterday. The app shows it until a whole day passes without a capsule
(`UserStats.streakAt`). Opt-in evening reminder at 19:00 local when the streak would end tonight
(`sendStreakReminders`, hourly).

## Unlocking
`unlockAchievements` compares the metrics before and after every `users/{uid}` update and writes
`users/{uid}/achievements/{id}` with the highest level reached (in a transaction, once per level), then sends the
"achievement" push and in-app notification (category `achievements`).

## Badge
`AchievementIcon`: the symbol on a round plate, with a ring of as many segments as levels; filled segments show
the level. Plate colours by level: brand green, info blue, warning orange, danger red, place yellow (existing
accents only). Locked: grey.

**Artwork.** The symbol is `assets/achievements/<id>.png` when that file exists (for example
`assets/achievements/collector.png`), else the Material icon of the table above. Adding artwork needs no code: drop
the PNG in (square, transparent background, at least 144 px so it is sharp at 3x), rebuild. A locked badge tints it
grey. Which files exist is read from the asset manifest once at startup (`AchievementIcon.preloadArt`). SVG artwork is
not supported: it would need the flutter_svg package, which is not a dependency (export PNGs instead). Tested in
`test/features/achievement_art_test.dart`. (Before Session A this override was described in D-16 but not built.)

## Adding an achievement
1. `functions/lib/gamification.js`: add to `ACHIEVEMENTS` (id, metric, tiers, icon, titles in 5 languages) and make
   sure something writes the metric; add a test in `functions/test/gamification.test.js`.
2. `lib/features/achievements/achievement_catalog.dart`: same id, tiers and metric; the catalog test compares ids and
   tiers with the server list.
3. `tool/l10n/fragments/achievements/*.json`: `achievement<Name>` and `achievement<Name>Goal` in all five languages.
4. `dart run tool/l10n/build_arb.dart && flutter gen-l10n`, run the tests.
