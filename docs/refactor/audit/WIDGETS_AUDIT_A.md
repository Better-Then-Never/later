> Appendix to AUDIT.md / DESIGN_SPEC.md. Produced by a read-only audit pass over the files listed below on 2026-10-16 (before any refactor change) and spot-checked against the code. Line numbers refer to commit 9f17db0.

# Audit A: shared widgets, capsule creation, history, map, notifications, share_profile, user, styles

Scope: every line of 47 files (3,504 LOC) was read in full. The repo was not modified.
Paths are relative to `D:\Projects\Later\later\lib\views\` unless they start with `lib/`.
Global context checked: `lib/main.dart:178-184` sets `ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green), fontFamily: "Irina")`, and Material 3 is on by default. `pubspec.yaml:122-128` registers family **"Irina"**, but the files are **Inria Sans** (`assets/fonts/IrinaSans/InriaSans-{Regular,Bold,Italic}.ttf`), so the name is a typo. Only weights **400 and 700 (plus 400 italic)** exist. `FontWeight.w500` renders as 400 and `w900` renders as 700, so neither weight exists as a distinct visual.

---

## 1. Per-file summary

### widgets/_common/decorations
| File | What it is | Used by |
|---|---|---|
| `box_decorations.dart` | Static `BoxDecoration` factory: `whiteCard`, `greyCard`, `blackShadow`, `softBlackShadow`, `redWithBorderRadius`, `lightBlueInfo`, `defaultBorderRadius` | 20 files. Call counts outside the file: whiteCard 16, greyCard 1, blackShadow 2, softBlackShadow 1, lightBlueInfo 1, defaultBorderRadius 2, **redWithBorderRadius 0 (UNUSED)** |

### widgets/_common/default_buttons
| File | What | Used by |
|---|---|---|
| `default_button_with_icon.dart` | Grey pill (default `greyCard`) with InkWell, 32px asset icon and FittedBox text | your_friend_profile_page, history_page, add_friends_action_buttons_row |
| `default_green_button.dart` | Green `ElevatedButton` sized as a fraction of the screen, with a loading spinner | capsule_creation_page, name/username settings pages, choose_pinned_friends_dialog, pinned_friends_selection_dialog |
| `default_icon_button.dart` | `GestureDetector` + `Opacity` + an asset image (or custom child). Default size is 0.11 x screen width | 8 files incl. GoBackButton, DefaultSearchBar, NotificationSelectionActionBar, capsule_creation_page |
| `default_text_button.dart` | `TextButton` using `TextButtonStyles.profileTextButtonStyle` and DefaultText | profile_page_my_capsules_panel, profile_page_my_friends_panel |

### widgets/_common/default_elements
| File | What | Used by |
|---|---|---|
| `confirm_dialog.dart` | Centered white card shown through `showModalBottomSheet`, with a red confirm button and a grey cancel text button | notifications_page, settings_page, history_page |
| `default_empty_inbox_info.dart` | Empty state: 72px icon, title and subtitle | my_friends_page, friend_requests_received/sent_list, notifications_list |
| `default_loading_container.dart` | Grey placeholder box with a 20px spinner | add_friend_profile_background_image |
| `default_search_bar.dart` | Grey pill with a magnifier asset, a borderless TextField and an optional trailing DefaultIconButton | add_friends_page, my_friends_page, history_page, pinned_friends_selection_dialog_header, PageHeader (type) |
| `default_text.dart` | `Text` wrapper. Defaults: Irina, 14, normal, black, centered | 35 files |
| `later_loading_bar.dart` | Logo GIF with an optional message | permission_gate_page, map_page, profile_background_picture, profile_picture |
| `navbar_widget.dart` | Bottom floating white navbar with 4 tabs and a center "add" button that pushes `/camera` | widget_tree |
| `page_header.dart` | White header with rounded bottom corners: title, optional leading/trailing button, description, search bar and an action row | 10 pages |
| `popup_notification.dart` | Animated toast (`StatefulWidget`, `TickerProviderStateMixin`) | lib/services/popup_notification_service.dart |
| `shadow_top_overlay.dart` | 1px-high container with the `blackShadow` decoration, used as a shadow strip | your_friend_profile_page, add_friend_profile_header |
| `white_circular_progress_indicator.dart` | White 16px spinner | add_friend_profile_request_handle_button |

### widgets/_common/options_elements
| File | What | Used by |
|---|---|---|
| `options_input_field.dart` | White, shadowed, 50px-high TextField at 0.92 x screen width | name_settings_page, username_settings_page |
| `options_settings_row.dart` | Settings `ListTile`: leading asset, bold title, chevron asset (`go_here.png`) at 30% opacity, divider, optional `navigateTo` with a 10ms fade | settings_page, capsule_creation_page |

### widgets/_common/premade_buttons
| File | What | Used by |
|---|---|---|
| `go_back_button.dart` | `DefaultIconButton` subclass that pops. Has a black/white asset variant | 9 pages |
| `refresh_button.dart` | Blue circle with a refresh icon or spinner | **UNUSED** |

### widgets/capsule_creation
| File | What | Used by |
|---|---|---|
| `capsule_creation_cycled_info.dart` | Translucent grey pill (0.4 x screen width) showing the current cycled value, with an optional pin icon | capsule_creation_page (trailing of OptionsSettingsRow) |
| `capsule_creation_datestamp.dart` | Green pill with white bold date `dd.MM.yyyy` (defaults to `DateTime.now()`) | capsule_creation_page, map/opened_capsule_widget |
| `capsule_creation_description_input.dart` | Borderless multiline TextField that **returns an `Expanded`**. maxLength 2200 | capsule_creation_page |
| `capsule_creation_location_label.dart` | Yellow pill showing a reverse-geocoded locality, plus a white circle icon | capsule_creation_page, map/opened_capsule_widget |
| `capsule_creation_title_input.dart` | Borderless bold 25pt TextField. maxLength 30 | capsule_creation_page |
| `capsule_image_preview.dart` | `Image.file` clipped to radius 25 | capsule_creation_page |
| `capsule_privacy_dropdown.dart` | `DropdownButton<CapsulePrivacy>` | **UNUSED** |

### widgets/history_page
| File | What | Used by |
|---|---|---|
| `capsule_list_tile.dart` | Stateful card: thumbnail, title, pin, favourite heart, countdown, privacy, distance, address pill, date pill. Runs a 1s timer per tile | history_page |
| `capsule_selection_action_bar.dart` | `SelectionActionBar`: "N selected", Cancel and Delete text buttons between dividers | history_page |
| `menu_item_node.dart` | Data class for NestedMenu (label, onTap, children) | history_page, nested_menu |
| `nested_menu.dart` | Drill-down menu inside a Dialog, with a back arrow | history_page (filter and sort dialogs) |

### widgets/map
| File | What | Used by |
|---|---|---|
| `capsule_info_widget.dart` (class **CapsuleInfoPanel**) | Map info window: title, date, live countdown, Open/Locked button. 1s timer | map_page (twice: lines 115, 213) |
| `opened_capsule_widget.dart` (class **CapsulePreviewCard**) | Dialog card: network image, title, description, location pill, date pill | map_page:301 |

The file names do not match the class names.

### widgets/notifications
| File | What | Used by |
|---|---|---|
| `notifications_list.dart` | Filtered list driven by `PushNotificationService` (Provider) and `NotificationsPageController`. Has pull-to-refresh, empty states and tap handling | notifications_page (3 tabs) |
| `notification_avatar.dart` | `CircleAvatar` that loads a URL or an asset | notification_item |
| `notification_filter_tabs.dart` | TabBar with a green pill indicator: "All", "Replies", "Comments" | notifications_page |
| `notification_item.dart` | Card: avatar, rich text, timestamp, thumbnail, unread dot. Selected and unread states | notifications_list |
| `notification_selection_action_bar.dart` | White card with count, mark-read, delete and close icons | notifications_page |
| `notification_thumbnail.dart` | 50px rounded network/asset image with error fallback | notification_item |
| `notification_timestamp.dart` | Relative time text | notification_item |
| `notification_unread_indicator.dart` | 8px blue dot | notification_item |
| `unread_notification_badge.dart` | Red count badge (Provider-driven) | profile_page_header_action_buttons |

### widgets/share_profile, widgets/user, styles, pages
| File | What | Used by |
|---|---|---|
| `share_profile/share_profile_qr.dart` | White card with a QR code. Takes `screenWidth` as a parameter | share_profile_page |
| `user/user_background_image.dart` | `ValueListenableBuilder` on `UserImageService.getBackgroundNotifier` | profile_header_background_image, user_rounded_background_image |
| `user/user_list_tile.dart` | ListTile: round avatar, name, @username. Takes `screenWidth` as a parameter | my_friends_grouped_by_letter_list |
| `user/user_name_and_username.dart` | `FutureBuilder` on `UserDataService.getUserData`, showing name and @username | share_profile_page, add_friend_profile_page, your_friend_profile_page, profile_page_header |
| `user/user_profile_image.dart` | `ValueListenableBuilder` on `getProfileNotifier` | pinned_friend_avatar, user_round_avatar, user_square_avatar |
| `user/user_round_avatar.dart` | `ClipOval` around UserProfileImage | 7 files |
| `user/user_rounded_background_image.dart` | Background image with bottom radius 25, default height 270 | add_friend_profile_header |
| `user/user_square_avatar.dart` | `ClipRRect(12)` around UserProfileImage | your_friend_profile_page |
| `styles/elevated_button_styles.dart` | `roundedButtonStyle` (4 uses) and `cancelButtonStyle` (**UNUSED**) | share_profile_page, add_friend_profile_main_button, add_friend_profile_request_handle_button |
| `styles/text_button_styles.dart` | `profileTextButtonStyle` | default_text_button only |
| `pages/capsule_related_pages/capsule_creation_page.dart` | Create Capsule screen: preview card, settings card, Create button | camera_page:107 (via `pushReplacement`) |

---

## 2. Bugs / defects

Severity: **H** = crash, data loss or broken feature; **M** = visible defect, leak or likely runtime error; **L** = code smell or minor.

### 2.1 Crashes and null-safety
| # | Location | Symptom | Root cause | Sev |
|---|---|---|---|---|
| B1 | `widgets/history_page/capsule_list_tile.dart:196` | Red error screen or crash for any capsule without `location` | `distanceInKm(location!)`. `location` is nullable (lines 47-52), but the null case is never handled | H |
| B2 | `widgets/notifications/notification_avatar.dart:17-19` with `lib/services/push_notification_service.dart:381` and `functions/index.js:269` | Every **'capsule'** notification throws "Unable to load asset: ''" and shows a grey circle | The Cloud Function writes `fromUserAvatar: creatorData.profilePicture \|\| ''`. The service's `?? no_photo.png` does not catch `''`, so `AssetImage('')` is built. The `isEmpty` check (line 21) only adds a child icon and still sets `backgroundImage`. Also, **nothing in the codebase writes `users.profilePicture`**, so real avatars never appear: 'follow' notifications always show `no_photo.png` (user_friends_service.dart:347) | M |
| B3 | `widgets/notifications/notification_avatar.dart:18` | Unhandled image exceptions when an avatar URL returns 404 | `NetworkImage` without `onBackgroundImageError` | L |
| B4 | `widgets/_common/default_buttons/default_icon_button.dart:32` | Null-check crash | `assetPath!` when both `child` and `assetPath` are null. The constructor does not assert that one is provided | L |
| B5 | `widgets/history_page/capsule_list_tile.dart:137` | Asset-load error widget | The pin path is built from the raw Firestore string `color` (`pin_${color.toLowerCase()}_icon.png`). Any value outside red/blue/green/yellow/orange/purple/pink has no asset | L |
| B6 | `widgets/map/opened_capsule_widget.dart:22-23` and `capsule_list_tile.dart:49-50` | Runtime `NoSuchMethodError` if `location` is not a GeoPoint | Dynamic access to `.latitude` on `Map<String,dynamic>` values. There is no typed model (a `TimeCapsule.fromMap` exists but is not used) | L |
| B7 | `widgets/map/opened_capsule_widget.dart:90` and `capsule_creation_datestamp.dart:17` | Shows **today's** date when `createdAt` is missing | `date ?? DateTime.now()` fallback in DateStamp | L |

### 2.2 Wrong logic and broken features
| # | Location | Symptom | Root cause | Sev |
|---|---|---|---|---|
| B8 | `widgets/notifications/notification_filter_tabs.dart:13` and `notifications_list.dart:52-53, 127-138` (page: `pages/core_pages/notifications_page.dart:88-95`) | The "Replies" and "Comments" tabs are **always empty**. 'follow' and 'capsule' cannot be filtered | The filters match `'reply'` and `'comment'`, which are never produced. Only `'follow'` and `'capsule'` exist. The empty-state copy ("Replies to your messages", "Comments on your Capsules") describes features that do not exist | H (functional) |
| B9 | `widgets/notifications/notifications_list.dart:104-113` | Tapping a notification only marks it read and navigates nowhere | `// TODO: Implement navigation`. The 4 branches only call `print()`. The 'comment' and 'reply' branches are dead | H (UX) |
| B10 | `widgets/notifications/notifications_list.dart:39, 82, 98` | The **wrong notification** can be marked read. Building is O(n²) | The index is computed with `notifications.indexOf(map)` at build time and captured in the closure. `markAsRead(index)` takes a positional index, so after a refresh (`_notifications.clear()` and refill) or a new push the index points to a different item. `indexOf` is also O(n) for each of up to 100 items. The fix is to mark by `id` | M |
| B11 | `widgets/notifications/notifications_list.dart:23-25` | Pull-to-refresh is impossible when a tab is empty | The empty state returns before the `RefreshIndicator` and is not scrollable | M |
| B12 | `widgets/notifications/notifications_list.dart:74` | Notifications with a missing timestamp always show "Just now" | `?? DateTime.now()` (the service already applies the same fallback) | L |
| B13 | `widgets/notifications/notification_item.dart:9-10` | Dead fields | `id` and `type` are required but never used in the UI. Type-specific icons or titles are not rendered, and the service's `title` key is ignored | L |
| B14 | `widgets/notifications/notification_selection_action_bar.dart:43` | Dead ternary | `count == 1 ? "selected" : "selected"` | L |
| B15 | `widgets/history_page/capsule_list_tile.dart:112-113` | The placeholder for a capsule with no image is **0.2 x 0.15 px** (invisible). The white `lock_clock` icon is clipped or invisible, and a white icon has no background anyway | `width: 0.2, height: 0.15` should be `screenWidth * 0.2` / `screenHeight * 0.15`, and a background colour is missing | M |
| B16 | `widgets/history_page/capsule_list_tile.dart:283-293` | Countdown is wrong for durations over 1 year | `days = inDays % 365` ignores leap years (minor). The format differs from the map panel's `_formatDuration` (capsule_info_widget.dart:50-66) | L |
| B17 | `widgets/history_page/capsule_list_tile.dart:224` | "No location" flashes while geocoding is in flight, and also shows when geocoding fails (`""` returns as an empty yellow pill) | `address ?? 'No location'`, and `_getAddress` returns `""` on failure. A failed lookup renders an empty pill | L |
| B18 | `widgets/history_page/capsule_list_tile.dart:15` | `selectionMode` is never read | Dead parameter | L |
| B19 | `widgets/history_page/capsule_list_tile.dart:43-68` | Stale data if the same keyed tile receives an updated capsule map (for example an edited `openAt`) | `openAt`, `location` and `address` are computed only in `initState`. There is no `didUpdateWidget` | L |
| B20 | `widgets/map/capsule_info_widget.dart` + `pages/navbar_pages/map_page.dart:118, 218` | A capsule with `openAt == null` gets `Timestamp.now()` passed in. It shows "Open" (correct by accident) | The widget requires a non-null `Timestamp`. Nullability is handled by the caller with a fake value | L |
| B21 | `widgets/capsule_creation/capsule_creation_location_label.dart:17, 44-45` | **Reverse geocoding re-runs on every rebuild**, and the pill flashes "Loading..." each time privacy, colour or date changes on the creation page (each calls `setState`). The preview dialog behaves the same. Repeated platform geocoder calls are rate-limited on iOS | `FutureBuilder(future: _getAddress(location))` creates a new future inside `build()`. There is no caching. The return type is `Future<Object>` and should be `Future<String>` | M |
| B22 | `widgets/user/user_name_and_username.dart:33-37` | Name and username **blink out** (replaced by empty `Center()`) on every parent rebuild, even when cached | The future is created in `build()`, so it is always `waiting` for at least one frame. Use an initState/didUpdateWidget future or a synchronous cache read | M |
| B23 | `pages/capsule_related_pages/capsule_creation_page.dart:85` | "Back" replaces the page with `/camera` without the original `privacy` argument | `pushReplacementNamed(context, '/camera')` without `arguments`. The first camera open had `widget.arguments?['privacy']` (camera_page:109) | L |
| B24 | `widgets/history_page/nested_menu.dart:66-72` | The Android back button closes the whole dialog instead of returning one menu level. If a leaf `onTap` navigates, the following `Navigator.pop(context)` pops the wrong route | No `PopScope`, and pop is called after `onTap` | L |
| B25 | `widgets/_common/default_elements/confirm_dialog.dart:86` | If a caller passes `onCancel`, the sheet **does not close** (confirm does) | `onPressed: onCancel ?? () => pop()`. Pop should run first, then `onCancel`. No current caller passes `onCancel` (latent) | L |
| B26 | `widgets/capsule_creation/capsule_creation_cycled_info.dart:22` | The pill is semi-transparent (alpha 217) | `Color.fromARGB(217, 217, 217, 217)`. The argument order was probably confused; opaque `#D9D9D9` was likely intended. **Keep the value as-is when tokenising** (visual parity), but name it explicitly | L |

