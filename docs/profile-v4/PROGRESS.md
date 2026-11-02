# Profile v4: progress

Branch `feature/profile-v4` (from `design/profile-v4`, which is `main` at `dd7d0f5` plus the design docs).
Owner, 2 Nov 2026: "start everything, test everything properly, overnight job; the Figma is a direction,
it still has some mistakes". Nothing is pushed, merged or deployed.

The design: [README.md](README.md) (the profile), [PAGES.md](PAGES.md) (the pages), Figma pages 13 and 14.

## Plan

| Phase | What | State |
|---|---|---|
| P1 | Stamp model (`stampShape`, `stampColor`, `homeTown` on `users/{uid}`), rules + rules tests, the `ProfileStamp` widget (six shapes, real cut-outs, colours), golden | done |
| P2 | Own profile: the postcard header (default, pulled open, scrolled strip) and the v2 body (My capsules, Friends, Places, Achievements) | done |
| P3 | New user and a friend's profile in the postcard style; the friend's menu; their Places row | done |
| P4 | Edit profile, the stamp sheet (shape + colour), Any colour | done |
| P5 | The other pages: Later card (front, back, share), Notifications, Settings (postcard row, streak reminder), My friends + Pin a friend, Add friends, My capsules header, Achievements + one achievement, Streak, a capsule for a friend, Passport | done (see below) |

## Backend (not deployed)

`firestore.rules`: `ownerUpdate` accepts `stampShape` (one of the six), `stampColor` (a name or
`#RRGGBB`) and `homeTown` (a string of at most 40). Rules tests: 91 pass (one new). Until the rules are
deployed, saving a stamp or a home town is refused by production; the app reads missing values as
Classic / White / no town, so nothing breaks for older profiles or older apps.

## Notes

- About me stays at 100 characters (the rules' limit); the Figma counter said 150.

## What was built (night of 2 Nov 2026)

Four parts were built in parallel worktrees and merged here (`profile-v4-notif`, `-achieve`, `-friends`,
`-passport`); the rest directly on this branch. Every merge kept the gates green: analyze, design tokens, unused
strings, the whole `flutter test` suite.

| Page | Where | Notes |
|---|---|---|
| Own profile: postcard (default / pulled open / photo strip) | `lib/features/profile/postcard/`, `profile_page.dart` | pull down at the top opens it and it stays open; scrolling closes it; checked on the phone |
| A friend's profile | `friends/pages/your_friend_profile_page.dart` | their stamp; Open chat / Send a capsule 16 dp below the postcard; Places row opens their Passport |
| Stamp: six shapes, nine colours, Any colour | `profile/stamp/`, `shared/widgets/user/profile_stamp.dart`, `user_stamp.dart` | saved as `stampShape` / `stampColor` (rules not deployed) |
| Edit profile + home town | `profile/edit_profile_page.dart` | replaces Customize profile; Settings starts with your postcard |
| Later card (front, back, share) | `profile/share/share_profile_page.dart` | tap turns it over (400 ms 3D flip); Share sends the side in view as a picture |
| Notifications | `features/notifications/` | filters All / Friends / Capsules / Places, friend requests card, Today / Earlier, stamps, Follow back |
| My friends, Pin a friend, Add friends, a friend's menu | `features/friends/` | the pin limit stays the app's 3 (Figma said 5) |
| Achievements, one achievement, Streak | `features/achievements/`, `features/streak/` | 13 achievements in 4 groups; Streak page with week and month |
| Streak reminder | `features/streak/streak_reminder*.dart`, Settings > Notifications | local, on this phone, inexact (no exact-alarm permission), skipped once today counts; Android only |
| A capsule for a friend | `capsules/creation/capsule_creation_page.dart` | "A capsule for Bob" and their stamp in a To card |
| Passport booklet | `features/passport/`, `world/world_page.dart` | cover, photo page, stamps, visas, your year, you and a friend, share a page, empty state |

## Not built, and why

- **Friends since**, **per-person mute**, **friends who have an achievement**, **show a town on the map**, **holder
  since**: the app has no such data (no friendship date, no per-person mute, no one else's achievements, no
  position per town, no account creation date). The friend's menu has the existing follow switch instead of mute.
- **Passport**: dates per town (only per country), longest away and most capsules this year; visa codes are 2
  letters (no ISO3 table).
- **The old server streak push** (`sendStreakReminders`): its switch is gone from Settings and turning the local
  reminder on sets its flag off; the function itself still runs for anyone who kept the old flag. Retiring it
  needs a functions change and deploy.
- A reminder tap only opens the app (the notification router maps it to "other").

## Before release

1. Deploy `firestore.rules` (stamp and home town). Until then saving a stamp or a home town is refused in
   production; everything else works.
2. Owner's look on the phone, especially the Passport and the friends pages (the helpers rendered them only in tests).
