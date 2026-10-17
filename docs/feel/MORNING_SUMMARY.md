# MORNING_SUMMARY.md: Session A in one page

Branch `feature/feel-pass-real-device`, PR #81 (stacked on #80, ready for review, **not merged**; they replace #79 and #78, which were closed and archived). Nothing was
deployed and nothing touched production: every check ran on a Galaxy S20 FE against the local Firebase emulators
with a heavy seed (104 people, 2,002 capsules, a 600-message chat). No pushes were delivered (no dev project) and
nothing ran on iOS.

## How it feels now
Measured on the phone, not guessed. The two things that made the app feel broken are gone: the 10–12 second freezes
after startup (thousands of skipped frames per run, caused by thousands of map markers) and the ~10 second freeze
after every theme switch. Scrolling, panning, zooming and the camera are smooth, and the app starts in 0.8 s. Every
page now moves the same way (one page route with an edge swipe back, cards that rise and close with a drag, tabs,
photo heroes, small celebrations). What is left is the first frame of a page: opening something costs one to three
late frames, and startup still has one long frame (84.6 ms) while the hidden tabs lay out their lists.

| Flow (medians of 3 runs, 120 Hz) | Before | Now |
|---|---|---|
| Theme switch | 16.8 % janky, a ~10 s freeze after it | **0.8 %**, no freeze (flow 22.1 s → 4.8 s) |
| Freezes (Android main-thread stalls per run) | 4,351–6,548 skipped frames, 10–12 s | **one 0.45 s stall at launch** |
| Settings open/close | 12.4 % | **0.8 %** |
| Notification segments | 10.8 % | 1.5 % |
| Cold start to the signed-in home | 867 ms | **820 ms** (budget 2 s) |
| Camera: tap → visible feedback | 26 ms | 20 ms (the page itself: 1.1 s) |
| Chat with 600 messages: tap → messages | 21 ms | 23 ms |
| Startup (launch → home) | 8.1 % | 6.9 %, worst frame 84.6 ms (**the weakest**) |
| New Part B screens (profile, notifications, passport, map filter, streak) | – | 0–1.3 % |

Final numbers are from one run (the owner's call); baseline and checkpoint A from three (PERFORMANCE.md).

## What was built (Part B; details in FEATURES_B.md)
- **Chat**: photos, a queue for text sent offline, typing, group chats, voice messages (Android), big emoji and a
  sticker panel, swipe actions, pinned chats, forward, report, delete for me, unread divider.
- **Capsules**: share as a link, quick reply to the author, "who left it", co-authors, report everywhere, comments
  in pages, notification taps open the capsule and its thread.
- **Profiles**: a new profile tab, pinned and recent friends with quick actions, about me, search by name (also
  from the chat search), report and block strangers, the missing settings (units, photo quality, save to gallery,
  sign-in methods, download my data).
- **Creation**: loop capsules switched on (mode switch, frame strip, speed), thumbnails, drafts, the app's own
  calendar, pin on a map, steps and a composer, uploads for friends' capsules, Wi-Fi only and in the background.
- **Map**: filters (whose, open or later, colours).
- **Notifications**: days, the team's announcements, swipes, friend requests answered in place, a vibration
  switch, tested tap routing; on the server group and co-author notifications, a capped fan-out, achievements
  checked only where a stat changes.
- **Gamification**: the streak on the map with an at-risk variant, unlock and milestone cards from real events,
  "capsules viewed" with a new achievement, a passport of countries and towns, `entitlements/limits`.

**Flagged off**: friend suggestions from contacts (needs a test phone and the contacts permission).
**Not built**: the app icon badge (needs a third-party package; Android's own dot remains).

## What to check by hand
1. Deploy to a dev project in the order of BACKEND_CHANGES.md and receive one push of each kind in each app state
   (BLOCKERS.md has the list), including vibration off.
2. The Storage delete grant for the functions' service account (BACKEND_CHANGES.md §2): account deletion cannot
   delete files today either.
3. Owner decisions: the Cyrillic font, the light map style, illustrated sticker packs, the weekly limit and the daily
   streak (FEATURES_B.md, B7, with a recommendation), the contacts flag, the icon badge.
4. iOS: voice messages and country names have no iOS side; nothing was built or run there.