### 2.3 Lifecycle, leaks and setState
| # | Location | Symptom | Root cause | Sev |
|---|---|---|---|---|
| B27 | `pages/capsule_related_pages/capsule_creation_page.dart` (no `dispose`) + `lib/controllers/page_controllers/capsule_creation/capsule_creation_page_controller.dart:14-15` | Leaks: the `CapsuleCreationPageController` (a ChangeNotifier) and its two `TextEditingController`s are never disposed | The state class has no `dispose()`, and the controller has no `dispose` override for the text controllers | M |
| B28 | `pages/capsule_related_pages/capsule_creation_page.dart:190-193` | Possible `setState() called after dispose()` if the page is popped while the date picker is open or closing | `await _controller.pickOpenDate(context); setState(() {});` without a `mounted` check. The page also calls `setState` after controller methods that already `notifyListeners()`, so state is held in two places | M |
| B29 | `widgets/history_page/capsule_list_tile.dart:54-58` | **Every tile rebuilds every second, forever**, even after the capsule has opened. With N tiles this is N timers and N rebuilds per second | A `Timer.periodic(1s)` per tile is never cancelled when the countdown reaches 0 | M (perf) |
| B30 | `widgets/map/capsule_info_widget.dart:32-35` | The 1s timer keeps rebuilding after the capsule is open | It is not cancelled when `_isOpen`. There is also no `didUpdateWidget` for a new `openAt` | L |
| B31 | `widgets/user/user_profile_image.dart:16`, `user_background_image.dart:11` | Notifiers are owned by `UserImageService` and **disposed in `onLogout()`** (`lib/services/user_image_service.dart:144-150`). A widget still mounted during logout keeps a disposed notifier, which asserts in debug if it is re-listened | `context.read` in `build` caches a service-owned notifier, and the widget cannot see the disposal | L |
| B32 | `widgets/_common/default_elements/popup_notification.dart:13, 63-86` | Dead code: `enableExitAnimation` is never read (the service handles it). The `isExit == true` branch of `_createSlideAnimation` is unreachable because exit uses `_createExitSlideAnimation` | Leftovers | L |

