# TEST_REPORT.md

## Automated (all on Windows, Flutter 3.38.4)
| Suite | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | No issues found |
| Format | `dart format --output=none --set-exit-if-changed lib test tool` | clean |
| Unit + widget + golden | `flutter test` | **259 passed**, 1 skipped (pre-existing: a fake_cloud_firestore GeoPoint case) |
| Translations | `test/l10n` (part of the above) | every message in 5 languages with the same placeholders; ARBs built from the fragments |
| Design tokens | `dart run tool/check_design_tokens.dart` | no violations |
| Cloud Functions | `cd functions && npm run test:emulate` | **43/43** |
| Security rules | `cd tools/rules-tests && npm run emulate` | **56/56** |
| Admin scripts | `tools/admin/selftest.js` against emulators | all checks passed (admin claim, verified, backfill) |
| Performance (profile mode) | `integration_test/perf_test.dart` | all flows ran; numbers in PERFORMANCE.md (mid-mission run) |

CI runs `flutter test --exclude-tags golden` (goldens are rendered on Windows only).

On Windows, `firebase emulators:exec` can leave the Firestore emulator's Java process running after the
suite (and always does when its output is piped into `head`); the next run then fails with "port taken".
Stop the leftover `java.exe` that listens on 8180 (rules) or 828x (functions) before running again.
Run the rules tests with their own `TEMP`/`TMP` while the dev emulators run: both storage emulators keep blobs
in `%TEMP%\firebase\storage`, the test instance wipes it on exit, and the dev storage emulator then crashes on
its next photo read ("ENOENT ... storage\blobs").

### New tests in this branch (selection)
Data mappers for every new field and the legacy fallbacks; settings store (privacy, language sync, offset);
read receipts both ways; reopening a chat without a spinner; image cache buckets and remembered avatar URLs
(restart, offline, eviction, account switch); friends-of-friends ranking; capsule creation (approximate rounding,
capture time, per-capsule switches, 0,0 rejected); offline outbox (queue, restart, other account, discard,
refusal cap); sheet system (outside tap, confirmation message, nested menu selection/back) and
icon button labels; reactions (toggle, replace, rollback), comments (thread order,
limits, delete rights), reports; news topics; achievements (catalog equals the server registry, standings,
streak); notification sentences for the server-made types; Appearance, Language and Privacy pages.

## On the emulator (Medium Phone AVD, 1080x2400, Android 16, local Firebase emulators)
Screenshots in `docs/ux/after`, `docs/ux/dark_candidates`.
- Dark mode on welcome, login, map (dark style), history, messages, profile, settings, capsule dialog, comments,
  creation, achievements; three dark candidates compared (D-03).
- Russian: settings, history (labels shortened after this check), profile.
- Language switch: instant, saved to the account (`language: "ru"` in the settings doc).
- Cold restart: avatars, background and capsule photos visible 1.5 s after opening the tab (disk cache).
- Permission onboarding: three steps, "Not now" on each, not shown again after a restart.
- My-location button: asks for location, flies to the user; dark "you" figure visible.
- Capsule card: opens on a marker, closes on map tap, back (app stays open) and swipe down; Google logo stays above
  it.
- Reactions and a comment saved through the new rules; comments sheet stays below the status bar with the
  keyboard open.
- Camera: first use after skipping the onboarding asks for the permission and starts (was failing).
- Offline capsule: airplane mode → saved at once with "Waiting for connection" → network back → uploaded
  (`offline_capsule_waiting_dark.png`).
- Sheets and menus: history Sort/Filter with the current choice, pinned friends sheet with a handle, permission
  confirmation card (`history_sort_menu_*.png`, `pinned_friends_sheet_dark.png`,
  `permission_confirm_card_dark.png`).
- Chat: hold menu, delete for both (chat list falls back), swipe-to-reply bar, quotes on both bubbles in light,
  tap a quote to jump across 40 messages (`chat_*.png`).
- Creation: privacy/colour/date menus, presets (`create_*_menu_dark.png`); full-screen photo from the preview and
  from an opened capsule, zoom and drag to close (`photo_viewer.png`).
- On this day with capsules dated 1 and 2 years back (`on_this_day_dark.png`); heatmap only when zoomed out
  (`map_heatmap_green_dark.png`).
- Light theme pass over tonight's screens (found the quote alignment bug).
- Large text (system font 130 %): history, profile, creation, messages fine; the map capsule card cut off its Open
  button (fixed, D-21).
- Capsule created with comments off.
- Verified badge and follower counts, achievements card and page (stats written by hand to the local emulator,
  since functions did not run there).

## Not tested
iOS; a physical Android device; push delivery end to end (functions not running with the app); announcements
end to end (topic sends need FCM).
