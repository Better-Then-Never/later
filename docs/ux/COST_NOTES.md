# COST_NOTES.md: what the new features cost to run

Prices are not quoted (they change); counts are per action so they can be multiplied by usage. "Read/write" are
Firestore document operations; "invocation" is a Cloud Functions call.

## Client
| Feature | Reads | Writes | Notes |
|---|---|---|---|
| Photo disk cache (F-01/F-02) | – | – | **Saves** Storage egress: a photo is downloaded once per device instead of on every screen visit; avatar URLs are remembered (fewer `getDownloadURL` calls). |
| Language sync | 0 | 1 per language change (and once per account) | settings doc |
| Privacy / notification settings | 0 | 1 per change | |
| Reactions on an open capsule | 1 query (≤100 docs) while the dialog is open, plus live changes | 1 per tap | counts come from the reactions themselves below 100 |
| Comments | 1 query (≤200 docs) while the sheet is open | 1 per comment / delete | |
| Achievements panel/page | 1 query on `users/{uid}/achievements` (≤12 docs) | 0 | stats ride on the user doc already loaded |
| Friends of friends (F-57) | ≤2 batched `whereIn` lookups (≤30 + ≤20 profiles), mostly already in the directory | 0 | replaces a 50-document query of strangers |
| News topics | 0 | 0 | FCM topic subscribe/unsubscribe calls only |
| Offline capsules (F-26) | 1 `get` per attempt (the idempotency check) | the normal capsule write once | retries only while something waits (sign-in, resume, every minute); a refused capsule uploads its photo again on each attempt, so it stops after 3 per sign-in |
| Deleting a chat message | 1 query (2 newest messages) | 1 batch: the delete, plus the summary when it was the newest | |
| Dark map | – | – | the dark style is local; mobile Maps SDK loads are not billed per load |

## Cloud Functions (per event)
| Function | Invocations | Reads | Writes |
|---|---|---|---|
| countFollower*/countFollowing* | 1 per follow/unfollow (×2: both sides) | 0 | 1 |
| onReactionWritten | 1 per reaction change | 1 capsule (+ settings, blocked check, tokens for the push on a first reaction) | 1 counter (+1 stat, +1 in-app notification) |
| onCommentCreated/Deleted | 1 per comment | capsule, parent comment, settings/tokens per recipient | counter, stat, notification per recipient (≤2) |
| onFriendRequestCreated/Updated | 1 per request change | settings, tokens | notification (+ stats on accept) |
| updateCapsuleStats | 1 per new capsule | user + private doc (transaction) | 1-2 |
| unlockAchievements | **1 per update of any user document** | 0 when no threshold is crossed (the common case: the before/after docs come with the event) | 1 per unlocked level (+ notification) |
| sendStreakReminders | 24 per day | one collection-group query over the opted-in settings docs (only users who turned the reminder on), +1 user doc each | notifications to those whose streak ends tonight |
| sendAnnouncement | per announcement (admin only) | 0 | 1 announcement doc; FCM topic sends are free |

`unlockAchievements` is the one to watch: it runs on every `users/{uid}` write (profile edits, favourites,
friend changes, counter increments). Each run returns early without reads when no threshold is crossed, so it
costs invocations, not reads. If invocation counts matter, a later optimisation is to unlock from the stats
writers directly (they already know the new values) and drop the trigger.

## Storage
No new files yet (loop frames and thumbnails are not built). The disk cache lowers egress.

## Push (FCM)
Free. The new categories add pushes only for users who keep them on; quiet hours and the master switch apply.
