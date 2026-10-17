# PLAN.md: ordered work list

Feel beats feature count: each item is finished and verified (tests, screenshots, timings) before the next.
Status lives in PROGRESS.md; findings in AUDIT.md (F-xx).

## Tier 0: foundation
1. Infrastructure: l10n tooling, palette + dark icons, appearance controller, UI scale, perf harness. **done**
2. Edge-to-edge system bars, splash = first frame (F-33). **done**
3. Conversion of every feature folder to the palette and five languages (8 areas, parallel worktrees), then
   the data layer; remove theme-dependent members from `AppColors`.
4. Dark palette decision: three candidates rendered on map, profile, chat, settings, capsule (DECISIONS D-03).
5. Settings > Appearance: theme (system/light/dark), language, UI size (F-83, F-84, F-87); language synced to the
   account for localized pushes.
6. Images (F-01..F-03): persistent disk cache keyed by storage path, decode sizes from layout × DPR, thumbnails,
   avatar URLs persisted, shaped placeholders; chat keeps its last messages (no spinner on re-entry).
7. Consistency (F-30..F-45): one sheet/dialog system (grabber, title hierarchy, filled bottom, stacking), one
   header spec on the real status-bar inset, nav pill lower, history controls on the shared scale, fixed-size
   avatars (no ListTile clamp), one segmented control (requests = notifications style), gradient placeholders,
   share icon, overflow fixes, profile sections and empty states.
8. Motion (F-38, F-45): add-friends transition (lazy list, load after the route), hero avatars and capsule
   images, list entrance stagger, sheet motion, state morphs; re-measure.

## Tier 1: core experience
9. Map (F-10..F-19): position out of the map rebuild, memoized markers, padding for compass/zoom/logo,
   my-location button, own dismissible capsule card, JSON style light/dark in brand greens, density clusters
   instead of the heatmap, invalid-coordinate guard (client + rules), filters (mine/friends/public).
10. Camera (F-20..F-23): zoom (pinch + stops), tap to focus + exposure, flash off/auto/on/torch, instant
    shutter feedback, preview without distortion; measure tap-to-file.
11. Creation (F-24, F-25, F-27..F-29): last-known location first + async place name + manual pin, own calendar,
    modern composer, capsule settings (visibility, show author, comments, reactions, location precision),
    draft autosave, description limit bug.
12. Offline capsules (F-26): local outbox, pending state, background upload with retry and idempotent ids.
13. Notifications (F-75): new events (friend request received/accepted, reactions, comments, achievements,
    streak reminder), localized pushes, admin broadcast, in-app tab grouped by day with inline actions, badges.
14. Chat (F-70..F-76): reactions, reply, delete, image messages + viewer, voice messages; group chats and
    stickers behind flags if they cannot be finished and verified.
15. Settings (F-80..F-88): privacy (who can message/find me, read receipts, default visibility), map and media.

## Tier 2: social and gamification
16. Follower counts (server counters), verified badge (server-controlled), profile redesign with sections,
    friend capsules widget, pinned/recent friends with quick actions (F-53..F-58).
17. People search entry point + suggestions (friends of friends; contacts opt-in with hashing) (F-57).
18. Capsule detail: reactions, comments, share deep link, quick reply, report (F-50, F-52, F-60).
19. Co-authored capsules (F-51).
20. Streaks, achievements registry with `AchievementIcon`, exploration summary (F-90..F-92).
21. Loop capsule (F-93).

## Tier 3 (only if 0-2 are verified)
Onboarding, "On this day", friends feed — see IDEAS_NOT_DONE.md otherwise.
