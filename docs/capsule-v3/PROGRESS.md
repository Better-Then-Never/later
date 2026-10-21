# Capsule v3: progress

Branch `feature/capsule-v3` (from `main` at `f76658c`, v0.0.36). The design lives in Figma file
`rDjGzKKbcqpnzJHCBqXTJv`, page 10 "App v2" (section from y 5560) and page 12 "To build (for approval)"
(`7102:682`), which lists every item by ID. The owner approved A, B, C, D and F on 2026-10-20; E (stamps)
and G (profile v2, passport, other screens) are for later.

## Plan

| Phase | Items | Needs the backend | State |
|---|---|---|---|
| 1 | A1–A10, C1 | no | done, committed locally |
| 2 | D1–D4: the wrapped first open, press and hold | no | done, committed locally (sound waits for H2) |
| 3 | B1–B5, C2, F1, F2: how it opens, Adjust, "is open" pushes | yes: a lock in the data first (below) | plan for the owner first |
| 4 | F3, F4: notifications by location | yes | later |

Phase 3 cannot start as UI only. Today the rules let anyone who may see a capsule read its title,
description and photo URLs before `openAt`; the lock exists only in the app. A place lock (150 m) or a
real date lock needs the content kept out of reach until it opens, and capsules are treated as
immutable (delta sync, the pin store). The owner gets a written plan before any of it is built.

## Phase 1 (done)

| ID | What | Where |
|---|---|---|
| A1, A2 | Map card: an open capsule shows the photo, who left it, "Opened today / yesterday / on {date}" or "Open anytime" and an Open pill; a locked one shows the pin on its colour, "Opens in …" with a wait bar, "Opens on {date}" and a Locked pill | `lib/features/map/widgets/capsule_info_panel.dart` |
| A3 | The opened capsule is a sheet over the map: square photo (a tap shows it whole), title with the yellow place chip (a tap shows it on the map), who left it, "Left … · opened …", the words | `lib/features/capsules/social/capsule_sheet.dart`, `AppSheetRoute` in `lib/shared/widgets/app_sheets.dart`, `lib/shared/widgets/capsule/capsule_place_chip.dart` |
| A4 | Reactions in one row, yours tinted soft green; Material placeholders until the owner's drawings exist (H1, `docs/polish/PLACEHOLDER_ICONS.md`) | `CapsuleReactionsBar` in `capsule_social_panel.dart` |
| A5 | The newest comment as a preview; an action bar with words: "Comments · N", "Reply to {first name}", share, ⋯ | `capsule_sheet.dart` |
| A6 | Comments: Author chip on the capsule owner's comments, replies on a thread line, "Replying to {name} ×", your picture in the field, a long-press menu beside the comment (Reply, Copy text, Delete or Report), the empty hint names the author | `capsule_comments_sheet.dart` |
| A7 | Quick reply sits right above the keyboard with the capsule as a chip; "Sent to {name}". The map no longer resizes under a card's keyboard (its zoom buttons jumped behind the scrim), and the sheet under it keeps its place | `quick_reply_card.dart`, `lib/app/shell/widget_tree.dart` |
| A8 | The ⋯ menu opens by its button: Show on the map, Remove me as co-author (co-authors), Report | `capsule_sheet.dart` |
| A9 | Report: a reason first, then the red Report button (one tap on a reason used to send it) | `ReportReasonSheet` in `capsule_social_panel.dart` |
| A10 | All of it in dark mode (new tokens `accentText`, `accentSoft` in `AppPalette`) | `lib/core/theme/app_palette.dart` |
| C1 | Create preview in the v3 look: square photo with Retake, the title as big as on the sheet with the place chip (a tap moves the pin), the words, "Left today · opens anytime / opens {date}" | `capsule_creation_page.dart` |

Gone: `CapsulePreviewCard`, `CapsuleSocialPanel`, `CapsulePlacePill`, `CapsuleDatePill`, `CapsuleImagePreview`,
and the strings only they used.

Not in phase 1, on purpose:

- C1's Adjust chip waits for C2 (phase 3): the square crop has to be stored with the capsule.
- The Create page keeps its old Settings list; "How it opens" (B2) replaces the "Open At" row in phase 3.
  Until then an empty date reads "Select date" there and "opens anytime" in the preview (both mean now).
- A hidden author stays unnamed in the quick reply ("Reply to the author", "Sent"); the old card put their
  name in the hint.

### Checked

