# FEEL_QA.md: what was checked, how, and on what

Everything marked ✓ here was checked **on the reference phone** (DEVICE.md) unless it says "test" (a widget or
unit test in `test/`). Not checked = not claimed (BLOCKERS.md).

## Gates (local; PR #79 has no CI)
| Gate | Command | Result at the checkpoint (A) |
|---|---|---|
| Format, analyze, tests, design tokens, unused strings | `bash tool/dev/checks.sh` | ✓ (315 tests, 1 pre-existing skip) |
| Functions tests (emulator) | `cd functions && npm run test:emulate` (own TEMP, see RIG.md) | ✓ 45/45 (43 in Part A; +2 for chat photos) |
| Firestore and Storage rules tests | `scratchpad/rules_tests.sh` equivalent: `cd tools/rules-tests && npm test` under `firebase emulators:exec` | ✓ 61/61 (rules untouched in Part A: 57; +4 for chat photos), run with the dev emulators stopped |
| Perf flows on the phone | `tool/dev/measure.sh <label> 3`, `dart run tool/dev/perf_summary.dart` | PERFORMANCE.md "After" |

## Measured on the phone (profile builds)
See PERFORMANCE.md: baseline, every Phase 2 fix with before/after, and the final "After" run. Main-thread stalls
(the freezes) are reported per run.

## Looked at on the phone (debug build, light and dark, ru and en)
| Screen | What was checked | Light | Dark | ru | en | Text 130 % |
|---|---|---|---|---|---|---|
| Map | local light style, clusters, zoom pill, my-location, capsule card with photo, card lifting the controls | ✓ | ✓ | ✓ | – | ✓ |
| Capsule dialog | rises over the scrim, photo, reactions, comments row | ✓ | – | ✓ | – | – |
| Profile | share icon, friends card title and tiles, header buttons | ✓ | ✓ | ✓ | ✓ | ✓ |
| Settings | 44 dp rows, subtitles unchanged, header below the status bar | ✓ | ✓ (appearance) | ✓ | – | ✓ |
| My capsules | 44 dp controls, 17 sp search, last capsule clear of the pill, "On this day" at 130 % (fixed) | ✓ | – | ✓ | ✓ | ✓ |
| Messages | sharp compose icon, search, list end | ✓ | – | ✓ | ✓ | – |
| Chat (600 messages) | bubbles, quote, receipts, input bar | ✓ | – | ✓ | – | – |
| Add friends, Requests | 44 dp targets, segmented tabs | – | ✓ | ✓ | – | – |
| Camera | zoom stops (2× tapped), brightness slider after tap to focus, torch, shutter freeze (front camera: the still shows the picture, 1080×1920) | n/a | n/a | ✓ | – | – |
| Map compass | two-finger twist (perf test) → compass shows; tap → north (296° → 0°) | ✓ | – | ✓ | – | – |
| Creation | page after capture, save morph (perf flow, 0 % janky) | ✓ | – | ✓ | – | – |

## Tap targets (tool/dev/tap_audit.sh on the phone)
| Screen | Before | After |
|---|---|---|
| History | search field 34 dp, favourite heart 24 dp | no problems |
| Profile | "My capsules" rows 39–41 dp, "My friends" 40 dp | no problems |
| Add friends | send request 32 dp, hide 25 dp | no problems |
| Requests | Accept/Decline 36 dp, segmented tabs 32 dp | no problems |
| Map | cluster bubbles 34 dp | 44 dp (bubbles cut off at the screen edge excepted) |
| Camera, notifications | – | no problems |
Known false positives of the tool: rows half under the pill mid-scroll, and anything below y ≈ 2168 px on this phone
(Android clips the reported bounds there; the chat input bar measures 46–48 dp in screenshots).
Widget tests hold the 44 dp minimum for the icon button, reply bar, hint and segmented tabs (`tap_targets_test`).

## Motion
Every motion in MOTION_CATALOG.md honours reduced motion; widget tests cover the route, tabs, crossfade, rows,
reaction burst, idle float and photo hero. Reduced motion was **not** toggled on the phone (test only).

## Part B on the phone (debug builds, Russian, light unless noted)
Each row was seen on the reference phone against the emulators with the triggers running; the details and what was
not seen are in FEATURES_B.md (per feature, "Phone" and "Not seen").

| Part | Seen on the phone |
|---|---|
| B1 chat | photo messages (with and without a caption, the viewer, delete), text queued offline across a restart, typing in a chat and in a group, a group (created, invites accepted by the function, renamed, left), a voice message recorded and played (also after a restart, from Storage), the sticker panel and a big emoji, swipes (pin, mute), pinned chats, forward, the message menu (report, delete for me), the unread divider |
| B2 capsules | a share link opened by `later://capsule` (a hidden capsule refused), quick reply with its toast, the author line, co-authors both ways and "remove me", reports of a capsule and a stranger's profile, a comment notification opening the thread |
| B3 profiles | the redesigned tab, quick actions and pins, about me, search by name from the chat search, sign-in methods, miles, photo quality (720×1280 → 1080×1920), the gallery copy, the data export (104 capsules, 60 friends, 23 chats), the contacts sheet refused without the permission (flag on locally only) |
| B4 creation | a loop recorded and edited (strip, speed), thumbnails, the loop mark, a draft taken up again, the calendar (Monday first), the pin moved on a map, the composer, a background upload by WorkManager |
| B5 map | the filter (Mine only: 105 of 1,208; Mine + red: 17; kept across a restart) |
| B6 notifications | day headers, an announcement in Russian, an accept in place, both swipes (Firestore checked) |
| B7 gamification | the streak pill in colour and at risk, its card and the way to the camera, the milestone card at 7 days, unlock cards from a reaction and from views, one card for a burst, the passport (16 countries, names in Russian), a new capsule's country |

Not looked at for Part B: dark theme, 130 % text and English on the phone (tests only; the stamp's fit at 1.3× is
a test), TalkBack.

## Tap targets of the Part B screens
Not run on the phone (the owner skipped the last phone pass; BLOCKERS.md), and `tap_targets_test.dart` covers only
the shared controls of Part A. By construction the streak pill is 52 dp and the passport row 44 dp tall; the map
filter chips, the notification swipe rows, the answer buttons and the moment cards were not measured.

## Gates at the end of Session A
| Gate | Result |
|---|---|
| `tool/dev/checks.sh`: format, analyze, Flutter tests, design tokens, unused strings | ✓ 404 tests passed, 1 pre-existing skip |
| Functions tests (emulator) | ✓ 62/62 |
| Firestore and Storage rules tests (emulator, dev emulators stopped) | ✓ 82/82 |
| Perf flows on the phone (27 flows, 1 run) | PERFORMANCE.md "Final": every flow ran; 6 flows 1.2–1.8 % janky, startup 6.9 % (documented there) |
| Cold start | ✓ 820 ms median of 5 (budget 2 s) |
