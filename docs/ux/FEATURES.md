# FEATURES.md: what this branch adds, and where

Status: **on** = in the app and verified; **flag off** = built, hidden behind `lib/core/config/feature_flags.dart`;
**backend only** = server side ready, no UI; **not done** = see IDEAS_NOT_DONE.md.

## Foundation (Tier 0)
| Feature | Status | Where | Verified |
|---|---|---|---|
| Five languages (en, ru, pl, de, es), every screen, pushes too | on | `tool/l10n`, `lib/l10n`, `functions/lib/i18n.js` | tests (completeness, per-area), emulator in ru |
| Dark theme (charcoal, D-03), dark icons, dark map style (D-07) | on | `AppPalette`, `ThemedAssetBundle`, `map_styles.dart` | emulator screenshots (`docs/ux/after`) |
| Settings > Appearance (theme, interface size) and Language | on | `settings/pages/appearance_settings_page.dart` | widget tests, emulator |
| Edge-to-edge bars, splash = first frame | on | `bootstrap.dart`, Android styles | emulator |
| Photo disk cache, decode buckets, remembered avatars, instant chat re-entry (F-01..F-03) | on | `data/services/app_image_cache.dart`, `profile_image_cache.dart`, `chats_store.dart` | tests, emulator cold restart |
| Optional permission onboarding (3 steps, "Not now") (F-42) | on | `auth/permission_gate_page.dart` | emulator |
| Round list avatars (F-30), nav tab labels (F-34), pinned headers | on | shared widgets | goldens, emulator |
| One segmented control (requests = notifications tabs, F-41); Reset icon (F-31); lazy suggestions (F-38); readable header without a background (F-40) | on | `app_segmented_tabs.dart` and others | emulator |
| One sheet system (F-32/F-37): centred cards and edge sheets share barrier, animation and shapes; grab handle on every bottom sheet; history Sort/Filter in the menu card with the current choice in green; permission dialogs use the confirmation card; centred forms rise above the keyboard | on | `shared/widgets/app_sheets.dart`, `options_menu.dart`, `nested_menu.dart` | tests (`test/shared/sheets_test.dart`), emulator |
| Screen-reader labels on icon-only buttons (new chat, close, back, QR, share, menu, notifications, settings) | on | `DefaultIconButton.semanticLabel` | test |
| No dead ends: the friend menu's "Chat settings"/"Capsules settings" (did nothing) removed; place pills never empty | on | `friend_options_modal.dart`, `capsule_list_tile.dart` | tests, emulator |

## Map and creation (Tier 1)
| Feature | Status | Where | Verified |
|---|---|---|---|
| My-location button that asks for location when needed (F-13) | on | `map_page.dart` | emulator |
| Capsule card that always closes; Google logo never covered (F-12, F-14, F-17) | on | `map_page.dart` | emulator |
| Marker/heatmap memoization (F-10) | on | `map_controller.dart`, `map_page.dart` | profile run (`perf/mid`) |
| One short date format everywhere (`AppDates.short`, dd.MM.yyyy) | on | `core/l10n/app_dates.dart` | tests |
| Heatmap in one brand green, only when zoomed out (F-16, D-19) | on | `map_page.dart`, `AppColors.heatmap*` | emulator |
| Invalid places (0,0) ignored (F-18) | on | `geo_position.dart`, mapper, rules | tests |
| Privacy defaults in creation; per-capsule comments/reactions/approximate location (F-29) | on | `capsule_creation_*` | tests, emulator |
| Capture time + UTC offset on capsules (for streaks) | on | draft/mapper | tests |
| Camera asks for its permission first (fix) | on | `camera_page.dart` | emulator |
| Camera: pinch to zoom, tap to focus/exposure, instant shutter feedback (F-20..F-22) | on | `camera_page.dart` | emulator (focus ring; pinch needs a real device) |
| Description limit 2000 (F-25 bug) | on | creation | – |
| Offline capsules: kept on the phone, "Waiting for connection" in My Capsules, uploaded at sign-in/resume/every minute with a fixed id; refused ones tried 3× per sign-in (F-26) | on | `capsules/outbox/`, `own_capsules_store.dart` | tests, emulator (airplane mode → pending → uploaded) |
| Creation asks for location itself when onboarding skipped it (fix) | on | `capsule_creation_controller.dart` | emulator |
| Creation: privacy, colour and open date chosen from the menu card (current in green) instead of cycling pills; open date presets (tomorrow, week, month, year, pick, open right away); locale date format (F-27 part, F-28 part) | on | `capsule_creation_page.dart`, `showChoiceMenu` | tests, emulator |
| Chat: hold a message to copy it or delete your own for both (the chat list falls back to the previous message with its sender and time) | on | `chat_page.dart`, `ChatRepository.deleteMessage`, rules `isUndo` | tests, rules tests, emulator |
| Chat replies: swipe a message right (tick at the threshold, spring back) or hold > Reply; bar above the composer; quote in the bubble | on | `reply_bar.dart`, `message_bubble.dart`, `MessageReply`, rules `validReply` | tests, rules tests, emulator |

## Social and gamification (Tier 2)
| Feature | Status | Where | Verified |
|---|---|---|---|
| Reactions on open capsules (6 emoji) | on | `capsules/social` | tests, emulator against the new rules |
| Comments with one level of replies, delete, report | on | `capsules/social` | tests, emulator |
| Reports (capsules, comments) | on | `capsule_social_panel.dart` | tests |
| Friends-of-friends suggestions with mutual counts (F-57) | on | `friend_suggestions_controller.dart` | tests |
| A friend's capsules on their profile (F-54) | on | `friend_capsules_strip.dart`, `CapsuleRepository.sharedBy` | tests, emulator against the rules |
| Follower/following counts, verified badge (F-53, F-58) | on | `user_name_and_username.dart`, `verified_name.dart` | emulator |
| Achievements and streak on profiles (F-90..F-92) | on | `features/achievements` | tests, emulator |
| Privacy: read receipts (both ways), show achievements, default visibility, approximate location | on | `settings/pages/privacy_settings_page.dart` | tests |
| New notification types in the list (reaction, friend request/accepted, achievement) and categories in settings | on | `notifications`, `settings` | tests |
| Announcements from the team (topics per language) | on | `news_topics.dart`, `functions/lib/broadcast.js`, `tools/admin/announce.js` | tests |
| Streak reminder push (opt-in) | on (setting), server scheduled | `gamification.js` | functions tests |
| Admin tools: admin claim, verified badge, announcements, count backfill | on (scripts) | `tools/admin` | self-test |
| Loop capsules (and the Animator achievement) | flag off | `FeatureFlags.loopCapsules` (data model + rules ready) | – |

## Tier 3
| Feature | Status | Where | Verified |
|---|---|---|---|
| "On this day": your capsules from today's date in earlier years lead My Capsules ("1 year ago", plurals in 5 languages) | on (`FeatureFlags.memories`) | `history/on_this_day.dart`, `on_this_day_strip.dart` | tests, emulator |

## Backend only
Server counters for reactions and comments on capsules (`reactionCounts`, `reactionTotal`, `commentCount`); the
app uses them for large counts.
