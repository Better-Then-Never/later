# MORNING_SUMMARY.md: the full map with every capsule, at once (M-06)

Branch `feature/map-instant-start` (from `fix/map-flash-ghosts-selection`; local commits, **not pushed, not
merged**). Nothing deployed, no production data touched: every check ran on the Galaxy S20 FE against the local
emulators. Mission 3's summary is in git history (`4ff4829`). Details and every number: COLD_START.md.

## What you will see now
| After tapping the icon | Before | Now |
|---|---|---|
| 0 to 1.2 s | a plain grey screen | the map's own colour (light or dark), with the Later logo |
| 1.3 s | buttons over an empty map (1.7 s) | the buttons and the tab bar, all icons in one frame |
| about 2.2 s | streets at 2.7 s, no pins | the streets fade in where you left the map, and **every pin and bubble grows in from the middle, in one motion** |
| afterwards | pins at 5.2 s, then friends', public ones and regrouping until 7.2 s | nothing moves unless a capsule really changed (a new one grows in, a deleted one shrinks away) |

## How
- The phone keeps the pins the map last showed (only what a pin needs: place, colour, owner, opening time; never a
  title or photo), per account, deleted at sign-out. A start draws them at once; Firestore's answers then replace
  them, so a deleted or hidden capsule goes about a second later and a removed friend's pins never show.
  Tapping a pin from that moment opens the capsule as the server has it now.
- The 107 marker pictures are kept on the phone (they took 1.75 s to draw at every start), the map no longer waits
  for the GPS, and it asks for the capsules first.
- Firestore's cache on the phone was emptied once (3,727 capsules of old test data) and is bounded.
- Measured (median of 5 launches, from Android's launch): **full map 2.15 s** (was 4.26 s; your phone's 5.2 to 7.2 s
  from the tap); first start after sign-in 3.4 s, after clearing the app's data 4.0 s (in one reveal); offline,
  dark and "remove animations" checked. Janky frames during the start: 48 → 9.

## Waiting for you
- **Delta sync is built but off.** It makes a start read only the friends' and public capsules that changed
  (today it re-reads all of them: 1,114 for the test account; Firestore bills them whenever a listener was away
  for over 30 minutes). It needs a small backend change: a function that records deleted capsules, its rules, four
  indexes and a 30-day TTL. Tested on the emulators; **deploy it, then switch the flag on** (exact steps in
  COLD_START.md, "Delta sync").
- **Prefetching map tiles is not allowed** by OpenFreeMap's current terms (14 Oct 2026) except as offline downloads
  the user asks for. Not built; it would not speed up the start anyway (the last view's tiles are cached).

## Try it (5 minutes)
1. Kill the app and open it five times in a row; then switch the phone to dark mode and do it twice more. Watch
   for: a colour flash, an empty map behind the buttons, pins coming in steps, bubbles regrouping after they appear.
2. Turn Wi-Fi off and open it once: the streets you saw last and your pins, no spinner.
3. Delete a capsule from another phone (or remove a friend), then open the app: it may show for a second, then it
   goes. Tap a pin within the first second after the map appears: the card shows the real capsule.

## Weak spots left (BLOCKERS.md)
- A pin tapped within about a second of the map appearing opens its card up to 0.85 s late.
- Offline, the pins can come a quarter second before the streets.
- iOS not run; 4,000 capsules and a slow network not measured on the phone.
