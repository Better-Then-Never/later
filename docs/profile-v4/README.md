# Profile v4

The profile as agreed with the owner on 1 and 2 Nov 2026. Design only so far; nothing is built.

Figma file `rDjGzKKbcqpnzJHCBqXTJv`:

| Page | Section | What |
|---|---|---|
| 13 · Profile rework (`7160:3025`) | Round 5 (`7177:3811`) | the header worked out: states, stamp shapes and colours, corners |
| 13 | Profile v4 (`7182:4351`) | the whole profile: own (default `7182:4354`, pulled open `7182:4504`, scrolled `7182:4654`), new user, a friend |
| 14 · Profile v4 pages (`7188:682`) | three sections | every page the profile leads to, see [PAGES.md](PAGES.md) |

Rounds 3 and 4 on page 13 are the rejected and the explored options; they stay for the record.

## The header: a postcard

- **Default** (opening Profile): the short postcard. 200 dp of the cover photo, the name, `@username · home
  town`, your stamp "saying" the About me in a bubble, then followers, following and countries.
- **Pulled open**: pull down on the short postcard and it opens to 294 dp of photo and stays open (like
  Samsung One UI Settings; the owner's video). Pull up or scroll to close it.
- **Scrolled**: a photo strip edge to edge with round bottom corners (option B). The stamp stays
  inside the strip, never hanging over its edge; name beside it, the buttons on the right.
- The postcard: 344 dp wide, 20 dp corners, a white print margin around the photo (photo corners 14 dp).
- No postmark on the cover (the "first stamp" mark was dropped as redundant).
- The three buttons (notifications, share, settings) sit on the photo in dark circles in every state.

## The stamp

Your photo is a postage stamp on your postcard. Everyone chooses its shape and colour in Edit profile;
friends see the choice wherever the person appears (profile, notifications, friend lists, share sheets).

- Shapes: Classic (default), Rounded, Round, Soft, Ticket, Polaroid. The holes are real cut-outs, so the
  photo or card shows through them.
- Colours: White (default), the app's colours (Paper, Green, Yellow, Orange, Red, Blue, Forest, Black)
  and Any: a full picker (shade box, hue slider, hex, recent colours).
- A new user's stamp is white with the initial and a camera badge (tap to add a photo).

## The three profiles

- **Own**: the header above, then the Profile v2 widgets unchanged: My capsules, Friends (Add friends,
  pinned five, My friends), Places (map and Passport), Achievements (streak and marks).
- **New user**: the green placeholder cover keeps the "Add a cover photo" prompt with the camera icon;
  the empty bio bubble; 0 followers; the v2 empty states below.
- **A friend**: their cover and their stamp; back on the left, share and the menu on the right; Open
  chat and Send a capsule start 24 dp below the postcard (they touched the About me in v2); then their
  capsules, a Places row (their Passport, "2 you both have") and their achievements.

## What it needs from the backend

- Two profile fields: `stampShape` (one of the six) and `stampColor` (a token name or `#RRGGBB`).
  Firestore rules must accept them (validated values only), so this is a rules deploy, with the owner's go.
- Everything else already exists: cover photo, profile photo, about me, pinned friends, counts, stamps.
