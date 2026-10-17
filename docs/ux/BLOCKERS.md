# BLOCKERS.md: what needs the owner, or could not be verified here

## Needs the owner
1. **Backend deploy** (rules, indexes, 13 new functions, backfill): never run from this session by the mission's
   rules. Order and commands in DEPLOY.md. New functions need the gcloud first-create (the default compute service
   account is gone).
2. **Merging**: PR #77 (polish) is inside this branch; merging PR #78 into `main` publishes a release. Deploy the
   backend first.
3. **Verified usernames**: the list given was "temka_ink, m9, amo b3". Usernames cannot contain spaces, so "amo b3"
   was written as `amob3` in `tools/admin/verified_users.json`. Please confirm the exact username (run
   `node set-verified.js --dry-run ...` first: it reports names that do not exist).
4. **Privacy policy text**: the hosted `privacy.html` should mention reactions, comments, reports, public profile
   stats and topic subscriptions (PRIVACY.md lists the points).
5. **Cyrillic font**: the app font (Inria Sans) has no Cyrillic glyphs, so Russian falls back to the system font
   (visible in titles). "No new fonts" forbids adding one; a font with Cyrillic in the same style would be the fix.

## Not verifiable here
- **iOS**: no Mac in this environment. Info.plist was not changed (microphone/contacts strings remain but are
  unused); permission flows were verified on Android only.
- **Raster on a real device**: the emulator's GPU numbers are not representative (PERFORMANCE.md, D-05).
- **Cloud Functions in the running app**: the local emulator session ran auth, Firestore and Storage only, so
  counters, unlocks and pushes were exercised by the functions test suite (43/43), not end to end. Stats and
  achievements on the emulator screenshots were written by hand to the local emulator.
- **Intermittent save failure (observed once)**: on a memory-starved emulator, the first capsule save after a
  reinstall was denied twice (full and legacy shape), while the identical document passed over REST and three
  later saves passed. Not reproducible; the user sees an error and the retry succeeds. Worth watching after the
  deploy.

## Decisions taken without the owner (reversible)
D-03 dark palette (charcoal), D-07 dark map style without map ID, optional permissions (F-42), contacts and
microphone removed from Android, friends-of-friends instead of a list of strangers (F-57). See DECISIONS.md.