### 2.4 Double-tap and double-submit
| # | Location | Symptom | Root cause | Sev |
|---|---|---|---|---|
| B33 | `pages/capsule_related_pages/capsule_creation_page.dart:229-235` + controller `saveCapsule` (controller:78-139) | Two taps in the same frame create **two capsules** (two Storage uploads and two Firestore docs) | The button is disabled only after a rebuild (`isLoading: isSaving`). `saveCapsule` has no `if (isSaving) return;` guard | M |
| B34 | `widgets/_common/default_elements/navbar_widget.dart:76-80` | A double tap on "+" pushes **two camera routes**, initialising the camera twice | `Navigator.pushNamed('/camera')` with no guard. The route name is hard-coded inside the widget | M |
| B35 | `widgets/_common/options_elements/options_settings_row.dart:76-87` | A double tap pushes the destination twice | No guard. The 10ms transition makes this easy | L |

### 2.5 Firebase / service access from widgets, and raw errors
| # | Location | Note | Sev |
|---|---|---|---|
| B36 | controller `saveCapsule:91-124` (invoked from `capsule_creation_page.dart:231`) | Firestore `.collection('capsules').doc()` and `FirebaseStorage.ref().putFile` are called directly from a page controller, not a service. The camera JPEG is uploaded uncompressed. `capsuleMap['privacy'] = privacy.name` (line 119) duplicates `toMap()` | M |
| B37 | controller `saveCapsule:131` | **The raw exception is shown to the user**: `'Failed to save capsule: $e'` | M |
| B38 | `widgets/map/capsule_info_widget.dart:3` | Imports `cloud_firestore` only for the `Timestamp` type, so the Firestore type leaks into the UI layer | L |
| B39 | `widgets/notifications/notifications_list.dart:32` | Calls `notificationService.loadNotificationsFromFirestore()` directly. That method is unbounded except for `.limit(100)` and swallows errors (`print`) | L |
| B40 | `widgets/history_page/capsule_list_tile.dart:5, 320-324`; `capsule_creation_page.dart:47` | Reads the global mutable `MapPage.currentPositionStatic` (a static field on a page widget) for distance and location. The distance is "0.0 km" whenever the map has not been opened yet | M |
| B41 | `widgets/capsule_creation/capsule_creation_location_label.dart:20` and `capsule_list_tile.dart:304` | `placemarkFromCoordinates` (a platform geocoder) is called directly from widgets, duplicated and uncached | M |
| B42 | `widgets/notifications/notifications_list.dart:106-112` | `print()` ×4 (all `print` calls in scope) | L |