- `tool/dev/checks.sh`: format, analyze, 536 tests, design tokens, no unused strings.
- New tests: the map card (dates, "Left by", text scale), the sheet (reactions, comments pill, Reply to),
  the comments sheet (Author chip, long-press menu, Replying to, the empty hint), the report confirm.
- On the phone (debug build, local emulators), light and dark: map card, sheet, comments with a thread,
  the long-press menu, quick reply above the keyboard and its toast, the Create preview.

## Matched to Figma (2026-10-21)

The owner found phase 1 off from the design. Every screen was rebuilt from the frames' own values
(`get_design_context`, not from memory) and checked on the phone side by side, light and dark:

| Screen | Frame |
|---|---|
| Map card, open / locked | `7080:1085`, `7080:1191` |
| Opened sheet, light / dark | `7080:1302`, `7080:1460` |
| Comments, comment menu, empty | `7084:1258`, `7084:1530`, `7084:1630` |
| Quick reply, ⋯ menu, report | `7084:1762`, `7084:1868`, `7084:1965` |
| Create (header, preview, settings, options, button) | `7094:2148` |

The quick reply had been built from an older v2 frame (`7047:784`). New shared pieces: `PillV2`
(Figma "Pill v2"), `showAnchoredMenu`, `PageHeaderV2`, `SheetHandle.v2`, `PhotoBadge`,
`SendCircle`. Four of the owner's icons came from the Figma library (send arrow, heart, done check,
write) with dark variants. Tokens: `accentSoft` is green at 30 %, dark `accentText` #7FD95A. The
countdown shows days and hours while a day or more is left ("41d 6h"). Still not built: the Adjust
chip on the Create photo (C2, phase 3).

## Phase 2 (done)

| ID | What | Where |
|---|---|---|
| D1 | The first open of a capsule arrives wrapped over the whole sheet: the cover pattern (the app's line icons, as the profile covers) in the capsule's colour, paler in light and deeper in dark, its pin on a white seal, a gift tag (From, title, "Left {date} in {place}") on a string, "Waited N days". The map card says "Yours to open" until then | `lib/features/capsules/opening/capsule_wrap.dart`, `capsule_info_panel.dart` |
| D2 | Press and hold about a second: the ring fills, the pin wobbles, ticks you can feel come closer together; letting go early winds it back ("Hold a little longer") | `CapsuleWrap` |
| D3 | One firmer tick, then the wrapping tears apart from the pin onto the capsule. The paper sound and chime wait for H2 | `CapsuleWrap` |
| D4 | Every later open is instant; reduced motion gives a plain fade; a screen reader's double tap opens it at once | `lib/features/capsules/opening/capsule_openings.dart` |

Which capsules arrive wrapped (`CapsuleOpenings`):

- Remembered on the phone, per account (the last 2000 unwrapped). The rule needs no backend, so it is
  per phone: on a second phone the first open is wrapped again.
- Only capsules that could first be opened after the phone first asked (`unwrapped_since`): after the
  update nothing the user may have seen before arrives wrapped. To try it, open a capsule a friend left,
  or one that reached its date, after installing.
- Someone else's capsule always; your own (or one you made with others) only when it waited for a date.
- Not when it is opened for its comments (from a comment notification).
- New colour tokens: the six capsule colours as the pins draw them (`AppColors.capsuleRed` …); the
  wrapping takes them 60 % towards white in light, 70 % towards black in dark (the prototype's blue).
- New motion tokens: `holdToOpen`, `holdWindBack`, `tear`, `tearCurve` (`MOTION_CATALOG.md`).

### Checked

- `tool/dev/checks.sh`: format, analyze, 546 tests, design tokens, no unused strings.
- New tests (`test/features/capsule_opening_test.dart`, `map_test.dart`): who gets the wrapping, the
  phone's start, your own capsules, remembered across a restart; arrives wrapped with its tag; early
  release winds back; a one-second hold tears it open and the next open is instant; the screen reader
  tap; the card's "Yours to open".
- On the phone, light and dark, with capsules made in the emulator after the phone's start: the card,
  the wrapping, an early release, and the tear recorded frame by frame (ring, tear along the edge, the
  seal dropping away, the sheet underneath). Haptics need a person holding the phone to judge.

## Owner side (H)

- H1: draw the reaction faces and marks (placeholders listed in `docs/polish/PLACEHOLDER_ICONS.md`).
- H2: pick the opening sound (phase 2).
- H3: put v0.0.36 back on the phone; it runs the debug build with test data.
