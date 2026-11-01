# Profile v4: progress

Branch `feature/profile-v4` (from `design/profile-v4`, which is `main` at `dd7d0f5` plus the design docs).
Owner, 2 Nov 2026: "start everything, test everything properly, overnight job; the Figma is a direction,
it still has some mistakes". Nothing is pushed, merged or deployed.

The design: [README.md](README.md) (the profile), [PAGES.md](PAGES.md) (the pages), Figma pages 13 and 14.

## Plan

| Phase | What | State |
|---|---|---|
| P1 | Stamp model (`stampShape`, `stampColor`, `homeTown` on `users/{uid}`), rules + rules tests, the `ProfileStamp` widget (six shapes, real cut-outs, colours), golden | done |
| P2 | Own profile: the postcard header (default, pulled open, scrolled strip) and the v2 body (My capsules, Friends, Places, Achievements) | |
| P3 | New user and a friend's profile in the postcard style; the friend's menu; their Places row | |
| P4 | Edit profile, the stamp sheet (shape + colour), Any colour | |
| P5 | The other pages: Later card (front, back, share), Notifications, Settings (postcard row, streak reminder), My friends + Pin a friend, Add friends, My capsules header, Achievements + one achievement, Streak, a capsule for a friend, Passport | |

## Backend (not deployed)

`firestore.rules`: `ownerUpdate` accepts `stampShape` (one of the six), `stampColor` (a name or
`#RRGGBB`) and `homeTown` (a string of at most 40). Rules tests: 91 pass (one new). Until the rules are
deployed, saving a stamp or a home town is refused by production; the app reads missing values as
Classic / White / no town, so nothing breaks for older profiles or older apps.

## Notes

- About me stays at 100 characters (the rules' limit); the Figma counter said 150.
