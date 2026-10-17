# STATUS_REVIEW.md

Branch `feature/ux-features-night-session` at `014957d`. Written from the docs in `docs/ux`, `git log` and the code;
the gates were re-run for this review (format, analyze, `flutter test` 264 passed / 1 skipped, design tokens clean).
Everything "verified" below was verified on the **Android emulator** (Medium Phone, API 36) or by automated tests.
**Nothing was checked on a physical phone or on iOS.**

Status meanings: DONE_VERIFIED = built and checked (automated test and/or emulator, evidence named);
DONE_UNVERIFIED = built, but no test or run shows it works; PARTIAL = part of the finding addressed;
NOT_DONE; FLAGGED_OFF = built, hidden behind `lib/core/config/feature_flags.dart`.

Appendix A has no F-04..F-09, F-46..F-49, F-61..F-69, F-77..F-79, F-89 (sections 9 and 11 mention ranges up to F-66 /
F-78, but the appendix lists none of those).

## 1. Status table

| ID | Short name | Status | Evidence / what is missing |
|---|---|---|---|
| F-01 | Photos reload on navigation | DONE_VERIFIED | `data/services/app_image_cache.dart`, `shared/widgets/app_network_image.dart`; `test/data/image_cache_test.dart`; emulator only. Cache is keyed by the download URL (token URL), not the storage path the audit proposed. |
| F-02 | Photos reload after restart | DONE_VERIFIED | disk cache + `profile_image_cache.dart` (avatar URLs persisted); `test/data/profile_image_cache_test.dart`; emulator cold restart (`after/history_ru_dark_after_restart.png`). |
| F-03 | Chat photos vanish on re-entry | DONE_VERIFIED | `ChatsStore.recentWith`; `messages_test.dart` "reopening a chat shows its messages at once (F-03)"; emulator. |
| F-10 | Map stutters | PARTIAL | Markers/heatmap memoized (`map_page.dart` `_markers`/`_heatmaps`, keyed by `capsulesVersion`). Not done: clustering, viewport-bounded queries, 2,000-capsule test, other team member's device. Measured map pan with the 7 seeded capsules only; build worst 2.9 ms baseline vs 18.0 ms mid-run (not an improvement on paper). Never measured after the final code. |
| F-11 | Compass top-left | PARTIAL | Map `padding.top` = status-bar inset, so the compass is no longer under the status bar, but it stays Google's default top-left. Never checked by rotating the map. |
| F-12 | Zoom buttons behind nav pill | PARTIAL | Zoom buttons disabled (`zoomControlsEnabled: false`, pinch only). The prompt asked to keep them above the pill or build a control cluster; neither done. |
| F-13 | No my-location button | DONE_VERIFIED | `_MyLocationButton` in `map_page.dart`; `after/map_my_location_dark.png`; emulator. No pulsing user marker. |
| F-14 | Google logo hidden | DONE_VERIFIED | GoogleMap bottom padding grows with nav bar, card and hint; screenshots `after/map_*.png`; emulator. |
| F-15 | Map green duller than brand | PARTIAL | Dark mode: local JSON style (`map_styles.dart`, D-07). Light mode still uses the owner's cloud style (map ID): greens unchanged. |
| F-16 | Heatmap disliked | DONE_VERIFIED | One brand green, 40 px, 70 %, only below marker zoom (D-19); `after/map_heatmap_green_dark.png`; emulator. Clusters/hexagons evaluated only on paper. |
| F-17 | Popup cannot be dismissed | DONE_VERIFIED | Own card, closes on map tap, swipe down, back, tab change, zoom-out; `after/map_capsule_card_dark.png`; emulator. Card content not enriched (no thumbnail, author, distance, reaction count). |
| F-18 | Capsules in strange places | DONE_VERIFIED (prevention) | `GeoPosition.isValid`, mapper filter, rules reject ~0,0 (rules test "capsules: new optional fields; no 0,0; no future capture"), `capsule_creation_test.dart` "a 0,0 fix is not a place". The real "Niger" documents were never inspected (no production access); the cause is inferred, not confirmed. |
| F-19 | Map reliable and fast | PARTIAL | See F-10/F-11/F-12/F-15. No device measurement. |
| F-20 | Camera zoom | PARTIAL | Pinch zoom with a "1.8×" hint (`camera_page.dart`); no 0.5×/1×/2× stops. Pinch cannot be performed through adb: never actually exercised. |
| F-21 | Focus, exposure, settings | PARTIAL | Tap sets focus + exposure point with a ring (`after/camera_focus_ring.png`); no exposure slider, no grid, no other settings. |
| F-22 | 1.5 s shutter delay, blur | PARTIAL | Haptic + 120 ms white blink on tap. Capture path unchanged (`ResolutionPreset.high`, `takePicture`, then route). Tap-to-capture latency **never measured**, before or after; blur not addressed. |
| F-23 | Flash, torch | PARTIAL | Off → auto → on (`camera_page.dart`), labels checked on emulator; the emulator's virtual camera has no flash, so firing was not seen. Torch not built. |
| F-24 | Location slow in creation | PARTIAL | Last known position used at once (`CurrentLocation`), fresh fix in background, permission asked when missing, cached reverse geocoding (`GeocodingService`). No mini map, no manual pin. |
| F-25 | Creation responsive, animated, more settings | PARTIAL | Pinned header, settings switches, choice menus. No step flow, no step animations. |
| F-26 | Offline creation | DONE_VERIFIED | `features/capsules/outbox/capsule_outbox.dart`, `own_capsules_store.dart`; `test/features/capsule_outbox_test.dart` (6 tests); emulator airplane-mode run (`after/offline_capsule_waiting_dark.png`). Gaps: no WorkManager (uploads only while the app runs: sign-in, resume, 1-minute timer), fixed 1-minute retry (no exponential backoff), no resumable uploads, a capsule sent to a friend is not queued, no "retry" button for refused ones. |
| F-27 | Stock calendar | PARTIAL | Date presets in the menu card; "Pick a date…" still opens `showDatePicker`. |
| F-28 | Dated title/text inputs | NOT_DONE | Inputs unchanged ("Add Title..." / "Название..."). |
| F-29 | Capsule settings | PARTIAL | Visibility, open date, colour, comments on/off, reactions on/off, approximate location (UI + rules). `showAuthor` exists in the data model only (no UI, author never displayed). No co-authors. |
| F-30 | Messages redesign, squashed avatars, low-res icon | PARTIAL | Round avatars (`UserRoundAvatar.listRadius`, goldens). `assets/icons/messages/new_message.png` is still 36×36 px (blurry). No further list redesign. |
| F-31 | History controls oversized, filtering odd | PARTIAL | Reset has its own icon; Sort/Filter menus rebuilt with current choice in green. Control sizes and search field size unchanged. |
| F-32 | Mixed button/popup styles | DONE_VERIFIED | `shared/widgets/app_sheets.dart`, `options_menu.dart`, `nested_menu.dart`; `test/shared/sheets_test.dart`; screenshots `after/history_sort_menu_*.png`, `pinned_friends_sheet_dark.png`, `permission_confirm_card_dark.png`. |
| F-33 | Small titles, gray status bar | PARTIAL | Edge-to-edge transparent bars done. Header spec unchanged: `PageHeader` title still `screenHeight * 0.04`, top padding still 4 % of height, not the real inset. Notifications title position not changed. |
| F-34 | Nav pill too tall | NOT_DONE | `NavbarWidget.barHeight = 80`, unchanged. Only tab labels were added. |
| F-35 | My capsules jitter at end | NOT_DONE | Not investigated; physics unchanged. |
| F-36 | Everything too big | PARTIAL | UI size setting (small/standard/large, `UiScaleView`, D-04). Default density not tuned. |
| F-37 | Samey popups, big grabber, stacked modals | PARTIAL | Handle 36×4, edge sheets fill to the bottom, menus are centred cards. Every overlay still enters with the Material bottom-sheet slide; stacked-modal separation not addressed. |
| F-38 | Add friends transition ~15 fps | DONE_UNVERIFIED | Suggestions list made lazy (`95f1607`). Never re-measured after the change (the mid-run predates it). See 3b. |
| F-39 | Friends section | NOT_DONE | No "Friends" header; empty text and layout unchanged except colours/translation. |
| F-40 | Gray placeholders | PARTIAL | Profile background: brand-green → blue gradient (same for everyone, not derived from the user id). Avatar placeholder still `no_photo.png`. |
| F-41 | Requests toggle style, "Comments" wrap | DONE_VERIFIED (style) | `shared/widgets/app_segmented_tabs.dart`; `after/friend_requests_dark.png`. The "Comments" wrap at 360 dp / 1.3× text was not re-checked. |
| F-42 | Permission screens design | PARTIAL | Three optional steps instead of five mandatory (`permission_gate_page.dart`, `after/permission_onboarding_dark.png`); microphone/contacts removed. Page visuals not redesigned. |
| F-43 | AI-looking share icon | NOT_DONE | No artwork available; icon unchanged. |
| F-44 | Overall consistency | PARTIAL | Tokens enforced by `tool/check_design_tokens.dart`; many items above still open. |
| F-45 | Many more animations | PARTIAL | See section 3: stagger, chat motion, menus, photo viewer added; hero, reaction burst, marker motion, achievement/streak animations missing. |
| F-50 | Share, reactions, comments | PARTIAL | Reactions and comments on capsules (`features/capsules/social`, `capsule_social_test.dart`, emulator against the new rules). Capsule sharing and deep links not built. |
| F-51 | Co-authored capsules | NOT_DONE | Not started. |
| F-52 | Quick reply to a capsule | NOT_DONE | Not started. |
| F-53 | Follower counts | DONE_VERIFIED (server) / DONE_UNVERIFIED (end to end) | Counters by functions (`countFollower*`, functions tests), protected by rules (D-14, rules tests), backfill script (`tools/admin/selftest.js`). On the emulator the counts were written by hand: functions never ran with the app. |
| F-54 | Friend page / home profile redesign | PARTIAL | Friend page: capsules strip, achievements, counts, verified badge (`after/friend_profile_dark.png`). Home profile sections not redesigned. |
| F-55 | Friend capsules widget | DONE_VERIFIED | `widgets/profile/friend_capsules_strip.dart`, `CapsuleRepository.sharedBy`; `friend_capsules_test.dart`; emulator against the rules. Not paginated (≤30 per visibility), blocks not checked by the query. |
| F-56 | Pinned friends → quick actions | NOT_DONE | Not started. |
| F-57 | Global search, smarter suggestions | PARTIAL | No more list of all users; friends-of-friends with mutual counts (`friend_suggestions_controller.dart`, `friends_test.dart`). No global search entry point; no contacts (only a `contactSuggestions` field in the model). |
| F-58 | Verified checkmark | DONE_VERIFIED (mechanism) | Field writable only by admin scripts (rules tests), `tools/admin/set-verified.js`. Not applied to production; "amo b3" written as `amob3`, unconfirmed (BLOCKERS). |
| F-59 | Customize profile ideas | NOT_DONE | No ideas written up, nothing built. |
| F-60 | Author visibility on public capsules | NOT_DONE | `showAuthor` field only; capsules never show an author. |
| F-70 | Chat opens in the middle | DONE_VERIFIED | Reversed list (polish branch); emulator check with 40+ messages this mission. |
| F-71 | Group chats | NOT_DONE | Not started. |
| F-72 | Stickers | NOT_DONE | Not started. |
| F-73 | Voice messages | NOT_DONE | Not started (microphone permission was removed). |
| F-74 | No circles/publics/music | DONE_VERIFIED | Nothing of the kind built. |
| F-75 | Notifications must work | PARTIAL | Settings, tab, server functions and broadcast exist and are unit-tested; push delivery never verified end to end; announcements not shown in the app (see section 4). |
| F-76 | Messages at top-messenger level | PARTIAL | Reply, reactions, copy, delete, quote jump added; no images, voice, stickers, groups, typing, swipe actions. |
| F-80 | Email row "loading" | DONE_VERIFIED | Polish branch (PR #77); not re-checked this mission. |
| F-81 | Password change | DONE_VERIFIED | Polish branch; not re-checked this mission. |
| F-82 | Password reset | DONE_UNVERIFIED | Dialog exists (now on the centred card, rises above the keyboard). The reset email was never sent and followed end to end. |
| F-83 | Language selection | DONE_VERIFIED | `LanguageSettingsPage`; `test/l10n/l10n_completeness_test.dart`, settings tests; emulator (`after/language_ru_dark.png`), language saved to the settings doc. |
| F-84 | Appearance / dark theme | DONE_VERIFIED | `AppearanceSettingsPage`, `AppPalette`; `appearance_privacy_test.dart`; emulator screenshots. |
| F-85 | Customize profile nearly empty | NOT_DONE | Still pictures, name, username. |
| F-86 | Logout / permission rows design | DONE_VERIFIED | Polish branch; permission dialogs moved to the confirmation card this mission. |
| F-87 | UI size setting | DONE_VERIFIED | `UiScaleView` + Appearance page; widget tests. Not compared by eye at small/large on a device. |
| F-88 | Notification settings | DONE_VERIFIED | Polish + new categories (`notification_settings_page.dart`); settings tests; server enforcement in `functions/lib/prefs.js` (functions tests). |
| F-90 | Streak | PARTIAL | Server-side, by capture day, 48 h window (`gamification.js`, functions tests); `StreakChip` on profiles. No flame animation, no celebration, not shown in the home area, no "at risk" variant. |
| F-91 | Achievements and rewards | PARTIAL | 12-entry registry, server unlocks (functions tests), Achievements page, profile card, privacy toggle. No unlock animation or toast, no "capsules viewed" metric, no exploration view. |
| F-92 | Placeholder Material icons | PARTIAL | Material icons through `AchievementIcon`. The asset override (`assets/achievements/<id>.png`) is **not implemented**, although DECISIONS D-16 says it is. |
| F-93 | Loop capsule | FLAGGED_OFF | `FeatureFlags.loopCapsules = false`. Built: hold-to-record ≤10 frames, upload, storage rule, outbox, playback in the capsule dialog and full screen. Missing vs prompt: mode toggle, frame strip, delete/reorder, speed setting, thumbnail, looping in map card/list/chat. Emulator: 10 frames uploaded; motion not judgeable (still virtual scene). |

## 2. Tier by tier

**Tier 0.** Built: l10n pipeline and five languages (screens, data layer, pushes); `AppPalette` light + dark (three
candidates compared, charcoal chosen), dark icons, dark map style; Appearance (theme, UI size) and Language pages;
edge-to-edge bars, splash = first frame; disk image cache (F-01..F-03); one sheet system; one segmented control; round
list avatars; nav tab labels; screen-reader labels on icon buttons; token check script; list entrance stagger on
three pushed pages; one date format; empty states for My Capsules; large-text fix for the map card and hint.
Not built: hero transitions, nav pill height, header spec, history control sizes, deterministic gradient
placeholders, share icon, crisp messages icon, F-35 investigation, F-39, hit-area audit, screen recordings and
frame-by-frame inspection, the final performance run, the side-by-side consistency contact sheet, README tooling
section. Not in the prompt: `AppDates` date unification, emulator scripts in the scratchpad (not committed).

**Tier 1.** Built: map card, my-location button, logo padding, memoized markers, heatmap restyle, dark map, 0,0
guard; camera permission fix, pinch zoom, tap focus/exposure point, shutter feedback, flash auto; creation settings,
choice menus with date presets, location asked in creation, offline outbox; notification categories, new server
events, broadcast; chat reply/reactions/copy/delete/quote jump; Privacy settings page.
Not built: clustering, viewport queries, map filters, control cluster, light map colours; zoom stops, exposure slider,
torch, grid, latency measurement; creation step flow, composer, own calendar, manual pin, draft autosave; WorkManager
background upload; notification tab grouping by day, swipe, inline accept/decline, icon badge, end-to-end push test;
chat images, voice, stickers, groups, typing, swipe actions, pinned chats, forward/edit/report message; settings for
who can find/message me, last seen, units, upload quality, save to gallery, download my data.

**Tier 2.** Built: reactions, comments (one level), reports for capsules and comments; follower counts; verified
badge mechanism; friend capsules strip; friends-of-friends suggestions; streak and achievements (server) with profile
card and page; loop capsules (flag off).
Not built: co-authors, quick reply, capsule sharing/deep links, global people search, contacts suggestions, pinned
quick actions, profile section redesign, report for profiles (the menu item exists and does nothing), exploration
view, unlock/streak animations, `entitlements/limits` config and the weekly-limit vs streak note (section 9.4).

**Tier 3.** Built: "Leave your first capsule" map card for new users, "On this day" strip, full-screen photo viewer.
Not built: onboarding tour, friends feed, trip collections, capsule search, widgets.

## 3. Animations and smoothness

### a) Every animation that exists now
All checked on the emulator only unless "tests" or "not checked" is written. None checked on a physical device.

| Animation | Where | Motion token | Checked |
|---|---|---|---|
| Page push/pop (fade) | `app/router/app_page_route.dart` `fadeRoute` | `fast` 150 ms, `enter`/`exit` | emulator |
| Add friends (slide up) | `slideUpRoute` | `fast` 150 ms | emulator; perf harness |
| Achievements page push | `achievements_view.dart` `MaterialPageRoute` | none (platform default) | not checked (inconsistent with `fadeRoute`) |
| Photo viewer open/close (fade + scale 0.94) | `shared/widgets/photo_viewer.dart` | `standard` 200 ms, `emphasizedCurve` | emulator |
| Photo viewer double-tap zoom, drag-to-close, spring back | same | `standard`, `exit` | emulator; tests |
| Sheets and centred menus | `shared/widgets/app_sheets.dart` (`showModalBottomSheet`) | Material default, not a token | emulator |
| Capsule detail dialog | `capsule_detail_dialog.dart` (`showDialog`) | Material default | emulator |
| Nested menu level change | `history/widgets/nested_menu.dart` `AnimatedSize` + `AnimatedSwitcher` | `standard` / `fast` | emulator |
| Tab switch | `IndexedStack`: **no transition**; navbar icon `AnimatedScale` ×1.2 | `standard`, `quick` | emulator |
| Segmented control (notifications, requests) | `app_segmented_tabs.dart` | `standard` | emulator |
| List entrance stagger | `AppStaggerScope/Item` on notifications, my friends, suggestions | `standard` + 35 ms steps, max 10 | tests; emulator (one mid-animation screenshot) |
| Button press scale | `AppPressable` (0.97) | `quick` 100 ms | tests; emulator (not per button) |
| Skeleton → content crossfade | `AppFadeSwitcher`; image fade-in in `AppNetworkImage` | `fast` | emulator |
| Toasts | `popup_notification.dart` | `slow` 300 ms; ignores reduced motion | emulator |
| Count badge | `count_badge.dart` `TweenAnimationBuilder` | `standard` | not checked |
| Page header size/search | `page_header.dart` | `emphasized`, `fast` | emulator |
| Capsule reaction select | `capsule_social_panel.dart` `AnimatedContainer` (colour/border only, no burst) | `fast` | emulator |
| Chat reaction | none (pill appears/disappears) | – | – |
| Map capsule card enter/exit | `map_page.dart` `AnimatedSwitcher` fade + slide | `emphasized` 250 ms | emulator |
| My-location button lift | `AnimatedPositioned` | `emphasized` | emulator |
| Camera fly to user | native `animateCamera` | – | emulator |
| Map markers appear / selection | none | – | – |
| Heatmap ↔ markers at zoom threshold | none (switch) | – | emulator |
| Camera shutter blink | `camera_page.dart` | 120 ms literal + `quick` | emulator |
| Camera focus ring | `camera_page.dart` | `slow`×3 = 900 ms (longer than the style bible's 350 ms rule); ignores reduced motion | emulator |
| Camera zoom hint | `AnimatedOpacity` | `fast` | never exercised (no pinch via adb) |
| Loop recording ring | progress indicator, steps per frame | – | emulator (flag off) |
| Loop playback | `shared/widgets/loop_picture.dart` | frame delay 300 ms | tests only |
| New chat message arrival | `AppEnter` in `chat_page.dart` | `standard`, `enter` | emulator |
| Swipe to reply (tracks finger, spring back, tick) | `_SwipeToReply` | `fast`, `exit` | emulator |
| Quote jump scroll + highlight | `chat_page.dart` | `slow` | emulator |
| Reply bar | `AnimatedSize` | `standard` | emulator |
| Scroll-to-latest button | `AnimatedScale` | `standard` | emulator |
| Theme switch | `MaterialApp.themeAnimationDuration`; dark map is recreated | `slow`, `standardCurve` | emulator (map recreation not inspected frame by frame) |
| Permission onboarding pages | `PageView` | `reveal` 350 ms | emulator |
| Pull to refresh | `RefreshIndicator` in notifications (refresh does nothing) | Material | not checked |
| Hero transitions | none | – | – |
| Achievement unlock, streak flame | none | – | – |
| Empty-state idle motion | none | – | – |
| Capsule creation steps | none (single page) | – | – |

### b) Add friends transition (~15 fps)
Cause from the audit: a 150 ms slide (~9 frames) during which a 50-user query fired, a non-lazy `ListView` built every
row, each avatar resolved a URL, and large icons decoded for the first time. What changed: the suggestions are friends
of friends (fewer, bounded lookups) and the list is `ListView.builder` (`95f1607`). Nothing else (no deferral of the
query until after the transition, no precaching).
Numbers (profile mode, emulator, build/UI thread): baseline 20 frames, build avg 3.0 ms, worst 21.3 ms, 5 % over
16.7 ms; mid-run (`25b5a85`, **before** the lazy list) 49 frames, avg 3.9 ms, worst 25.9 ms, 8.2 % over. **After the
lazy list: NOT MEASURED.** There is no evidence the transition is smoother; the "15 fps" itself was never reproduced
because the emulator rasterizes at ~8-25 fps for any screen.

### c) Frame timings (profile mode, Android emulator Medium Phone API 36, local Firebase emulators, seed of 7 capsules)
Baseline = commit `9cb4be8`, emulator default GPU (raster ~110 ms/frame for any screen). Mid = `25b5a85`, emulator
`-gpu host` (raster not comparable with baseline). **No final run was made**: the "After" section of PERFORMANCE.md is
empty and most of the night's work came after the mid-run.

| Flow | Run | Frames | Build avg / worst (ms) | Raster avg / worst (ms) | Over 16.7 ms build / raster |
|---|---|---|---|---|---|
| Cold start (`startup`) | baseline | 20 | 19.4 / 116.0 | 177.5 / 342.2 | 30.0 % / 85.0 % |
| | mid | 43 | 10.1 / 148.3 | 57.5 / 406.5 | 9.3 % / 86.0 % |
| | final | NOT MEASURED | | | |
| Time to home | baseline / mid | 2938 ms / 2792 ms | | | |
| Tab switch | baseline | 42 | 7.5 / 89.1 | 147.8 / 579.8 | 9.5 % / 97.6 % |
| | mid | 95 | 5.8 / 51.9 | 51.9 / 165.1 | 10.5 % / 91.6 % |
| | final | NOT MEASURED | | | |
| Open/close a sheet | all | NOT MEASURED (the harness measures a settings page push, below) | | | |
| Settings page open/close | baseline | 20 | 1.7 / 9.7 | 115.1 / 202.4 | 0 % / 95.0 % |
| | mid | 45 | 5.1 / 46.4 | 40.5 / 101.9 | 13.3 % / 93.3 % |
| Add friends transition | baseline | 20 | 3.0 / 21.3 | 113.9 / 145.7 | 5.0 % / 95.0 % |
| | mid (before fix) | 49 | 3.9 / 25.9 | 36.3 / 63.8 | 8.2 % / 87.8 % |
| | final | NOT MEASURED | | | |
| Scrolling My capsules | baseline | 138 | 1.1 / 6.1 | 116.0 / 219.3 | 0 % / 98.6 % |
| | mid | 216 | 2.1 / 75.9 | 42.9 / 103.8 | 0.5 % / 93.1 % |
| Map pan, many capsules | all | NOT MEASURED with many capsules; pan with 7 capsules: baseline 55 frames 0.8 / 2.9, 109.6 / 136.9, 0 % / 98.2 %; mid 135 frames 1.5 / 18.0, 41.8 / 112.6, 0.7 % / 97.0 % | | | |
| Open a long chat | baseline | 18 (short chat) | 3.5 / 23.2 | 153.7 / 637.9 | 5.6 % / 94.4 % |
| | mid / final | NOT MEASURED (no chat for the test account) | | | |
| Camera open (+ capture) | baseline | 17 (open/close, no capture) | 1.8 / 18.2 | 225.1 / 887.1 | 5.9 % / 88.2 % |
| | mid | 63 | 3.6 / 54.6 | 53.7 / 321.1 | 3.2 % / 87.3 % |
| | capture | NOT MEASURED | | | |
| Capsule creation steps | all | NOT MEASURED | | | |
| Theme switch | all | NOT MEASURED | | | |

Notifications tab switch (not in the list): baseline 2.1 / 6.6 ms build, 0 % over; mid 4.1 / 24.4 ms, 5.0 % over.

### d) Still outside budget or choppy
- Against the prompt's budget (<1 % of frames over 16.7 ms), **no flow meets it on raster**, and on build time
  cold start (9.3 %), tab switch (10.5 %), settings open (13.3 %), add friends (8.2 %), notifications tabs (5 %) and
  camera open (3.2 %) miss it in the last run. These are first-build costs that were identified but not fixed.
- Unknown on real hardware: everything (raster on a phone was never measured).
- Feels abrupt to me: tab switches (instant swap), map markers popping in at the zoom threshold, sheets all sliding
  from the bottom, the dark map being recreated on theme switch.
- Missing from the prompt: hero transitions (avatars, capsule photos), reaction burst, marker appear/selection,
  creation step transitions, achievement unlock and streak flame, pending → sent morphs for capsules, empty-state idle
  motion, chat image viewer hero, pull to refresh that does something.

### e) Hit-area audit
**Not done.** STYLE_BIBLE has the 44×44 checklist line, but no screen-by-screen audit was run. Known undersized
targets from the code (`DefaultIconButton` hit area = icon size): reply-bar close (22 dp), first-capsule-hint close
(22 dp), camera flash button (40 dp), the reaction pill under chat bubbles (~24 dp tall). Nothing was checked for
controls hidden by the keyboard or the nav pill beyond the screens fixed this night (comments composer, password reset,
map card/logo).

### f) Design token check
`tool/check_design_tokens.dart` exists and passes ("no violations (251 files)"), also in CI. It has an allow-list
(`tool/design_tokens_allowlist.txt`, 46 lines) for Material icons the design already used and achievement icons.

### g) Reduce motion
Checked by widget tests only (`test/shared/motion_test.dart`: `AppPressable` and `AppEnter`;
`loop_picture_test.dart`). Never toggled on the emulator or a phone. Known gaps in code: toasts and the camera focus ring
ignore it; sheets/dialogs use Flutter defaults (not verified).

## 4. Notifications

| Event | Implemented | Tested how | Foreground / background / terminated |
|---|---|---|---|
| New message | yes (`sendMessageNotification`, polish) | functions tests (`notify.test.js`: text, mute, quiet hours, preview off) | not tested in any app state |
| Group message | no (no groups) | – | – |
| Friend request received | yes (`onFriendRequestCreated`) | functions tests (`social.test.js`) | not tested |
| Friend request accepted | yes (`onFriendRequestUpdated`) | functions tests | not tested |
| New follower | yes (`sendFollowerNotification`, polish) | functions tests | not tested |
| Followed user posted | yes (`sendCapsuleNotification`) | functions tests (public / friends / private) | not tested |
| Reaction | yes (`onReactionWritten`, first reaction only) | functions tests | not tested |
| Comment | yes (`onCommentCreated`) | functions tests | not tested |
| Reply | yes (to the parent comment's author) | functions tests | not tested |
| Co-author invite | no (no co-authors) | – | – |
| Achievement | yes (`unlockAchievements`) | functions tests | not tested |
| Streak reminder | yes, opt-in, 19:00 local (`sendStreakReminders`, hourly); no "at risk" variant | functions tests | not tested |
| Developer announcement | yes, push only (`sendAnnouncement` + `tools/admin/announce.js`, topics `news_<lang>`) | functions tests | not tested; **not shown in the in-app tab** (`watchAnnouncements` is never used by the UI, contrary to D-17) |
| Capsule unlock date reached | no | – | – |

- **Settings:** master toggle; categories messages, follows, capsules, friend requests, reactions, comments,
  achievements, news, streak reminder; preview; sound; quiet hours; per-chat mute; permission status page. No
  vibration toggle.
- **Server enforcement:** `functions/lib/prefs.js` before every send (tests). Blocking checked for reactions,
  comments, requests (tests).
- **Token lifecycle:** `users/{uid}/fcmTokens/{token}` per device, refresh listener, `deleteToken` on sign-out, server
  prunes invalid tokens (test "dead tokens are removed").
- **Tap routing:** `notification_router.dart` via `getInitialMessage`/`onMessageOpenedApp`: message → chat; follow /
  accepted → profile; request → requests page; reaction/comment/reply/capsule → map focused on the capsule (not the
  comments sheet); achievement → profile tab; announcement → nothing. **No router tests.** No background handler on
  purpose (POL-001).
- **Badges:** in-app tab counts only. App icon badge not implemented (iOS badge permission is requested, never set).
- **In-app tab:** exists (All/Replies/Comments, selection mode to mark read/delete). Not grouped by day, no swipe,
  no inline accept/decline, pull to refresh does nothing.
- **Admin broadcast:** callable guarded by the `admin` custom claim; functions test "a normal user (or nobody) cannot
  send one" passes. Usage in `docs/ux/ADMIN.md` (grant the claim with `tools/admin`, then `node announce.js`).
- **Emulator only:** every server path ran only inside the functions test suite (43/43, last run with the
  functions code unchanged since `cad1365`). The app never ran together with the functions; no push was ever delivered
  to the emulator. **Needs a real phone / real APNs:** delivery in all three states, tap routing, channels, quiet hours
  with real time zones, iOS at all, OEM battery optimizers.

## 5. Chat and messages

| Item | State |
|---|---|
| Conversation list redesign | partial (polish redesign + round avatars, unread, muted); new-chat icon still 36 px; no typing, pinned chats, swipe actions |
| Opens at latest message | yes |
| Bubbles and grouping | yes (polish) |
| Read receipts | yes (one `lastReadAt` per reader, privacy switch both ways) |
| Typing indicator | no |
| Reply | yes (swipe or menu, quote, jump to original) |
| Reactions | yes |
| Delete | yes, for both (own messages); no "delete for me" |
| Images | no |
| Voice messages | no |
| Stickers and packs | no |
| Group chats | no |
| Capsule sharing in chat | yes (send a capsule to a friend; card with photo) |
| Offline sending | partial: optimistic with "Not sent · Tap to retry"; sending uses a transaction, so nothing is queued while offline |
| Forward, edit, report message, unread divider | no |

## 6. Map, camera, creation

- **Map performance:** cause found in code (new marker set on every build, position updates and three streams
  rebuilding the whole map, heatmap rebuilt each time); fix: markers/heatmap memoized on `capsulesVersion`. Not done:
  clustering, viewport-bounded queries (own capsules unbounded, friends via `whereIn` chunks, public band limit 300).
  Not measured with many capsules, not on a device.
- **Controls:** zoom buttons off (pinch only), compass only moved below the status bar, my-location button added,
  no control cluster.
- **Style:** light = owner's cloud style (unchanged greens), dark = local JSON (D-07). **Heatmap:** single brand green,
  shown only zoomed out (D-19): red means danger in the app, yellow turns olive on the dark map, brand-coloured
  clusters need custom cluster icons the plugin cannot draw.
- **Popup:** own card, dismissible five ways. **Filters:** none.
- **0,0 / Niger:** the app code never writes 0,0; a failed fix could; now blocked in the client, rules and map.
  The production documents were not inspected.
- **Camera:** tap-to-capture latency NOT MEASURED (before or after). Pinch zoom (unexercised), tap focus + exposure
  point, flash off/auto/on, no torch, no exposure slider, no grid, no zoom stops; hold-to-record loops behind the flag.
- **Creation:** single page (no steps); location: last known position at once, background fix, permission asked,
  cached place name, no manual pin; date: presets + stock calendar; composer unchanged; settings: visibility, date,
  colour, comments, reactions, approximate location; no drafts autosave (leaving loses the photo except when queued
  offline); offline queue as in F-26.

## 7. Social, settings, gamification, localization, dark theme

- **Profiles/friends:** friend capsules strip, counts, verified badge, achievements on profiles; no section
  redesign, no pinned quick actions. **Search/suggestions:** username search on Add friends (unchanged entry through
  the profile); suggestions = friends of friends with mutual counts, never the user list (PRIVACY.md); no contacts.
- **Follower counts:** server counters + backfill. **Verified:** field only writable by admin scripts / functions
  (user rules list client-writable keys; rules tests prove a user cannot set it).
- **Reactions, comments:** capsules yes. **Share and deep links:** profile share only (polish); no capsule share.
  **Co-authors:** no. **Report:** capsules and comments; the profile "Report" item does nothing (TODO); no message
  report. **Block:** existing (polish).
- **Settings groups:** Account (email, password, username, name, delete account, sign out), Appearance, Language,
  Notifications, Privacy (default visibility, approximate location, read receipts, show achievements), Permissions,
  Map and camera (map look, start camera), Data and storage (cache size, clear), Blocked users, Help (FAQ, contact,
  copy info), About (version, privacy, terms, licenses). Options added this mission work on the emulator (tests for
  the stores). Missing: who can find/message me, last seen, units, upload quality, save to gallery, mobile data,
  download my data, linked providers.
- **Streak/achievements:** server-side (functions). `AchievementIcon` draws a Material icon on a level ring;
  **no asset override** (D-16 is wrong about that). Exploration: places counted server-side (≈5 km cells) for the
  Explorer achievement; no world-progress view.
- **Languages:** en, ru, pl, de, es complete per `l10n_completeness_test.dart` (every key and placeholder in all five;
  ARBs built from fragments, `tool/l10n/unused_keys.js`). Push texts localized in `functions/lib/i18n.js`. All
  non-English text was written by me, not reviewed by native speakers; Russian uses the system font because the app
  font has no Cyrillic (BLOCKERS). Checked on screen: Russian (several screens), German only by tests.
- **Dark theme:** three palettes compared (charcoal, forest, slate; `dark_candidates/sheet.png`), charcoal chosen
  (D-03). Checked in dark on the emulator: welcome, login, map, history, messages, chat, profile, settings, capsule
  dialog, comments, creation and its menus, achievements, friend profile, requests, sheets.

## 8. Backend and tests

- **Flutter:** 264 passed, 1 skipped (pre-existing `fake_cloud_firestore` GeoPoint case); goldens run on Windows only
  (CI excludes them). **Rules:** 57/57 (Firestore + Storage). **Functions:** 43/43. **Integration:** only the
  performance harness (`integration_test/perf_test.dart`: startup, tab switches, notifications tabs, settings,
  add friends, history scroll, map pan, camera open/close, open chat). No functional integration tests (sign in,
  create capsule, react, comment, follow, chat, theme/language switching).
- **New collections:** `capsules/{id}/reactions/{uid}`, `capsules/{id}/comments/{id}`, `users/{uid}/achievements/{id}`,
  `reports`, `announcements`. **New fields:** capsule `capturedAt`, `utcOffsetMinutes`, `showAuthor`, `allowComments`,
  `allowReactions`, `locationPrecision`, `frames`, `frameDelayMs`, `thumbUrl`, `placeName`, counters; user
  `followerCount`, `followingCount`, `verified`, `stats.*`; settings `language`, `privacy`, new notification keys;
  message `replyTo`, `reactions`. **Indexes:** `reactions.uid`, `comments.authorId`, `settings.notifications.streakReminder`
  field overrides. **Functions:** 13 new (DEPLOY.md). **Storage:** `frame_0..9.jpg`.
- **Backward compatibility:** writes fall back once to the old capsule shape and old notification keys when the rules
  reject new fields (code + tests); mappers read old documents (tests). Not tested against a copy of production data.
- **Three most expensive per screen:** Map: own capsules (unbounded stream), friends' capsules (`whereIn` chunks of 30),
  public band (≤300). History: the same unbounded own-capsules stream. Capsule dialog: reactions (≤100) and comments
  (≤200) queries while open. Chat: messages page of 50 + chat list ≤200.
- **Unbounded:** own-capsules query; `sendCapsuleNotification` reads every follower and one document per follower
  (fan-out not capped); `unlockAchievements` runs on every user-document write.

## 9. Not verified (and the manual check)

| Item | Manual check on a real phone |
|---|---|
| All performance | Profile build on a mid-range Android: DevTools frame chart for cold start, tab switch, add friends, history scroll, map pan with ~2,000 capsules, chat open, camera, theme switch; target <1 % janky frames. |
| Push notifications (all types) | Deploy to a dev project; for each event, app in foreground, background, killed: arrives once, right language, tap opens the right screen; muted chat and quiet hours stay silent. |
| Announcements | Send one with `announce.js`; arrives per language; note it does not appear in the app's tab. |
| iOS | Build and run once: permissions, edge-to-edge, camera, push (APNs). |
| Camera | Pinch zoom, tap focus/exposure, flash auto/on firing, time from tap to creation page, blur. |
| Loop capsules | Set the flag, hold the shutter with moving subject: loop plays smoothly in the dialog and full screen, upload size. |
| Offline capsules | Airplane mode, create, kill the app, restore network, reopen: uploaded once at the original place and time. |
| Streak/achievements | With functions deployed: create capsules on consecutive days; counts, unlock push. |
| Follower counts / verified | After backfill: counts right; verified badge on the three accounts. |
| Password reset | Request a reset email and complete it. |
| Dark theme / large text | Whole app at system text 130 % and in dark on a small (360 dp) phone. |
| Reduce motion | Turn on "Remove animations": pages, sheets, toasts, camera ring. |
| Russian / German | Every screen; Russian titles in the fallback font. |
| Map controls | Rotate the map: compass position; Google logo visible with card and hint open. |

## 10. Known bugs and risks

1. Announcements are never shown in the in-app notifications tab (D-17 says they are).
2. `AchievementIcon` has no asset override (D-16 says `assets/achievements/<id>.png` is used).
3. Profile menu "Manage friendship → Report" does nothing (`friend_options_modal.dart:140`, TODO).
4. PERFORMANCE.md "After" is empty; F-38's fix was never measured; no recordings exist.
5. Stale docs: REPORT.md "Not done" still lists chat reactions/replies; ACHIEVEMENTS.md says loop capsules are not
   built; FEEL_QA marks screens ✓ from emulator checks only.
6. Undersized tap targets: reply-bar close 22 dp, first-capsule-hint close 22 dp, flash 40 dp, chat reaction pill.
7. Notification taps for reactions/comments open the map, not the comments.
8. Chat messages cannot be sent offline (transaction); capsules for a friend are not queued offline.
9. Offline uploads only run while the app is open (no WorkManager); refused capsules show no retry action.
10. Emulator-only intermittent denial of the first write after reconnect (BLOCKERS); unknown on production.
11. Nav pill height, header sizes, history control sizes, messages icon (36 px), share icon, avatar placeholder,
    friends section header: unchanged, still off per the original findings.
12. Camera focus ring animates 900 ms (style bible says ≤350 ms) and ignores reduced motion; toasts ignore reduced
    motion.
13. Achievements page uses `MaterialPageRoute` (different transition from every other page).
14. Dark map is recreated on theme change (possible flash; not inspected).
15. Cyrillic falls back to the system font.
16. iOS `Info.plist` still has microphone/contacts usage strings for features that were removed.
17. Unbounded reads: own capsules, capsule follower fan-out; `unlockAchievements` on every user write.
18. Translations not reviewed by native speakers.
19. Verified username "amo b3" unconfirmed.
20. One skipped test (pre-existing); goldens not run in CI.
21. Loop capsules: no frame editing, speed, thumbnail or looping outside the dialog/viewer.
22. `entitlements/limits` config and the weekly-limit vs streak note (prompt 9.4) were not done.

## 11. PR and deploy state

- **PR #77** (polish): open, ready for review, mergeable, CI green (`9294d02`). Its backend (rules, functions,
  hosting) was deployed to production earlier with the owner's explicit authorization, before this mission.
- **PR #78** (this branch): open, **draft**, mergeable. CI on `014957d`: analyze/test/token job passed, Android
  build passed, iOS build still running when this was written. Last fully green run including iOS: `c64ebf5`. Runs in between
  were cancelled by newer pushes (their analyze/test jobs passed).
- Nothing was merged. Nothing was deployed during this mission. No tags, no version bump.

Next steps, in order:
1. Merge PR #77 (`gh pr merge 77 --merge`); this publishes the polish release.
2. Decide on #78's backend: deploy to a **dev** Firebase project first (Firestore rules + indexes, Storage rules, the
   13 functions created with gcloud as in DEPLOY.md, then `firebase deploy --only functions`), run the backfill.
3. Install the #78 build against that project on a real Android phone (and iOS if possible) and do the section 9
   checks, push notifications first.
4. Fix what that finds; decide on loop capsules (flag).
5. Deploy the same backend to production (DEPLOY.md), confirm the verified usernames, update the privacy policy.
6. Mark #78 ready and merge (this publishes a release).

## 12. Honest opinion

| Area | Rating | Why | Most valuable next fix |
|---|---|---|---|
| Smoothness and feel | 5/10 | Many interactions got real motion and feedback, but nothing was measured after the work, raster was never measured on hardware, and tab switches, sheets and markers still pop. | A profile-mode run on a real phone of every section-0.5 flow, then fix first-build jank (startup, tab, settings, add friends). |
| Style consistency | 6/10 | Menus, sheets, tokens, dark theme and five languages are consistent, but several original findings (nav pill, headers, history controls, icons, placeholders) are untouched. | Do the header spec, nav pill height and history control sizes in one pass with before/after screenshots. |
| Notifications reliability | 4/10 | Server logic is broad and unit-tested, but no push has ever been delivered to a device from this branch and announcements are invisible in the app. | Deploy to a dev project and run every event on a real phone in the three app states. |
| Chat quality | 5/10 | Reply, reactions, delete and quote jump work well on the emulator, but there are no images, voice, stickers, groups or typing, and nothing sends offline. | Image messages with cached viewer (most used missing feature). |
| Overall readiness to ship | 4/10 | Tests are green and the app works against the old backend, but the new features need an undeployed backend, nothing ran on a physical phone or iOS, and some docs overstate what exists. | Steps 2-3 of section 11 before anything else. |

## 13. Addendum: the feel pass on a real phone (checkpoint A)

Branch `feature/feel-pass-real-device`, draft PR #79 (stacked on #78). Checked on a **Samsung Galaxy S20 FE**
(Android 13, 120 Hz, 360 × 800 dp; `docs/feel/DEVICE.md`) in profile builds, against the local Firebase emulators
seeded with `tool/seed_heavy.js` (104 people, 2,002 capsules, a 600-message chat). Numbers:
`docs/feel/PERFORMANCE.md`; what was looked at, and how: `docs/feel/FEEL_QA.md`. Still nothing on iOS, and no push
was delivered (no dev project; `docs/feel/BLOCKERS.md`). Sections 1–12 above are left as they were written.

### Findings whose status changed
| ID | Was | Now | Evidence |
|---|---|---|---|
| F-10 | PARTIAL | DONE_VERIFIED (drawing) / PARTIAL (queries) | Only on-screen capsules become markers, clustered on a 64 px grid, never more than 150 (`map_clusters.dart`, `map_clusters_test.dart`); one shared pin set. Phone, 2,002 capsules: map pans and zooms 0 % janky (Flutter side); Android main-thread stalls **4,351–6,548 skipped frames per run (10–12 s freezes) → launch only (≤ 150)**. Queries are still not viewport-bounded (own capsules unbounded, friends `whereIn`, public band 300). |
| F-11 | PARTIAL | DONE_VERIFIED | Google's compass off; our compass sits above the zoom pill and shows only while the map is turned (`map_compass.dart`, `map_compass_test.dart`). Phone: a two-finger twist in the perf test turned the map to 296°, a tap on the compass brought it back to 0° (`map_compass` flow, 0 % janky). |
| F-12 | PARTIAL | DONE_VERIFIED | Zoom pill (two 52 dp halves) above the my-location button, both lift with the card; phone (FEEL_QA). |
| F-15 | PARTIAL | DONE_VERIFIED (owner to compare) | Local light style, no map ID; the map is restyled in place on a theme switch (D-22). Compare with the cloud style before release (BLOCKERS). |
| F-17 | DONE_VERIFIED | DONE_VERIFIED, richer | The card shows the capsule's photo (or the pin while locked), which flies into the dialog and on to full screen. Author, distance and reaction count are still not on the card. |
| F-19 | PARTIAL | PARTIAL | Measured on the phone (above); queries remain. |
| F-20 | PARTIAL | DONE_VERIFIED | Zoom stops (0.5 / 1 / 2 / 5×, those the lens has) with an eased move; a real two-finger pinch in the perf test reaches 3.8× on the phone (3 of 3 runs). |
| F-21 | PARTIAL | PARTIAL | Brightness slider after tap to focus; no grid or other settings. |
| F-22 | PARTIAL | PARTIAL (measured) | Tap → shutter feedback frame **24 ms** (the preview holds still at once), tap → file 1,083 ms, tap → creation page **1,111 ms** (CameraX `takePicture`; budget < 300 ms perceived is met by the feedback, not by the page). Blur not addressed. |
| F-23 | PARTIAL | DONE_VERIFIED | Off → auto → on → torch, cycle checked on the phone in 3 of 3 runs (`camera_flash_step_*`). |
| F-30 | PARTIAL | DONE_VERIFIED | Compose icon redrawn at 144 px with a dark variant (`tool/make_compose_icon.dart`); phone. |
| F-31 | PARTIAL | DONE_VERIFIED | Controls 44 dp with 24 dp icons, search 17 sp, on the shared scale; phone tap audit clean. |
| F-33 | PARTIAL | DONE_VERIFIED | Header from the real status-bar inset + 8, title 32; phone, light and dark. |
| F-34 | NOT_DONE | DONE_VERIFIED | Pill 68 dp (was 80), fixed tab slots so the icons no longer jiggle; lists end clear of it; phone. |
| F-35 | NOT_DONE | NOT_DONE (not reproduced) | My capsules scrolled to the end and back: 0 % janky in all 6 phone runs (baseline and after). The jitter as the team saw it was not reproduced; physics unchanged. |
| F-37 | PARTIAL | DONE_VERIFIED (motion) | Centred cards rise and grow in over a painted scrim and close with a drag (`AppCardRoute`); sheets use the token motion. Stacked-modal separation not addressed separately. |
| F-38 | DONE_UNVERIFIED | DONE_VERIFIED | Add friends transition 2.5 → 1.2 % janky on the phone (worst frame still 22.6 ms, over the 16.7 ms rule). |
| F-39 | NOT_DONE | DONE_VERIFIED | "Friends" title, loading tiles, empty state with a way to Add friends; phone. |
| F-40 | PARTIAL | DONE_VERIFIED | Per-person gradient from the user id (FNV-1a) for avatars and backgrounds (`user_placeholder.dart`, test); phone. |
| F-43 | NOT_DONE | DONE (owner to approve) | Usual share sign in the profile icons' ring and stroke (`tool/make_share_icon.dart`, `docs/feel/icons/share.svg`). |
| F-44 | PARTIAL | PARTIAL | Sweep on the phone in light/dark, ru/en and 130 % text (FEEL_QA); German, Polish, Spanish by tests only. |
| F-45 | PARTIAL | DONE_VERIFIED (except map markers) | One page route with edge back swipe, tabs, cards, photo heroes, reaction bursts, idle empty states, pending → date and save morphs, achievements and streak motion (`docs/feel/MOTION_CATALOG.md`). Native marker motion not built (Google Maps markers are drawn on Android's main thread). |
| F-92 | PARTIAL | DONE_VERIFIED (mechanism) | `assets/achievements/<id>.png` overrides the icon (`AchievementIcon.preloadArt`, `achievement_art_test.dart`, ACHIEVEMENTS.md). No artwork is shipped yet. |

### Section 3 on the phone
- **Frame timings**: measured, 3 runs per flow, baseline and after (PERFORMANCE.md). The theme switch went from
  16.8 % janky with a ~10 s freeze after every switch to 0.4 % and no freeze; settings 12.4 → 3.3 %;
  notifications segments 10.8 → 1.1 %.
- **Hit areas**: audited on the phone (`tool/dev/tap_audit.sh`); every finding fixed to 44 dp (D-24,
  `tap_targets_test.dart`).
- **Reduce motion**: every new motion honours it in code and widget tests; it was **not** switched on on the phone.

### Section 10, bug by bug
| # | Now |
|---|---|
| 1 | Open (Part B6). |
| 2 | Fixed (`7f5f064`). |
| 3 | Open (Part B2). |
| 4 | Fixed: "After" filled from 3 phone runs; F-38 measured. No video (no ffmpeg); stills from the phone in `docs/feel/after/`. |
| 5 | Fixed (REPORT, ACHIEVEMENTS); `docs/ux/FEEL_QA.md` now points to the phone checks in `docs/feel/FEEL_QA.md`. |
| 6 | Fixed (44 dp, phone audit). |
| 7 | Open (Part B2). |
| 8 | Open (Part B1 messages, B4 friend capsules). |
| 9 | Open (Part B4). |
| 10 | Not seen on the phone rig; unknown on production. |
| 11 | Fixed (pill, headers, history controls, compose icon, share icon, placeholders, friends title). |
| 12 | Fixed (ring ≤ 350 ms; ring and toasts honour reduced motion). |
| 13 | Fixed (achievements open on the app route). |
| 14 | Fixed: the map is restyled in place, never recreated. |
| 15 | Open, owner decision (BLOCKERS). |
| 16 | Open (the microphone string comes back with voice messages, Part B1). |
| 17 | Open (Part B6). |
| 18–20 | Open. |
| 21 | Open (Part B4). |
| 22 | Open (Part B7). |

### Ratings at checkpoint A
| Area | Was | Now | Why |
|---|---|---|---|
| Smoothness and feel | 5/10 | 7/10 | Measured on a phone; scrolls, pans, zooms and the camera are within budget; the freezes are gone. Opening things still costs 1–3 % janky frames (first text layout and Impeller's glyph atlas) and startup 6.6 %; the capsule dialog regression (3.2 %) was found and fixed (0.6 %). |
| Style consistency | 6/10 | 7.5/10 | The original findings on pill, headers, controls, icons, placeholders and friends are done and checked on the phone in both themes; the font mix in Russian remains (owner). |
| Notifications reliability | 4/10 | 4/10 | Unchanged until Part B6; still no push delivered. |
| Chat quality | 5/10 | 5/10 | Unchanged until Part B1. |
| Overall readiness to ship | 4/10 | 5/10 | Feels much better on Android hardware, but the backend from #78 is still undeployed and nothing ran on iOS. |