### 2.6 Layout and overflow risks
| # | Location | Risk | Sev |
|---|---|---|---|
| L1 | `widgets/history_page/capsule_list_tile.dart:164-198` | The three info rows (`Row[icon, DefaultText]`) have **no Expanded/Flexible**. The available width is about `0.53·w − 64` (127px at w=360). "Capsule is opened!" at 14pt, the countdown "1y 200d 23h 59m" and "Friends visibility" overflow on 320-360dp phones (yellow/black stripes) | M |
| L2 | `widgets/map/capsule_info_widget.dart:70-151` inside `CustomInfoWindow(height: screenHeight*0.171, width: screenWidth*0.58)` (map_page:280-281) | Content is about 16 pad + ~30 title + ~19 date + 8 + ~19 status + 48 button ≈ 140px. 0.171·h is 109px at h=640 and 137px at h=800, so it **overflows on most phones**. The Column uses `mainAxisSize.max` with no flex | M |
| L3 | `widgets/map/opened_capsule_widget.dart:28-29, 58-65` | Fixed height `0.45·h`. The title Text has no `maxLines`, so a long title can push the column past the Expanded description. When `imageUrl == null` the 12px gap remains | L |
| L4 | `widgets/_common/default_elements/page_header.dart:52-70` | The title is centred in a Stack and the leading/trailing buttons are `Positioned` at 16px with no horizontal title padding, so long titles collide with the buttons. Font is `screenHeight*0.04` (25.6 at h=640, 37 at h=926) | L |
| L5 | `widgets/_common/default_buttons/default_green_button.dart:40-43` | Fixed size of `0.45·w × 0.06·h` gives a **38px tap height at h=640** (below 48) and 56px on tablets. Text defaults to fontSize **30** shrunk by FittedBox | L |
| L6 | `widgets/_common/default_buttons/default_icon_button.dart:33-34` | The default icon size is 0.11·w (35-47px), so tap targets are under 48 at small widths. A `GestureDetector` has no padding or semantics | L |
| L7 | `widgets/_common/default_elements/navbar_widget.dart:33-41` | Width is about 4×46 (one tab at 55.2) plus the add icon (69 high, aspect-dependent), close to 300px, inside `w − 32`. That overflows at w ≤ 330. Height is fixed at 80 | L |
| L8 | `widgets/history_page/capsule_selection_action_bar.dart:25-48` | Row of 18pt bold text + Spacer + 2 `TextButton.icon` with no Flexible, so it overflows on narrow screens when the count reaches 2 digits | L |
| L9 | `widgets/_common/options_elements/options_input_field.dart:19-20` | Fixed `0.92·w × 50` container | L |
| L10 | `widgets/capsule_creation/capsule_creation_description_input.dart:14` | The widget **returns `Expanded`**, so it crashes with an "Incorrect use of ParentDataWidget" error if placed outside a Flex | L |
| L11 | `pages/capsule_related_pages/capsule_creation_page.dart:75, 106-150` | `resizeToAvoidBottomInset: false` with a fixed `0.4·h` preview card. Description editing works because the inputs are near the top, but the Create button is hidden while the keyboard is open. On very short screens (h ≤ 600) the Column inside the 0.4·h card (title input about 54px + date 0.045h + 8 + location 0.05h + 8) leaves under 100px for the description | L |
| L12 | `widgets/notifications/notification_filter_tabs.dart:16` | `IntrinsicWidth` around a TabBar is costly (an O(n²) layout pass) | L |
| L13 | Screen-ratio typography | `page_header` (0.04h / 0.017h), `default_empty_inbox_info` (0.048w / 0.033w), `options_settings_row` (0.045w), `capsule_list_tile` (0.04w ×3), `user_list_tile` (0.045w / 0.04w), `opened_capsule_widget` (0.05w), `capsule_creation_page` (0.05w ×2). Text scales with the device rather than the user's text scale, so tablets get huge text | L |
| L14 | `widgets/user/user_list_tile.dart:8`, `share_profile/share_profile_qr.dart:8` | `screenWidth` is passed as a constructor parameter (an anti-pattern) | L |
| L15 | `widgets/capsule_creation/capsule_image_preview.dart:13`, `opened_capsule_widget.dart:50`, `capsule_list_tile.dart:105` | `Image.file`/`Image.network` without `cacheWidth`, `loadingBuilder` or `errorBuilder`. A full-resolution camera photo is decoded for a small preview, and a broken URL shows the error widget | M |

### 2.7 Visual and interaction defects
| # | Location | Issue | Sev |
|---|---|---|---|
| V1 | `widgets/notifications/notification_item.dart:47-67` | `InkWell` sits inside a decorated `Container` with no `Material` between them. The ripple paints on the ancestor Material *behind* the opaque card, so it is invisible. The 16px card padding is outside the InkWell and is not tappable | L |
| V2 | `widgets/history_page/capsule_list_tile.dart:87-93` | The InkWell wraps the *margin*, so the ripple shows only in the 6/12px margin. The InkWell radius is 12 but the card radius is 25 | L |
| V3 | `widgets/_common/default_buttons/default_button_with_icon.dart:35` | InkWell radius is hard-coded to 25 even if a custom `decoration` has another radius | L |
| V4 | `widgets/_common/default_elements/navbar_widget.dart:59-69` | `TweenAnimationBuilder` with `begin: 1.0, end: 1.0` is a no-op. `AnimatedScale` at 10ms is effectively instant (dead animation code). The selected scale is 1.2 (size) × 1.1 (scale) | L |
| V5 | Fonts | Text without an explicit family falls back to the theme's "Irina": confirm_dialog, later_loading_bar, notification_filter_tabs, capsule_selection_action_bar "Delete" label, capsule_privacy_dropdown. Fine, but inconsistent with the explicit `fontFamily: 'Irina'` elsewhere | L |
| V6 | Date formats (5 different) | `dd.MM.yyyy` (datestamp:18), `d.M.yyyy` (capsule_list_tile:252), `yyyy-MM-dd` (creation page:184), `dd-MM-yyyy` (map_page:117, 216 → CapsuleInfoPanel), `d/M/yyyy` (notification_timestamp:34) | L |
| V7 | Hints | `"Add Title... "` has a trailing space (title_input:14). The privacy dropdown uses `toString().split('.')` instead of the `.label` extension | L |

### 2.8 Dead and unused code
- **Unused:** `RefreshButton` (`_common/premade_buttons/refresh_button.dart`), `CapsulePrivacyDropdown` (`capsule_creation/capsule_privacy_dropdown.dart`), `BoxDecorations.redWithBorderRadius` (box_decorations.dart:55-60), `ElevatedButtonStyles.cancelButtonStyle` (elevated_button_styles.dart:19-25).
- `DefaultIconButton.contentPadding` (default_icon_button.dart:9, 18) is declared but never used.
- `ConfirmDialog` `const SizedBox(height: 0)` (confirm_dialog.dart:84).
- `NestedMenu` has an empty `Container(child: ...)` wrapper (nested_menu.dart:41).
- `searchFocusNode ?? null` (default_search_bar.dart:46), `foregroundColor ?? null` (elevated_button_styles.dart:11), `subtitle ?? null` (options_settings_row.dart:52), `this.onTap = null` (options_settings_row.dart:21), `initialPrivacy ?? null` (creation page:60).
- `SelectionActionBar` constructor has no `super.key` (capsule_selection_action_bar.dart:10). Old-style `Key? key` in capsule_creation_cycled_info.dart:10 and share_profile_qr.dart:11.
- `navbarIconHeight` is a public top-level const used only in its own file (navbar_widget.dart:3).
- `pin_pink_icon.png` exists in assets, but `CapsuleColor` has no pink value (orphan asset).

---

## 3. Design tokens observed

### 3.1 Colours (every literal)

