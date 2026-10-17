# REPORT.md: overnight UX, design consistency and features

Branch `feature/ux-features-night-session` (draft PR #78, **do not merge before the backend deploy**, DEPLOY.md).
Based on the polish branch (PR #77), which it contains.

## In one paragraph
Later now speaks five languages end to end (screens and pushes), has a real dark theme including a dark map,
loads photos from a disk cache (no reloading after navigation or restarts), no longer blocks new users behind five
permission screens, and gains the first social layer: reactions and comments on capsules, reports, friends-of-friends
suggestions, follower counts, a verified badge, achievements with streaks, and announcements from the team. The
backend for all of it is written, tested and additive, but not deployed (mission rule); the app tolerates the old
backend until it is.

## What was done
**Foundation.** Translation pipeline (fragments per area → ARB → gen-l10n, completeness tests); every screen
converted (eight areas in parallel worktrees, merged); data-layer strings localized; `AppPalette` for everything
theme-dependent (`AppColors` keeps only invariant colours); dark icon set; Appearance (theme, UI size) and Language
pages; edge-to-edge bars and a splash that is the first frame; dark palette chosen from three on-device candidates
(D-03, charcoal); dark map style (D-07).

**Feel.** Disk image cache with shared decode sizes and skeleton placeholders; remembered avatar URLs; chats reopen
instantly; map markers and heatmap rebuilt only when capsules change; capsule card that always closes; Google logo
never covered; my-location button; pinned headers; round list avatars; labelled navigation tabs; profile scrolls.

**Fixes found on the device.** Russian labels cut off (shortened); camera failed on first use after the optional
onboarding (asks for the permission first now); creation header scrolled under the status bar; the user's figure
vanished on the dark map; comments sheet went under the status bar with the keyboard; the info panel overflowed by
2 px and its locked button was unreadable.

**Features.** Reactions, comments (one level of replies), reports; a friend's capsules on their profile; camera
pinch zoom, tap to focus and instant shutter feedback; offline capsules (kept on the phone, uploaded when the
connection is back); per-capsule comment/reaction/approximate-location
switches and privacy defaults; read receipts honoured both ways; friends-of-friends suggestions (replacing a list of
the app's first 50 users, a privacy problem); follower counts and verified badge; achievements and streak on
profiles; new notification types and categories; topic subscription for announcements; admin scripts (admin claim,
verified badge, announcements, count backfill).

**Backend (not deployed).** 13 new functions (counters, reactions, comments, friend requests, stats, achievements,
streak reminders, announcements), localized pushes, rules for every new document, indexes; account deletion also
removes the user's reactions and comments; deleting a chat message puts the previous one back in the chat summary
(`isUndo`); messages may quote the one they answer (`replyTo`). Functions 43/43, rules 55/55.

## Numbers
Flutter tests 241 passing (1 pre-existing skip); analyze clean; design tokens clean; profile-mode flows in
PERFORMANCE.md (build p90 within a frame except first builds of tabs/pages at 17-18 ms).

## Decisions (DECISIONS.md)
D-03 charcoal dark palette; D-07 dark map without the cloud map ID; optional permissions; contacts and microphone
removed from Android; friends-of-friends suggestions; feature flags for anything not finished (loop capsules).

## Not done (IDEAS_NOT_DONE.md)
Loop capsules, flash auto/torch, own date picker and composer, chat reactions/replies/photos/voice,
map clusters, co-authors, some consistency items (history control sizes, share icon) and
transition polish (hero, stagger).

## Read next
MORNING_SUMMARY.md (what to do first), DEPLOY.md, BLOCKERS.md, FEATURES.md, TEST_REPORT.md, FEEL_QA.md,
PRIVACY.md, COST_NOTES.md, ACHIEVEMENTS.md, MIGRATIONS_NEEDED.md, COMPONENTS.md, PROGRESS.md (log).
