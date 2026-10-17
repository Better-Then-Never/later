# TEST_REPORT.md

## Automated (all on Windows, Flutter 3.38.4)
| Suite | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | No issues found |
| Format | `dart format --output=none --set-exit-if-changed lib test tool` | clean |
| Unit + widget + golden | `flutter test` | **231 passed**, 1 skipped (pre-existing: a fake_cloud_firestore GeoPoint case) |
| Translations | `test/l10n` (part of the above) | every message in 5 languages with the same placeholders; ARBs built from the fragments |
| Design tokens | `dart run tool/check_design_tokens.dart` | no violations |
| Cloud Functions | `cd functions && npm run test:emulate` | **43/43** |
| Security rules | `cd tools/rules-tests && npm run emulate` | **53/53** |
| Admin scripts | `tools/admin/selftest.js` against emulators | all checks passed (admin claim, verified, backfill) |
| Performance (profile mode) | `integration_test/perf_test.dart` | all flows ran; numbers in PERFORMANCE.md (mid-mission run) |

CI runs `flutter test --exclude-tags golden` (goldens are rendered on Windows only).

### New tests in this branch (selection)
Data mappers for every new field and the legacy fallbacks; settings store (privacy, language sync, offset);
read receipts both ways; reopening a chat without a spinner; image cache buckets and remembered avatar URLs
(restart, offline, eviction, account switch); friends-of-friends ranking; capsule creation (approximate rounding,
capture time, per-capsule switches, 0,0 rejected); offline outbox (queue, restart, other account, discard,
refusal cap); reactions (toggle, replace, rollback), comments (thread order,
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
- Capsule created with comments off.
- Verified badge and follower counts, achievements card and page (stats written by hand to the local emulator,
  since functions did not run there).

## Not tested
iOS; a physical Android device; push delivery end to end (functions not running with the app); announcements
end to end (topic sends need FCM).
