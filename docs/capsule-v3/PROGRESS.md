# Capsule v3: progress

Branch `feature/capsule-v3` (from `main` at `f76658c`, v0.0.36). The design lives in Figma file
`rDjGzKKbcqpnzJHCBqXTJv`, page 10 "App v2" (section from y 5560) and page 12 "To build (for approval)"
(`7102:682`), which lists every item by ID. The owner approved A, B, C, D and F on 2026-10-20; E (stamps)
and G (profile v2, passport, other screens) are for later.

## Plan

| Phase | Items | Needs the backend | State |
|---|---|---|---|
| 1 | A1–A10, C1 | no | done, committed locally |
| 2 | D1–D4: the wrapped first open, press and hold | no | next |
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

## Owner side (H)

- H1: draw the reaction faces and marks (placeholders listed in `docs/polish/PLACEHOLDER_ICONS.md`).
- H2: pick the opening sound (phase 2).
- H3: put v0.0.36 back on the phone; it runs the debug build with test data.