**Brand and accent**
| Value | Written as | Where | Count |
|---|---|---|---|
| **#56C92E** (`0xFF56C92E`) brand green | `Color(0xFF56C92E)` | box_decorations:71 (defaultBorderRadius default), default_green_button:35, capsule_info_widget:113 (text), :126 (button bg) | 4 |
| #56C92E | `Color.fromARGB(255, 86, 201, 46)` | notification_filter_tabs:21 (tab indicator) | 1 (plus popup_notification_service showSuccess, out of scope) |
| **#55C92E** (off by one from brand) | `Color.fromARGB(255, 85, 201, 46)` | capsule_creation_datestamp:12 (default bg), capsule_list_tile:241 (date pill) | 2. **Near-duplicate of #56C92E; pick one token, the difference is not visible** |
| **#FFD900** location yellow | `Color.fromARGB(255, 255, 217, 0)` | capsule_creation_location_label:40, capsule_list_tile:213 | 2 |
| **#FD4140** destructive red | `Color.fromARGB(255, 253, 65, 64)` | confirm_dialog:63 (confirm bg default), options_settings_row:50 (last-row title) | 2 |
| #F44336 `Colors.red` | | box_decorations:57, capsule_list_tile:148 (heart), capsule_info_widget:103 ("Opens in"), unread_notification_badge:14 (default badge), share_profile_qr:38 (error text), elevated_button_styles:21 (cancel, unused) | 6 |
| #FF5252 `Colors.redAccent` | | capsule_selection_action_bar:41, :44; notification_selection_action_bar:61 | 3 |
| #2196F3 `Colors.blue` | also `Color.fromARGB(255, 33, 150, 243)` | refresh_button:24 (ARGB form), notification_selection_action_bar:52, notification_unread_indicator:20 | 3 |
| `Colors.blue` @ α0.1 = `0x1A2196F3`, border @ α0.3 = `0x4D2196F3` | `withValues(alpha:)` | box_decorations:64, :66 (lightBlueInfo) | 2 |
| `Colors.blue` @ α0.2 = `0x332196F3` (shadow) | | notification_item:55 | 1 |
| #BBDEFB `Colors.blue.shade100` (selected notification bg) | | notification_item:51 | 1 |
| #E3F2FD `Colors.blue.shade50` (unread notification bg) | | notification_item:62 | 1 |
| #67CFFF @ alpha 100 = **`0x6467CFFF`** (selected capsule bg) | `Color.fromARGB(255,103,207,255).withAlpha(100)` | capsule_list_tile:96 | 1. **Note: the selected state differs between capsule tile (light-blue α100) and notification (blue.shade100)** |

**Neutrals**
| Value | Written as | Where | Count |
|---|---|---|---|
| #FFFFFF `Colors.white` | | box_decorations:6; default_green_button:50, :58; confirm_dialog:34, :77; navbar_widget:23; page_header:34; white_circular_progress_indicator:19; options_input_field:23, :48; refresh_button:33, :37; capsule_creation_datestamp:41; location_label:58, :73; capsule_list_tile:114, :229, :257; capsule_info_widget:73, :144; opened_capsule_widget:31; notification_avatar:22; notification_filter_tabs:26; notification_item:62; notification_selection_action_bar:24; unread_notification_badge:15; share_profile_qr:28 | 28 |
| #000000 `Colors.black` | also `Color.fromARGB(255,0,0,0)` | box_decorations:28 (ARGB form); default_button_with_icon:51; confirm_dialog:49; default_text:40 (default); options_settings_row:50; capsule_selection_action_bar:35; notifications_list:31 (refresh spinner); notification_filter_tabs:27; notification_item:102; notification_selection_action_bar:70; share_profile_qr:31, :35; user_list_tile:33; user_name_and_username:24; text_button_styles:7 | 16 |
| **#EAEAEA** grey surface | `Color(0xFFEAEAEA)` | box_decorations:21 (greyCard), default_search_bar:31, nested_menu:38 | 3 |
| **#F5F5F5** page background | `Color(0xFFF5F5F5)` | capsule_creation_page:76 | 1 (check other pages) |
| **#D3D3D3** divider | `Color.fromARGB(255, 211, 211, 211)` | options_settings_row:97 (also `ProfilePageDivider` default, my_profile_page/profile_page_divider.dart:12) | 1 (+1) |
| **#5E5E5E** secondary text | `Color.fromARGB(255, 94, 94, 94)` | page_header:79, user_list_tile:43, user_name_and_username:25 | 3 |
| **#5F5F5F** (near-duplicate of #5E5E5E) | `Color.fromARGB(255, 95, 95, 95)` | confirm_dialog:88 (cancel) | 1 |
| **#6A6A6A** | `Color.fromARGB(255, 106, 106, 106)` | capsule_creation_cycled_info:36 | 1 |
| **#D9D9D9 @ α217 = `0xD9D9D9D9`** | `Color.fromARGB(217, 217, 217, 217)` | capsule_creation_cycled_info:22 | 1 |
| #757575 `Colors.grey[600]` | | default_empty_inbox_info:36, notification_selection_action_bar:45, notification_timestamp:17 | 3 |
| #E0E0E0 `Colors.grey[300]` / `.shade300` | | default_loading_container:21, notification_avatar:20, notification_thumbnail:43 | 3 |
| #9E9E9E `Colors.grey` | | capsule_list_tile:148 (heart off), capsule_info_widget:127 (locked button), notification_thumbnail:44 | 3 |
| `Colors.black54` = `0x8A000000` | | opened_capsule_widget:74 (description) | 1 |
| `Colors.transparent` | | default_button_with_icon:32, confirm_dialog:116, popup_notification:150, options_settings_row:36-38 (×3), notification_filter_tabs:25, text_button_styles:11 | 8 |

**Shadow and overlay alphas**
| Value | Where | Count |
|---|---|---|
| `Colors.black12` = `0x1F000000` | box_decorations:10, :45; options_input_field:27 | 3 |
| `Colors.black26` = `0x42000000` | navbar_widget:27, capsule_info_widget:75, opened_capsule_widget:35 | 3 |
| black `withAlpha(120)` = `0x78000000` | box_decorations:32 | 1 |
| black `withAlpha(128)` = `0x80000000` (modal barrier) | confirm_dialog:118 | 1 |
| black `withAlpha(25)` = `0x19000000` (splash) | default_button_with_icon:36 | 1 |
| black α0.2, written `withAlpha((0.2*255).round())` = 51 = `0x33000000` | popup_notification:159 | 1 |
| black α0.05 = `0x0D000000` | notification_selection_action_bar:28 | 1 |

### 3.2 Shadows (exact)
| Name / site | color | blur | spread | offset | radius of the shape |
|---|---|---|---|---|---|
| `BoxDecorations.whiteCard` (box_decorations:9-14) | black12 | 9 | 1 | (0,4) | 25 (param) |
| `OptionsInputField` inline (options_input_field:26-31) | black12 | 9 | 1 | (0,4) | 25. **Identical to whiteCard; should use it** |
| `BoxDecorations.blackShadow` (box_decorations:31-36) | black α120 | 20 | 15 | (0,6) | 16, colour black |
| `BoxDecorations.softBlackShadow` (box_decorations:44-49) | black12 | 16 | 1 | (0,6) | 25, no fill |
| NavbarWidget (navbar_widget:26-30) | black26 | 10 | 0 | (0,4) | 30 |
| CapsulePreviewCard (opened_capsule_widget:34-38) | black26 | 10 | 0 | (0,4) | 25. **Same shadow as navbar** |
| CapsuleInfoPanel (capsule_info_widget:75) | black26 | 8 | 0 | (0,0) | 25 |
| PopupNotification (popup_notification:158-162) | black α0.2 | 8 | 0 | (0,4) | 10 |
| NotificationItem selected (notification_item:54-58) | blue α0.2 | 8 | 0 | (0,2) | 25 |
| NotificationSelectionActionBar (…:27-31) | black α0.05 | 10 | 0 | (0,2) | 25 |

