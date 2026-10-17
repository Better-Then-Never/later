# IDEAS_NOT_DONE.md: planned or considered, not built in this session

Ordered by value. Each has the data model or backend groundwork noted where it exists.

## Next
- **Loop capsules (F-93)**: several frames played as a loop. Data model, rules (`frames`, `frameDelayMs`), stats and
  the Animator achievement exist; needs the camera burst, upload of frames (Storage rules allow only `image.jpg`
  today: add `frame_<n>.jpg`), and a looping viewer. Hidden by `FeatureFlags.loopCapsules`.
- **Offline capsules, next steps**: a capsule for a friend still needs the connection (its chat post is made at
  once); a "not sent" state with a manual retry for capsules the server refused three times.
- **Camera (F-23)**: flash auto/torch (needs artwork for the extra states; zoom, focus and shutter feedback are
  done).
- **Own calendar for "Pick a date…" (F-27; the presets cover the common cases)** and a step-by-step composer (F-25, F-28).
- **Chat (F-70..F-76)**: reactions on messages, tapping a quote to jump to the original, photos, voice notes (would need the microphone
  permission back); "deleted" placeholders instead of removing (needs a sender-only update rule); lowering the
  friend's unread count when an unread message is deleted (rules allow only +1 from the sender today).
- **Map clusters instead of the heatmap (F-16)** in brand colours; viewport-bounded public queries (F-10 part 2).
- **Co-authored capsules (F-51)**, quick reply from a capsule (F-52), share deep link for a capsule (F-50 part).
- **People from contacts (F-57 part 2)**: opt-in, hashed phone numbers; the `contactSuggestions` privacy switch
  exists in the data model but is not shown.

## Consistency and motion still open
- F-31 history control sizes (the Reset icon is fixed), F-43 share icon (no artwork besides the paper plane),
  hero transitions for avatars and capsule photos (tags must stay unique per route; the capsule dialog is not a
  page route, so it needs its own transition), list entrance stagger.

## Tier 3 (not started)
Onboarding tour, "On this day" memories, a friends feed.

## Explicitly not built (mission rules)
Ads, music for capsules, public channels, video circles, web version, payments or subscriptions.
