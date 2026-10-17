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
| animator | stats.loopCapsules | 1, 10 | animation (hidden: loop capsules are not built, `FeatureFlags.loopCapsules`) |
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
`AchievementIcon`: the Material symbol on a round plate, with a ring of as many segments as levels; filled
segments show the level. Plate colours by level: brand green, info blue, warning orange, danger red, place yellow
(existing accents only). Locked: grey.

## Adding an achievement
1. `functions/lib/gamification.js`: add to `ACHIEVEMENTS` (id, metric, tiers, icon, titles in 5 languages) and make
   sure something writes the metric; add a test in `functions/test/gamification.test.js`.
2. `lib/features/achievements/achievement_catalog.dart`: same id, tiers and metric; the catalog test compares ids and
   tiers with the server list.
3. `tool/l10n/fragments/achievements/*.json`: `achievement<Name>` and `achievement<Name>Goal` in all five languages.
4. `dart run tool/l10n/build_arb.dart && flutter gen-l10n`, run the tests.