### 3.3 Elevations
| Value | Where |
|---|---|
| 0 | confirm_dialog:67 (ElevatedButton), capsule_info_widget:131, elevated_button_styles:15, :23 |
| 8 | nested_menu:39 (Material) |
| M3 default (1, plus a surface tint because colorScheme is seeded green) | default_green_button (no elevation override). **Shadow and tint appear on the green button only** |

### 3.4 Border radii
| Radius | Sites | Count |
|---|---|---|
| **25** (dominant) | box_decorations:4, :19, :51, :73; default_button_with_icon:35; default_green_button:37 (25.0); confirm_dialog:35, :65; default_search_bar:32; page_header:36-37 (bottom only); options_input_field:24; capsule_creation_datestamp:28; location_label:41; capsule_image_preview:12; capsule_list_tile:214, :242; capsule_info_widget:74, :129; opened_capsule_widget:32; notification_filter_tabs:22; notification_item:52, :67; notification_selection_action_bar:25; user_rounded_background_image:18-19 (bottom only); elevated_button_styles:7, :22 | ~30 |
| 24 | options_input_field:44 (inner OutlineInputBorder; 1px off the outer 25) | 1 |
| 30 | navbar_widget:24 | 1 |
| 20 | nested_menu:40, opened_capsule_widget:49 (image) | 2 |
| 17 | capsule_list_tile:103 (thumbnail) | 1 |
| 16 | box_decorations:29 (blackShadow) | 1 |
| 12 | box_decorations:65 (lightBlueInfo), capsule_list_tile:90 (InkWell), user_square_avatar:13 (default) | 3 |
| 10 | box_decorations:55 (redWithBorderRadius default), popup_notification:156 | 2 |
| 8 | default_loading_container:22 (default), notification_thumbnail:20 | 2 |
| size/2 (pill) | unread_notification_badge:36 | 1 |
| circle shapes | refresh_button:25, location_label:74, notification_unread_indicator:21, unread_notification_badge:35, UserRoundAvatar (ClipOval), NotificationAvatar (CircleAvatar r=24) | — |

### 3.5 Typography (family "Irina" = Inria Sans; weights 400/700 only)
| Size | Weight | Where | Notes |
|---|---|---|---|
| 12 | normal | notification_timestamp:16 (grey600) | |
| 14 | normal | **DefaultText default** (default_text:39); opened_capsule_widget:72 (black54); notification_filter_tabs:33 (unselected); notification_item:101 (body, username bold); notification_selection_action_bar:44 | most common body size |
| 14 | bold | notification_filter_tabs:29 (selected) | |
| 15 | normal | capsule_creation_description_input:23, :30 | |
| 16 | normal | default_text_button:28 (default), text_button_styles:8, capsule_info_widget:94 (date) | |
| 16 | bold | confirm_dialog:50, :79, :90; popup_notification:209; capsule_info_widget:105, :115 | |
| 18 | bold | capsule_selection_action_bar:29, notification_selection_action_bar:38 | |
| 18 | normal (theme font) | later_loading_bar:32 | |
| 20 | bold | capsule_info_widget:141 (button) | |
| 22 | normal | default_search_bar:53 (input) | |
| 22 | bold | user_name_and_username:23 (username default) | |
| 25 | bold | capsule_creation_title_input:17, :24; capsule_info_widget:88 | |
| 30 | bold | default_green_button:20 (default, FittedBox-shrunk) | |
| 32 | bold | user_name_and_username:22 (name default) | |
| 35 | normal | capsule_creation_cycled_info:35 (FittedBox-shrunk) | |
| 50 | bold | capsule_creation_datestamp:38, location_label:55 (FittedBox-shrunk, so the effective size depends on height) | |
| size·0.6 | bold | unread_notification_badge:47 (12 at the default size of 20) | |
| **screen-relative** | | page_header title `h·0.04` bold, description `h·0.017` bold #5E5E5E; empty_inbox title `w·0.048` **w900** and subtitle `w·0.033` grey600; options_settings_row title `w·0.045` bold; capsule_list_tile title `w·0.04` **w500**, pills `w·0.04` bold white; user_list_tile name `w·0.045` bold, username `w·0.04` #5E5E5E; opened_capsule title `w·0.05` bold; creation page section titles `w·0.05` bold | |
| Line height | | `height: 1.0` user_name_and_username:59 (name only) | |
| **letterSpacing** | | **none anywhere in scope** | |

### 3.6 Spacing (padding, margin, gaps)
| Value | Where |
|---|---|
| 0 | confirm_dialog:39 (horizontal), :93 |
| 1 | capsule_creation_cycled_info:19 (vertical) |
| 4 | default_search_bar:29 (vertical); notification_item:78 (gap); notification_selection_action_bar:41 (gap) |
| 5 | default_empty_inbox_info:24, :30 (gaps); notification_filter_tabs:38 (indicatorPadding horizontal) |
| 6 | confirm_dialog:56 (gap); capsule_list_tile:93 (margin vertical); opened_capsule_widget:66 (gap); options_settings_row:25 (minVerticalPadding default) |
| 8 | default_search_bar:27 (bottom); popup_notification:172 (icon gap); capsule_selection_action_bar:20 (horizontal), :38 (gap); capsule_info_widget:71 (all), :97 (gap), :133 (button vertical); opened_capsule_widget:41 (all), :80, :87, :92 (gaps); notification_filter_tabs:36 (labelPadding horizontal), :38 (indicator vertical), :42 (tab vertical); notification_item:41 (vertical); notification_selection_action_bar:56, :65 (gaps); notification_unread_indicator:18 (left margin); notifications_list:34 (top); creation page:97 (all), :137, :144, :151, :158 (gaps) |
| 10 | capsule_creation_page:165, :179, :197 (minVerticalPadding); :225 (vertical) |
| 12 | default_button_with_icon:40 (horizontal); confirm_dialog:45 (horizontal); default_search_bar:37 (icon horizontal); popup_notification:153 (vertical); capsule_creation_cycled_info:30 (all); datestamp:34; location_label:51; capsule_list_tile:93 (margin horizontal), :203 (gap); nested_menu:46 (all); opened_capsule_widget:53 (gap); notification_item:72, :84 (gaps); notification_selection_action_bar:22 (vertical); capsule_creation_page:120 (gap) |
| 14 | capsule_list_tile:92 (all) |
| 16 | confirm_dialog:38 (vertical); navbar_widget:21 (margin horizontal); page_header:59, :67 (button inset); popup_notification:152 (margin horizontal), :153 (padding horizontal); capsule_info_widget:134 (button horizontal); notification_filter_tabs:42 (tab horizontal); notification_item:41 (horizontal), :48 (all); notification_selection_action_bar:22 (horizontal); notifications_list:34 (bottom) |
| 20 | share_profile_qr:23 (all); later_loading_bar:29 (messageSpacing default) |
| 40 | capsule_creation_page:225 (horizontal) |
| `size·0.35` | unread_notification_badge:39 |
| **screen-relative** | navbar bottom `h·0.01`; page_header top `h·0.04`, description horizontal `w·0.07`, search bar L/R `w·0.04` + top `h·0.01`, action row L/R `w·0.04` + bottom `h·0.01`; default_search_bar trailing right `w·0.03`; options_input_field horizontal `w·0.01`, content `w·0.04` × `h·0.001`; options_settings_row content L `w·0.05` R `w·0.03`; capsule_list_tile gaps `w·0.04`, `w·0.01` ×4, `h·0.004`, `h·0.016`, `h·0.008` ×2, `h·0.005` ×2, pill padding `w·0.02` × `h·0.003`; user_list_tile horizontal `w·0.02`; capsule_selection_action_bar top `h·0.01` |

