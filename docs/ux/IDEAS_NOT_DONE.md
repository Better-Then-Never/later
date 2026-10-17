# IDEAS_NOT_DONE.md: planned or considered, not built in this session

Ordered by value. Each has the data model or backend groundwork noted where it exists.

## Next
- **Loop capsules (F-93)**: several frames played as a loop. Data model, rules (`frames`, `frameDelayMs`), stats and
  the Animator achievement exist; needs the camera burst, upload of frames (Storage rules allow only `image.jpg`
  today: add `frame_<n>.jpg`), and a looping viewer. Hidden by `FeatureFlags.loopCapsules`.
- **Offline capsules (F-26)**: local outbox with the photo, pending state in the list, background upload with
  retry; `capturedAt` already keeps the real moment for streaks.
- **Friend's capsules on their profile (F-54/F-55)**: the section still shows the old placeholder; a query on
  `ownerId == friend` with `privacy in [public, friends]` fits the rules.
- **Camera (F-20..F-23)**: zoom, tap to focus/exposure, flash auto/torch, instant shutter feedback.
- **Own calendar for the open date (F-27)** and a step-by-step composer (F-25, F-28).
- **Chat (F-70..F-76)**: reactions and replies on messages, delete one message, photos, voice notes (would need
  the microphone permission back).
- **Map clusters instead of the heatmap (F-16)** in brand colours; viewport-bounded public queries (F-10 part 2).
- **Co-authored capsules (F-51)**, quick reply from a capsule (F-52), share deep link for a capsule (F-50 part).
- **People from contacts (F-57 part 2)**: opt-in, hashed phone numbers; the `contactSuggestions` privacy switch
  exists in the data model but is not shown.

## Consistency and motion still open
- F-31 History controls (Reset reuses the sort icon; sizes), F-32/F-37 one sheet/dialog system (the comments sheet
  introduces a grab handle; other sheets do not have one yet), F-41 requests toggle vs the notifications tabs,
  F-43 share icon, F-38 Add Friends transition (lazy list after the route), hero transitions for avatars and
  capsule photos, list entrance stagger.

## Tier 3 (not started)
Onboarding tour, "On this day" memories, a friends feed.

## Explicitly not built (mission rules)
Ads, music for capsules, public channels, video circles, web version, payments or subscriptions.
