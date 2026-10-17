# IDEAS_NOT_DONE.md: planned or considered, not built in this session

Ordered by value. Each has the data model or backend groundwork noted where it exists.

## Next
- **Loop capsules (F-93)**: several frames played as a loop. Data model, rules (`frames`, `frameDelayMs`), stats and
  the Animator achievement exist; needs the camera burst, upload of frames (Storage rules allow only `image.jpg`
  today: add `frame_<n>.jpg`), and a looping viewer. Hidden by `FeatureFlags.loopCapsules`.
- **Offline capsules, next steps**: a capsule for a friend still needs the connection (its chat post is made at
  once); a "not sent" state with a manual retry for capsules the server refused three times.
- **Camera (F-23)**: torch while framing (flash auto is done; zoom, focus and shutter feedback too).
- **Own calendar for "Pick a date…" (F-27; the presets cover the common cases)** and a step-by-step composer (F-25, F-28).
- **Chat (F-70..F-76)**: photos, voice notes (would need the microphone
  permission back); "deleted" placeholders instead of removing (needs a sender-only update rule); lowering the
  friend's unread count when an unread message is deleted (rules allow only +1 from the sender today).
- **Map clusters instead of the heatmap** (the heatmap is restyled, D-19; brand-coloured cluster icons need plugin support); viewport-bounded public queries (F-10 part 2).
- **Co-authored capsules (F-51)**, quick reply from a capsule (F-52), share deep link for a capsule (F-50 part).
- **People from contacts (F-57 part 2)**: opt-in, hashed phone numbers; the `contactSuggestions` privacy switch
  exists in the data model but is not shown.

## Consistency and motion still open
- F-31 history control sizes (the Reset icon is fixed), F-43 share icon (no artwork besides the paper plane),
  hero transitions for avatars and capsule photos (tags must stay unique per route; the capsule dialog is not a
  page route, so it needs its own transition); the stagger for the tab lists (they are built in the background at
  start; it would need to run when the tab is first shown).

## Tier 3 (not started)
A longer onboarding tour (the first-capsule card is done), a friends feed; "On this day" as a morning push (the in-app strip is done; a push needs a
scheduled function per time zone).

## Explicitly not built (mission rules)
Ads, music for capsules, public channels, video circles, web version, payments or subscriptions.
