# BACKLOG.md: interactive polish session (from the owner's notes of 18 Oct)

Branch `polish/interactive-fixes` (from `main` at `7ca8bae`, v0.0.33). One item at a time, in the owner's order.
Status: `UNCHECKED` → `LIKELY_OPEN` / `LIKELY_FIXED` / `NEEDS_PHONE` (static triage, code only) → `FIXED` /
`ALREADY_FIXED` / `NEEDS_DECISION` / `DEBUG_ONLY` once checked on the phone. Finished items are in `LOG.md`.

## Map (M)
| ID | Item | Status | Triage note |
|---|---|---|---|
| M-01 | Map control sizes (zoom, compass, my location, streak pill, filter): one smaller scale, 44×44 taps | FIXED | 52 → 44 dp, one token `AppSizes.mapControl` (LOG.md) |
| M-02 | Selected capsule unclear: animated emphasis on the selected marker | FIXED | the selected pin pops to ~1.3× with a green ring, on top (LOG.md) |
| M-03 | Capsules appear with an animation on the first map open | LIKELY_OPEN | native markers; motion deliberately not built in Session A |
| M-04 | Capsules appear in batches when zooming | LIKELY_OPEN | same family as M-03 |
| M-05 | Cluster rework (ask: which element is unreadable; library change = decision gate) | LIKELY_OPEN | own grid clustering in `map_clusters.dart` |
| M-06 | Map cold start looks clumsy (white screen, person, then map, then capsules) | NEEDS_PHONE | |
| M-07 | "Almost there" screen shown after the map at the first Google login | NEEDS_PHONE | `settingsCompleteProfileTitle` |
| M-08 | Capsule preview too far left; inconsistent placement (ask) | NEEDS_PHONE | |
| M-09 | Remove the words "Visibility" and "From you" from capsule info | LIKELY_OPEN | |
| M-10 | Remove seconds from the opening countdown | LIKELY_OPEN | `capsule_info_panel.dart` ticks every second, shows seconds |

## Profile, friends, people (P)
| ID | Item | Status | Triage note |
|---|---|---|---|
| P-01 | Following / followers wrap badly in Russian: stack when they do not fit | NEEDS_PHONE | |
| P-02 | "Friends" and "Achievements" labels in the "My capsules" label style, above their widgets | LIKELY_OPEN | |
| P-03 | Redo the profile page in the original Later style, no emoji (git history as reference) | LIKELY_OPEN | large |
| P-04 | Count badges off-centre (profile bubble, add friends widget) | NEEDS_PHONE | |
| P-05 | Friend requests tabs identical to the notifications switch, everywhere | LIKELY_OPEN | `friend_requests_page.dart` vs `app_segmented_tabs.dart` |
| P-06 | Names and usernames in friend requests too small | LIKELY_OPEN | |
| P-07 | Add friends list looks different from other lists | LIKELY_OPEN | |
| P-08 | Add friends opens with a different animation | LIKELY_OPEN | `appSheetRoute` (rises) instead of the page route |
| P-09 | Lists of who you follow and who follows you | LIKELY_OPEN | not built |
| P-10 | Share profile page sits too high | NEEDS_PHONE | |

## Chat (C)
| ID | Item | Status | Triage note |
|---|---|---|---|
| C-01 | Tap the name or avatar in a chat to open the profile | LIKELY_OPEN | only group member sheets open profiles |
| C-02 | Consecutive bubbles too close | NEEDS_PHONE | |
| C-03 | Reply by swiping right to left with a smoothly appearing icon | LIKELY_OPEN | `_SwipeToReply` takes positive dx (left to right) |
| C-04 | Opening a chat feels sluggish (measure in profile first) | NEEDS_PHONE | Session A: chat_open 1.4 % janky, 23 ms to messages |
| C-05 | Telegram-like composer with a gallery photo panel | LIKELY_OPEN | large; the photo panel needs a gallery source |
| C-06 | Header shows mismatched rounded corners over lists | NEEDS_PHONE | |

## Creation (K)
| ID | Item | Status | Triage note |
|---|---|---|---|
| K-01 | Oversized grey option buttons (date, colour, ...) | LIKELY_OPEN | |

## Lists and scrolling (L)
| ID | Item | Status | Triage note |
|---|---|---|---|
| L-01 | Choppy list scrolling (~30 fps feel) | NEEDS_PHONE | Session A profile runs: scrolls 0–0.3 % janky; may be debug only |
| L-02 | List stutter ("shattering") | NEEDS_PHONE | same investigation as L-01 |

## Share (S)
| ID | Item | Status | Triage note |
|---|---|---|---|
| S-01 | Bring back the original share icon, delete the drawn one | LIKELY_OPEN | |
| S-02 | Two Later-style web pages (profile, capsule) and links that open the app (hosting deploy = gate) | LIKELY_OPEN | |

## Global design (G)
| ID | Item | Status | Triage note |
|---|---|---|---|
| G-01 | No emoji in the UI; Material placeholders recorded in PLACEHOLDER_ICONS.md | LIKELY_OPEN | emoji in 11 files (streak flame, passport, profile, ...) |
| G-02 | Cyrillic font close to Inria Sans (decision gate, comparison first) | LIKELY_OPEN | |
| G-03 | Frosted surface behind the Android navigation bar | LIKELY_OPEN | |