### 3.7 Fixed sizes
| Value | Where |
|---|---|
| Navbar: height **80**; icon **46** (`navbarIconHeight`), selected ×1.2 = 55.2 plus scale 1.1; add icon height 46×1.5 = **69** | navbar_widget:3, :20, :57-58, :65, :81 |
| ConfirmDialog width **264**; confirm button **160×40** | confirm_dialog:32, :58-59 |
| DefaultButtonWithIcon default height **48**; icon **32×32** | default_button_with_icon:39, :43 |
| DefaultGreenButton default **0.45w × 0.06h**; spinner **24**/stroke 2 | default_green_button:41-42, :47-51 |
| DefaultIconButton default icon **0.11w** | default_icon_button:33-34 |
| DefaultEmptyInboxInfo icon **72×72** | :23 |
| DefaultLoadingContainer spinner **20**/stroke 2 | :26-28 |
| LaterLoadingBar **150×150** | :14-15 |
| WhiteCircularProgressIndicator **16**/stroke 2 | :9-10 |
| RefreshButton **40**, spinner **20**/2, icon **30** | refresh_button:18-19, :30-34, :37 |
| ShadowTopOverlay height **1** | :13 |
| OptionsInputField **0.92w × 50** | :19-20 |
| OptionsSettingsRow leading/trailing icon **0.09w**; Divider 1/1; `VisualDensity(vertical: -3)`; dense | :43, :56-57, :67-68, :93-94 |
| DefaultSearchBar icon **0.07w** | :40-41 |
| CapsuleCreationCycledInfo width **0.4w**, icon **0.1w** | :24, :42-43 |
| Capsule creation preview card **w × 0.4h**, image **0.45w**; datestamp **0.045h**; location **0.05h**; title divider width **0.5w** | capsule_creation_page:107-108, :114, :128, :135, :139 |
| Title max length **30**; description max length **2200** | title_input:5, description_input:13 |
| CapsuleListTile thumbnail **0.2w × 0.15h**; pin width **0.025h**; heart **0.03h**; info icons **0.05w**; pills **0.23w × 0.035h** | :107-108, :138, :147, :168/:182/:193, :210-211/:238-239 |
| CapsuleInfoPanel container **0.58w × 0.171h** (from map_page) | map_page:280-281 |
| CapsulePreviewCard **w × 0.45h**, image **0.45w**, pills **0.05h** | opened_capsule_widget:28-29, :46, :82, :89 |
| NotificationAvatar radius **24** (48px) | :10 |
| NotificationThumbnail **50**; unread dot **8×8** | thumbnail:10; unread_indicator:16-17 |
| UnreadNotificationBadge **20** (min width = size) | :13 |
| ShareProfileQR card **0.75w square**, QR **0.55w** | :19-20, :27 |
| UserRoundedBackgroundImage height **270** | :11 |
| UserSquareAvatar radius **12** | :13 |
| UserListTile avatar radius **0.07w** | :26 |
| PopupNotification icon **20** | :171 |
| Selection action bar icons **24** ×3 | notification_selection_action_bar:53, :62, :71 |

### 3.8 Animation durations and curves
| Value | Where |
|---|---|
| 10 ms | navbar AnimatedScale (navbar_widget:65); OptionsSettingsRow PageTransition fade forward and reverse (:82-83). The same 10ms fade is also in camera_page:105-106 |
| 100 ms | navbar TweenAnimationBuilder (no-op) (:60) |
| 150 ms | PageHeader AnimatedSwitcher, easeOut/easeIn (:98-100) |
| 200 ms | navbar AnimatedContainer, easeInOut (:55-56) |
| 250 ms | PageHeader AnimatedSize, fastOutSlowIn (:29-30) |
| 300 ms | PopupNotification entry (easeOut) and exit (easeIn) (:51, :93). Slide offsets: top ±1, center +0.3 in / −0.3 out, bottom ±1 |
| 1 s | countdown timers (capsule_list_tile:55, capsule_info_widget:32) |
| 2 s | popup display time (service default; out of scope) |

