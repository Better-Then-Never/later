# MORNING_SUMMARY.md

**First:** PR #77 (polish) is still waiting for your merge (`gh pr merge 77 --merge`); the overnight work is on top
of it in **draft PR #78**. Do **not** merge #78 yet: merging into `main` publishes a release, and its new features
need the backend deployed first (DEPLOY.md, about 30 minutes incl. creating 13 functions with gcloud).

## What you get when it is live
- Five languages (en, ru, pl, de, es) everywhere, pushes included; a dark theme with a matching dark map.
- Photos and avatars come from a disk cache: no reloading when switching screens or after a restart.
- New users are no longer blocked by five permission screens; microphone and contacts are gone.
- Reactions and comments on capsules, reports, friends-of-friends suggestions, follower counts, verified badge,
  achievements with streaks, announcements you can send (`tools/admin/announce.js`).
- Capsules made without a connection wait on the phone and upload by themselves.
- Chat: swipe a message to reply; hold it to copy or delete it for both.
- Settings: Appearance, Language, Privacy (default visibility, approximate location, read receipts).

## Needs you
1. Deploy rules, indexes, functions, then run the count backfill (DEPLOY.md).
2. Confirm the username "amo b3" for the verified badge (BLOCKERS.md).
3. Add the new data uses to the privacy policy (PRIVACY.md).
4. Look at the screenshots in `docs/ux/after` and the dark palette sheet in `docs/ux/dark_candidates/sheet.png`.

## Health
`flutter analyze` clean · `flutter test` 239 passing · functions 43/43 · rules 55/55 · nothing deployed, no tags,
no version bump, no secrets committed.
