# MIGRATIONS_NEEDED.md

No document has to be rewritten: every change is additive and every reader accepts the old shapes. What the
owner should run, and why (commands in DEPLOY.md):

| Step | Why | Tool | Required? |
|---|---|---|---|
| Deploy rules + indexes | new fields, subcollections (reactions, comments, achievements, private, reports, announcements), settings keys | `firebase deploy --only firestore` | yes, before the app |
| Create + deploy functions | counters, notifications, stats, achievements, streak reminders, announcements | gcloud first-create, then `firebase deploy --only functions` | yes |
| Backfill counts | `followerCount`, `followingCount`, `stats.capsules`, `stats.publicCapsules` only move from the deploy on; existing accounts would show 0 | `tools/admin/backfill-counts.js` | recommended |
| Admin claim | only `admin: true` users may call `sendAnnouncement` | `tools/admin/set-admin.js` | for announcements |
| Verified users | the badge is written only by the admin script | `tools/admin/set-verified.js` | optional |

## Data that starts fresh (not rebuilt)
- Streaks (`stats.streakCurrent/Longest/LastDay`): need the capture day of every capsule in the user's time zone;
  old capsules have no `capturedAt`/`utcOffsetMinutes`. They start at the first capsule after the deploy.
- Places and distance (`stats.places`, `stats.distanceKm`, `users/{uid}/private/gamification`): built from new
  capsules only.
- Achievements: unlock as soon as the user document changes after the backfill (the backfill itself is an update,
  so `unlockAchievements` runs for every changed user and unlocks e.g. "Collector" from the counted capsules).

## New fields and documents (all optional)
- `users/{uid}`: `followerCount`, `followingCount`, `verified`, `showAchievements`, `stats.*` (server-written except
  `showAchievements`).
- `users/{uid}/settings/app`: `notifications.{friendRequests, reactions, comments, achievements, news,
  streakReminder}`, `privacy.{defaultVisibility, readReceipts, locationPrecision, contactSuggestions}`, `language`.
- `users/{uid}/achievements/{id}`, `users/{uid}/private/gamification` (server only).
- `capsules/{id}`: `capturedAt`, `utcOffsetMinutes`, `showAuthor`, `allowComments`, `allowReactions`,
  `locationPrecision`, `frames`, `frameDelayMs`, `thumbUrl`, `placeName` (client, optional), `reactionCounts`,
  `reactionTotal`, `commentCount` (server).
- `capsules/{id}/reactions/{uid}`, `capsules/{id}/comments/{id}`, `reports/{id}`, `announcements/{id}`.
- In-app notification types: `reaction`, `friendRequest`, `friendAccepted`, `achievement`, `comment`, `reply`
  (the app of this branch renders them; older apps show them as a generic notification).

## Account deletion
`cleanupDeletedAccount` now also deletes the user's reactions and comments on other people's capsules
(collection-group queries on `reactions.uid` / `comments.authorId`, indexed by the field overrides).

## Client compatibility
- The app retries a rejected capsule save once without the new fields, and a rejected notification-settings
  save with the old keys only, so it can ship before the rules (DEPLOY.md, "Compatibility").
- Android manifest: `READ_CONTACTS` removed, the camera plugin's `RECORD_AUDIO` removed at merge time.