### 3.9 Repeated values: token candidates (count across the scoped files)
- `radius.lg = 25`: ~30 uses. `radius.xl = 30` (navbar). `radius.md = 20` ×2, `12` ×3, `10` ×2, `8` ×2; 17, 16 and 24 are one-offs that could probably snap to 16/25.
- `color.brand = #56C92E` ×5 (+ #55C92E ×2, near-duplicate).
- `color.accentYellow = #FFD900` ×2.
- `color.danger = #FD4140` ×2. Material `red` ×6 and `redAccent` ×3 are three different reds for the same meaning.
- `color.surfaceMuted = #EAEAEA` ×3. `color.textSecondary = #5E5E5E` ×3 (+ #5F5F5F ×1). `grey[600]` ×3 is a third "secondary text" grey.
- `color.divider = #D3D3D3` ×2.
- `shadow.card = black12/blur9/spread1/(0,4)` ×2. `shadow.raised = black26/blur10/(0,4)` ×2.
- Text styles: 14 regular ×6+, 16 bold ×6, 18 bold ×2, 25 bold ×3, 50 bold white (pill) ×2.
- Spinners: white stroke-2 at 16/20/24 (×4 implementations).
- Spacing scale actually used: 4, 5, 6, 8, 10, 12, 14, 16, 20, 40. 8, 12 and 16 dominate. 5 and 14 are outliers.

---

## 4. Duplicated and near-duplicate components

1. **Pill label** (coloured, radius 25, white bold Irina in a scale-down FittedBox, padding 12):
   - `CapsuleCreationDateStamp` (green #55C92E, `dd.MM.yyyy`, fontSize 50)
   - `CapsuleCreationLocationLabel` pill part (yellow #FFD900, fontSize 50, plus a white circle icon)
   - `capsule_list_tile.dart:209-234` address pill (yellow, fixed 0.23w × 0.035h, fontSize w·0.04, padding w·0.02 × h·0.003)
   - `capsule_list_tile.dart:237-262` date pill (green #55C92E, `d.M.yyyy`)
   - `CapsuleCreationCycledInfo` (translucent grey 0xD9D9D9D9, grey #6A6A6A text, **not bold**, fontSize 35, optional trailing icon)

   Proposal: `PillLabel({text, color, textColor, height, width?, trailing?})`. The differences are colour, text colour, weight, size and padding.
2. **Reverse geocoding**: `CapsuleCreationLocationLabel._getAddress` vs `_CapsuleListTileState._getAddress`. The code is identical; only the fallbacks differ ("No location"/"Unknown location"/"Error getting location" vs ""). Move it to a cached service.
3. **Countdown**: `CapsuleInfoPanel._formatDuration` (`Xd Xh Xm Xs`, omitting leading zeros) vs `CapsuleListTile.formatCountdown` (`Xy Xd Xh Xm` or `Xd Xh Xm Xs`, always all fields). Each has its own 1s timer. Proposal: a single `CountdownText(openAt)` with one formatter, which stops ticking once open.
4. **Selection action bar**: `SelectionActionBar` (history: dividers above and below, "N selected" 18 bold, `TextButton.icon` Cancel (black close) and "Delete (N)" (redAccent)) vs `NotificationSelectionActionBar` (white card r25 with shadow α0.05, "N" 18 bold + "selected" 14 grey600, icon-only buttons mark-read (blue), delete_outline (redAccent), close (black), size 24, gap 8). Proposal: `SelectionBar(count, actions: [...], style: divider|card)`.
5. **Avatars**: `UserRoundAvatar` (ClipOval, radius) vs `UserSquareAvatar` (ClipRRect 12, size). Both wrap `UserProfileImage`. `NotificationAvatar` (CircleAvatar r24 with a URL or asset string, grey300 bg, person icon) is the same concept with a different source. Proposal: `Avatar(source: userId | url, shape: circle | rounded(r), size)`.
6. **Service-image builders**: `UserProfileImage` vs `UserBackgroundImage` are line-for-line identical apart from the notifier getter. Proposal: `ServiceImage(notifier)`.
7. **Capsule preview card**: `CapsulePreviewCard` (map dialog) vs the "Capsule Preview" container in `capsule_creation_page.dart:106-150`. Both are `Row[image 0.45w, gap 12, Expanded Column[title, description, pills]]` with padding 8 and radius 25. Differences:
   - height 0.45h vs 0.4h
   - shadow black26/blur10 vs the `whiteCard` shadow
   - image radius 20 vs 25
   - read-only Text vs TextFields
   - pill order: location then date vs date then location
   - pill heights 0.05h/0.05h vs 0.045h (date) and 0.05h (location)
   - trailing 8 gap: present vs absent

   Proposal: `CapsuleCard(mode: preview|edit)`.
8. **White elevated cards**: `BoxDecorations.whiteCard` vs the `OptionsInputField` inline decoration (identical) vs `NotificationSelectionActionBar`, `CapsuleInfoPanel`, `CapsulePreviewCard` and `NavbarWidget` (each with its own shadow; see §3.2). Converge on 2-3 shadow tokens.
9. **Grey #EAEAEA surfaces**: `BoxDecorations.greyCard`, `DefaultSearchBar` container, `NestedMenu` Material (r20, elevation 8).
10. **Rounded ElevatedButtons (r25)**:
    - `DefaultGreenButton`: green, M3 default elevation, fixed screen-ratio size, 30 bold
    - `ConfirmDialog` confirm: #FD4140, elevation 0, 160×40, 16 bold
    - `CapsuleInfoPanel` Open/Locked: green or grey, elevation 0, padding 8×16, 20 bold
    - `ElevatedButtonStyles.roundedButtonStyle`: color param, elevation 0
    - `cancelButtonStyle`: red, unused

    Proposal: `AppButton(variant: primary|danger|neutral, size, loading)`.
11. **Spinners**:
    - `WhiteCircularProgressIndicator` (16/2)
    - `DefaultGreenButton` inline (24/2 white)
    - `RefreshButton` inline (20/2 white)
    - `DefaultLoadingContainer` inline (20/2, theme colour)

    Merge into one.
12. **Borderless text inputs**: `CapsuleCreationTitleInput` (25 bold), `CapsuleCreationDescriptionInputField` (15 normal, expands), `DefaultSearchBar` TextField (22 normal, isDense), `OptionsInputField` (filled white, OutlineInputBorder r24 none). Proposal: `AppTextField(variant)`.
13. **Dividers**: the `OptionsSettingsRow` `Divider(color #D3D3D3, height 1)` and `ProfilePageDivider` (default #D3D3D3, 1px), which is used here by capsule_list_tile, capsule_selection_action_bar, nested_menu and capsule_creation_page. Use one `AppDivider`.
14. **Back button**: `GoBackButton` vs the inline `DefaultIconButton(assetPath: go_back.png)` in capsule_creation_page:83-87 (differs only in using `pushReplacementNamed`).
15. **Image clipping**: `CapsuleImagePreview` (file, r25) vs opened_capsule_widget:48-51 (network, r20) vs capsule_list_tile:102-115 (network, r17) vs notification_thumbnail (r8, with error fallback). Proposal: `RoundedImage(source, radius, fallback)`.
16. **Secondary-text greys**: #5E5E5E, #5F5F5F, #6A6A6A, grey[600] #757575 and black54 are all used for "muted text". Choose 1-2 tokens.
17. **Empty and loading states**: `DefaultEmptyInboxInfo` vs `LaterLoadingBar` (message 18) are similar "icon + text centred" layouts.

---

## 5. Asset paths referenced

Every path below exists on disk (checked against `assets/images/icons/...` listings). `pubspec.yaml:95-107` declares the directories.

| Path | File:line |
|---|---|
| `assets/images/icons/friends_page/look_for.png` | widgets/_common/default_elements/default_search_bar.dart:39 |
| `assets/gifs/loading/later_logo_loading.gif` | widgets/_common/default_elements/later_loading_bar.dart:13 (default param) |
| `assets/images/icons/navbar/icon-map.png` | widgets/_common/default_elements/navbar_widget.dart:36 |
| `assets/images/icons/navbar/icon-history.png` | navbar_widget.dart:37 |
| `assets/images/icons/navbar/icon-add.png` | navbar_widget.dart:38 |
| `assets/images/icons/navbar/icon-messages.png` | navbar_widget.dart:39 |
| `assets/images/icons/navbar/icon-profile.png` | navbar_widget.dart:40 |
| `assets/images/icons/prof_page/go_here.png` | widgets/_common/options_elements/options_settings_row.dart:66 |
| `assets/images/icons/prof_page/go_back.png` | widgets/_common/premade_buttons/go_back_button.dart:14; pages/capsule_related_pages/capsule_creation_page.dart:86 |
| `assets/images/icons/prof_page/go_back_white.png` | go_back_button.dart:15 |
| `assets/images/icons/capsule_creation/pin_${color.toLowerCase()}_icon.png` (dynamic; Firestore string) | widgets/history_page/capsule_list_tile.dart:137 |
| `assets/images/icons/capsule_creation/timer_icon.png` | capsule_list_tile.dart:167; capsule_creation_page.dart:189 |
| `assets/images/icons/capsule_creation/privacy_icon.png` | capsule_list_tile.dart:181; capsule_creation_page.dart:168 |
| `assets/images/icons/capsule_creation/location_icon.png` | capsule_list_tile.dart:192; widgets/map/opened_capsule_widget.dart:84; capsule_creation_page.dart:141 |
| `assets/images/icons/capsule_creation/cross.png` | capsule_creation_page.dart:90 |
| `assets/images/icons/capsule_creation/pin_${_controller.color.label.toLowerCase()}_icon.png` (dynamic; red/blue/green/yellow/orange/purple, all exist) | capsule_creation_page.dart:202 |
| `assets/images/icons/capsule_creation/pin_color_icon.png` | capsule_creation_page.dart:205 |
| `assets/images/icons/prof_page/no_photo.png` | widgets/notifications/notifications_list.dart:71 (also service:381, user_friends_service:347) |
| `assets/images/icons/prof_page/reply.png` | notifications_list.dart:131 |
| `assets/images/icons/prof_page/send_message.png` | notifications_list.dart:137 |
| `assets/images/icons/prof_page/notifications_button_black.png` | notifications_list.dart:143 |

Other notes:
- The `assetPath`/`iconPath` parameters are pass-through in DefaultButtonWithIcon, DefaultIconButton, DefaultEmptyInboxInfo, CapsuleCreationLocationLabel, CapsuleCreationCycledInfo and OptionsSettingsRow.
- `NotificationAvatar` and `NotificationThumbnail` treat any non-`http` string as an asset path.
- Orphan asset: `assets/images/icons/capsule_creation/pin_pink_icon.png` (no `CapsuleColor.pink`).
