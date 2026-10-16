> Appendix to AUDIT.md / DESIGN_SPEC.md. Produced by a read-only audit pass over the files listed below on 2026-10-16 (before any refactor change) and spot-checked against the code. Line numbers refer to commit 9f17db0.

# Audit B: friends / my_profile_page / add_friend_profile widgets, friends_pages, settings_pages

Branch: `refactor/architecture-and-stabilization`. I read every line of all 47 files in scope (about 5,000 lines). I also read the supporting code needed to judge how the widgets behave: UserFriendsService, UserDataService, AssetImageService, PopupNotificationService (show/mounted), BoxDecorations, DefaultText, DefaultGreenButton, ElevatedButtonStyles, UserNameAndUsername, and the controllers PinnedFriendsController, SuggestedFriendsListController, MyFriendsPageController, AddFriendProfileController, FriendRequestsPageController and AddFriendsPageController.

Paths are relative to `lib/views/` unless they start with `lib/`.

---

## 1. Per-file summary

### widgets/friends/
| File | What it is | Used by |
|---|---|---|
| add_friends_page/add_friends_action_buttons_row.dart | A row with two `DefaultButtonWithIcon`: "Share Profile" (opens ShareProfilePage) and "Requests" (opens FriendRequestsPage, with a `FriendRequestCountBadge` overlay). | pages/friends_pages/add_friends_page.dart:84 |
| add_friends_page/suggested_friends_list.dart | StatefulWidget. Streams `UserFriendsService.getSuggestedFriends`, preloads each user through `SuggestedFriendsListController`, and shows rows or placeholders. | add_friends_page.dart:101 |
| add_friends_page/suggested_friend_placeholder_row.dart | Grey skeleton row (circle plus two bars). | suggested_friends_list.dart:98 |
| add_friends_page/suggested_friend_row.dart | A ListTile with avatar, name, @username, and trailing add/pending and delete icons. | suggested_friends_list.dart:121 |
| contacts_list.dart | Device contacts list with an "Invite" SMS button. | **UNUSED** (no import anywhere in lib/) |
| friend_options_modal.dart | Three bottom-sheet modals: `FriendOptionsModal`, `ManageFriendshipModal` (follow, report, block, remove) and `RemoveFriendConfirmModal`. Private helpers: `_ModalContainer`, `_ModalHeader`, `_ModalOption`, `_FollowButton`, `_ModalDivider`, `_ConfirmButton`, `_CancelButton`. | your_friend_profile_page.dart:38 |
| friend_requests_count.dart | `FriendRequestCountBadge`: a red count pill. **It returns a `Positioned`.** | add_friends_action_buttons_row.dart:62, profile_page_add_friends_button.dart:59 |
| friend_requests_page/friend_requests_action_button.dart | Small coloured pill button (Accept / Reject / Cancel). | received_row.dart:69,75; sent_row.dart:56 |
| friend_requests_page/friend_requests_received_list.dart | Consumer of `UserFriendsService.receivedRequests`, with a FutureBuilder per row. | friend_requests_page.dart:77 |
| friend_requests_page/friend_requests_received_row.dart | White card row with Accept and Reject buttons. | received_list.dart:56 |
| friend_requests_page/friend_requests_sent_list.dart | Consumer of `sentRequests`, with a FutureBuilder per row. | friend_requests_page.dart:82 |
| friend_requests_page/friend_requests_sent_row.dart | White card row with a Cancel button. | sent_list.dart:54 |
| friend_requests_page/friend_requests_toggle_button.dart | Received/Sent segmented toggle. **It returns `Expanded`.** | friend_requests_page.dart:61,67 |
| my_friends_page/my_friends_grouped_by_letter_list.dart | Alphabetical sections, each a white card of `UserListTile`. | my_friends_page.dart:97 |

### widgets/my_profile_page/
| File | What it is | Used by |
|---|---|---|
| my_friends_panel/pinned_friends_row.dart | A row of up to 3 friend avatars. Tapping one opens `PinnedFriendOptionsDialog`. | profile_page_my_friends_panel.dart:52 |
| .../on_pinned_friend_tap/choose_pinned_friends_dialog.dart | `ChoosePinnedFriendsDialog`, a byte-for-byte duplicate of `PinnedFriendsSelectionDialog`. | **UNUSED** (no import anywhere) |
| .../on_pinned_friend_tap/pinned_friends_selection_dialog.dart | Bottom sheet for choosing up to 3 pinned friends (search, checkboxes, Save). | lib/controllers/widget_controllers/profile/pinned_friends_controller.dart:110 |
| .../on_pinned_friend_tap/pinned_friends_selection_dialog_header.dart | Title, subtitle and DefaultSearchBar for the dialog above. | choose_pinned_friends_dialog.dart:64 (unused file), pinned_friends_selection_dialog.dart:65 |
| .../on_pinned_friend_tap/pinned_friend_avatar.dart | Square avatar with the top corners rounded (`UserProfileImage`, `pinnedFriend` placeholder). | pinned_friends_row.dart:44 |
| .../on_pinned_friend_tap/pinned_friend_options_dialog.dart | Small card: name, "View profile page", "Choose pinned friends". | pinned_friends_row.dart:53 |
| .../on_pinned_friend_tap/pinned_friend_option_tile.dart | 264x37 TextButton tile. | pinned_friend_options_dialog.dart:40,45 |
| profile_background_picture.dart | Own-profile background: tap opens a modal to pick from gallery or camera, or delete. Uploads through `AssetImageService`. | profile_page_header.dart:23 |
| profile_header_background_image.dart | `ProfileHeaderBackground`: `UserBackgroundImage` in a ClipRRect with bottom radius 25. | your_friend_profile_page.dart:30 |
| profile_page_add_friends_button.dart | White card "Add friends" button with request badge. Opens AddFriendsPage (bottomToTop transition). | lib/views/pages/navbar_pages/profile_page.dart:41 |
| profile_page_divider.dart | Thin coloured Container line. | Widely reused: capsule_creation_page.dart:128, history_page/capsule_list_tile.dart:154, capsule_selection_action_bar.dart:24,50, nested_menu.dart:58, pinned_friend_options_dialog.dart:39,44, profile_page_my_capsules_panel.dart:72, profile_page_my_friends_panel.dart:113 |
| profile_page_header.dart | Own-profile header: Stack of background picture, a 1px "shadow" bar, action buttons, avatar and name. | navbar_pages/profile_page.dart:33 |
| profile_page_header_action_buttons.dart | Notifications (with unread badge), Share and Settings icon buttons. | profile_page_header.dart:36 |
| profile_page_my_capsules_panel.dart | "My capsules" card with 2 text buttons that push `/camera` with privacy friends or public. | navbar_pages/profile_page.dart:39 |
| profile_page_my_friends_panel.dart | 150px card: PinnedFriendsRow (own `ChangeNotifierProvider<PinnedFriendsController>`) and a "My friends" button. | navbar_pages/profile_page.dart:43 |
| profile_picture.dart | Own-profile avatar (115x115): tap opens a modal to pick from gallery or camera, or delete. Uploads through `AssetImageService`. | profile_page_header.dart:46 |

### widgets/add_friend_profile/
| File | What it is | Used by |
|---|---|---|
| add_friend_profile_action_button.dart | Stack of Positioned bottom buttons chosen by the `buttonState` string. | add_friend_profile_page.dart:84 |
| add_friend_profile_avatar.dart | Positioned round avatar with Material elevation 8. **It returns a `Positioned`.** | add_friend_profile_header.dart:33 |
| add_friend_profile_background_image.dart | FutureBuilder on `FirebaseStorageService.getBackgroundImageUrl` that shows Image.network. | **UNUSED** |
| add_friend_profile_header.dart | Stack: rounded background, top shadow, back/share row, avatar. | add_friend_profile_page.dart:66 |
| add_friend_profile_main_button.dart | `AddProfileMainButton`: an ElevatedButton whose label and colour come from `buttonState`. | add_friend_profile_action_button.dart:40 |
| add_friend_profile_request_handle_button.dart | `AddProfileRequestHandleButton`: Cancel/Accept/Reject ElevatedButton. | add_friend_profile_action_button.dart:55,73,85 |
| friend_profile_action_buttons_row.dart | `ProfileActionButtonsRow`: back, share and optional menu icons. **It returns a `Positioned`.** | add_friend_profile_header.dart:32, your_friend_profile_page.dart:32 |

### pages/friends_pages/
| File | What it is | Reached from |
|---|---|---|
| add_friend_profile_page.dart | Profile of a non-friend or unknown user, with add/accept/reject/cancel. | deep_link_service.dart:26, qr_code_scanner_page.dart:33, suggested_friends_list.dart:132, received_list.dart:76, sent_list.dart:70 |
| add_friends_page.dart | Search, action row and suggested friends list. | main.dart:154 (route), profile_page_add_friends_button.dart:25 |
| friend_requests_page.dart | Received/Sent toggle and lists. | add_friends_action_buttons_row.dart:51 |
| my_friends_page.dart | Friends grouped by letter, with search. | main.dart:155, profile_page_my_friends_panel.dart:99 |
| your_friend_profile_page.dart | Profile of an existing friend (header, chat and capsule buttons, capsules placeholder, options menu). | pinned_friends_controller.dart:128, add_friend_profile_page.dart:49, my_friends_grouped_by_letter_list.dart:56 |

### pages/settings_pages/ (all reached from lib/views/pages/core_pages/settings_page.dart)
| File | Status |
|---|---|
| app_theme_settings_page.dart | **STUB**: "The feature will be added soon." plus a default-theme ElevatedButton "Back" (settings_page.dart:110) |
| email_settings_page.dart | **STUB**: "You can't change your email right now. Sorry for the inconvenience. Skebob..." (unprofessional placeholder text, line 16) (settings_page.dart:95) |
| language_settings_page.dart | **STUB**: "The feature will be added soon." (settings_page.dart:105) |
| password_settings_page.dart | **STUB**: "The feature will be added soon." (settings_page.dart:100) |
| profile_customization_settings_page.dart | **STUB**: "The feature will be added soon." (settings_page.dart:115) |
| name_settings_page.dart | Working: PageHeader, OptionsInputField, DefaultGreenButton calling `updateName`. Also a route in main.dart:153. |
| username_settings_page.dart | Working but unsafe: `updateUsername` with no normalization or uniqueness check (settings_page.dart:86). |
| permissions_settings_page.dart | Working: lists 5 permissions with a Switch. Builds its own header instead of using PageHeader. Has a `// TODO: Refactor` comment (line 5). (settings_page.dart:120) |

The five stub pages are identical except for the class name and message string.

---

## 2. Bugs / defects

### HIGH

**H1. `UserFriendsService()` is instantiated directly inside modals. Each instance starts 3 Firestore realtime listeners and a users-doc read that are never cancelled.**
- Where: `widgets/friends/friend_options_modal.dart:111` (`_ManageFriendshipModalState._friendsService = UserFriendsService()`) and `:274` (`_RemoveFriendConfirmModalState._requestService = UserFriendsService()`).
- Root cause: the `UserFriendsService` constructor calls `init()`, which runs `refreshFriends()` plus `_listenSentRequests/_listenReceivedRequests/_listenFriends`. The instance is never disposed and `onLogout` is never called on it.
- Effect: every open of "Manage friendship" or the remove-friend confirm leaks 3 snapshot listeners and 1 read for the rest of the session. They keep listening after logout and are billed on every change to any request involving the user.
- Fix: use `context.read<UserFriendsService>()`.

**H2. Suggested-friends stream is unbounded and re-created on every rebuild and every keystroke.**
- Where: `widgets/friends/add_friends_page/suggested_friends_list.dart:53-60`. `userFriendsService.getSuggestedFriends(...)` is called inside `AnimatedBuilder.builder` in `build`. The parent `add_friends_page.dart:48-52` calls `setState` on every keystroke, and the list rebuilds on every `UserFriendsService.notifyListeners`, which it hears twice, through `context.watch` (line 50) and `AnimatedBuilder` (line 53).
- Root cause: the query is `users where documentId != me` with **no limit** (`lib/services/user_friends_service.dart:235-262`). StreamBuilder unsubscribes and re-subscribes to a new listener on each build, so the whole users collection is re-read each time.
- Effect: cost and latency grow with the user base, and every user's name and username is exposed to every client.
- Related problems:
  - The `searchQuery` sent to Firestore is the raw input; it is not lower-cased. Usernames are stored lower-case, so typing "John" returns nothing.
  - The server filter applies from 1 character, but the client `_matchesSearch` only applies from 2 (line 152).
  - The documentId inequality combined with a username range needs a composite index. If it is missing, `snapshot.hasError` is never handled (line 62 only checks `hasData`), so the list stays blank silently.

**H3. N+1 reads and image preloads per suggested user, triggered from `build`.**
- Where: `suggested_friends_list.dart:76-84` calls `controller.loadUser` for every user during build. `SuggestedFriendsListController.loadUser` then does `getUserData` (a Firestore read) and `imageService.getProfileNotifier` plus `precacheImage`.
- The stream already contains `name` and `username`, so the extra read is redundant.
- The list is a non-lazy `ListView(children: …)` (line 86), so every row and image is built at once.

**H4. Profile and background image upload has no compression, size limit, content type, or per-user cache, and resizing distorts the avatar.**
- Where: `widgets/my_profile_page/profile_picture.dart:42-56` and `profile_background_picture.dart:47-54`. `ImagePicker().pickImage(source: …)` is called with no `maxWidth`, `maxHeight` or `imageQuality`.
- The full-resolution bytes (often 3–15 MB) are then:
  - (a) uploaded with `putData` and no `SettableMetadata(contentType)`, via `image_assets_service.dart:38,79`;
  - (b) base64-encoded into SharedPreferences under the global keys `'profile_image'` / `'background_image'` (`image_assets_service.dart:44,82`), which inflates them by about 33%;
  - (c) decoded and resized synchronously on the UI isolate by `img.decodeImage`/`copyResize(width:128,height:128)` (`image_assets_service.dart:131-134`). This freezes the UI on large photos and **squashes non-square photos** (aspect distortion) for `profile_image_small`.
- After upload, `UserImageService` is not told: no invalidation or notifier update. Every other avatar of the current user (`UserRoundAvatar`, `UserProfileImage`, friends' views) stays stale, or stays "no avatar" because of its negative cache.

**H5. Deleting a picture when none exists (or when the small variant is missing) locks the widget forever.**
- Where: `profile_picture.dart:58-66` and `profile_background_picture.dart:84-90`. There is no try/catch.
- Root cause: `AssetImageService.deleteProfileImage` deletes `profile_image` and then `profile_image_small`. Storage throws `object-not-found` if either is missing. This is guaranteed when the user taps "Delete profile icon" without a picture, because the option is always shown.
- Effect: `isUploading` stays `true`, the "Updating..." loader shows permanently, and `onTap` is `null` (line 204 / 217) until the page is rebuilt from scratch. The exception is also unhandled.
- On top of that, `setState` is called after `await` without a `mounted` guard (profile_picture.dart:62, profile_background_picture.dart:89), so it throws if the page was popped.

**H6. `FriendRequestCountBadge` returns a `Positioned`, and one call site wraps it in another `Positioned`.**
- Where: `widgets/friends/friend_requests_count.dart:17` returns `Positioned(top:15,right:12)`. `add_friends_action_buttons_row.dart:59-63` wraps it in `Positioned(top:-4,right:-4)`.
- Effect: two `Positioned` (ParentDataWidgets) target the same RenderObject. Debug builds throw "Incorrect use of ParentDataWidget" whenever there is at least one received request. In release the outer one wins, which gives -4/-4.
- The two call sites therefore depend on different effective offsets: the profile button gets 15/12, the Requests button gets -4/-4. The shared badge component must take its position from the caller.
- The same "widget returns Positioned" pattern appears in `AddFriendProfileAvatar` (add_friend_profile_avatar.dart:20) and `ProfileActionButtonsRow` (friend_profile_action_buttons_row.dart:18). It works there only because both are direct Stack children. `FriendRequestsToggleButton` likewise returns `Expanded` (friend_requests_toggle_button.dart:21).

**H7. `MyFriendsPage` crashes when a friend's name is an empty string.**
- Where: `lib/controllers/page_controllers/friends/my_friends_page_controller.dart:65` evaluates `friend['name'][0]`, and `pages/friends_pages/my_friends_page.dart:95` calls `groupedFilteredFriends` on every build.
- `getUserData` returns `''` when the Firestore field is `''` (it only defaults when the field is null). That produces a RangeError and a red screen on My Friends.
- `my_friends_grouped_by_letter_list.dart:45-47,56` uses `friend['name']!` etc. on a `Map<String,dynamic>`. That is fragile but not currently reachable as null.

**H8. Username change has no normalization, uniqueness, or format validation.**
- Where: `pages/settings_pages/username_settings_page.dart:27-66` calls `lib/services/user_data_service.dart:86-98`.
- Accepted as typed: mixed case, spaces inside, emoji, any length, and a username already taken by another user.
- Effects:
  - Mixed case breaks prefix search (H2), because signup stores usernames lower-case.
  - Duplicates make `@username` identity ambiguous.
  - There is no transaction or reservation document (e.g. `usernames/{name}`).
- `uid` may be `'No User'` (line 38-41). `update()` on a missing doc then fails, and the user sees a generic "Failed".
- Also: `_usernameController` is never disposed (dispose at lines 21-25 only calls `PopupNotificationService.hide()`).

**H9. Own-profile picture and background read `currentLoggedInUid` once in `initState`.**
- Where: `profile_picture.dart:28-31` and `profile_background_picture.dart:32-36`.
- If the profile is not yet fetched, `uid == 'No User'`, which is non-null, so every `if (uid == null) return;` guard is useless.
- Effects:
  - The first load reads `userdata/No User/...` from Storage.
  - An upload in that window writes to `userdata/No User/assets/images/...`.
  - Because the local cache key is global (`'profile_image'`), a previous account's cached image is shown if `clearLocalCache` did not run (it runs in logout_button.dart:35 and settings_page.dart:132, but not on token expiry or account deletion).
- The uid is never re-read when the user changes.

### MEDIUM

**M1. Pinned-friends row is re-shuffled and re-fetched on every rebuild.**
- Where: `widgets/my_profile_page/my_friends_panel/pinned_friends_row.dart:32-34` creates `FutureBuilder(future: controller.getDisplayFriends())` in `build`.
- `getDisplayFriends` shuffles the non-pinned friends and calls `FirebaseStorageService.getProfileImageUrl` for each (pinned_friends_controller.dart:84-93). So every rebuild (any `UserFriendsService` notify, controller notify, MediaQuery change) shows a **different random set of friends** and repeats the Storage URL lookups.
- `controller._loadFriends` also sets `isLoading=true` on every friends-service notify. The row collapses to a 80px blank (line 16-18) and flickers.
- `print()` appears at pinned_friends_controller.dart:95-97.

**M2. Pinned selection limit can be blocked by invisible stale uids.**
- Where: `pinned_friends_selection_dialog.dart:36` (`tempPinned = List.from(widget.pinnedUids)`) and the check at `:132`.
- `pinnedUids` comes from the global SharedPreferences key `pinned_friend_uids`, which is a known service issue. It can hold uids of removed friends or another account's friends. Those uids are filtered out of the visible list (`allFriends` only) but still count toward `tempPinned.length >= 3`.
- Effect: the user gets "You can only pin up to 3 friends" with nothing checked and cannot clear the stale entries.
- Fix: intersect with `allFriends` in initState.

**M3. Pinned selection Save shows no success popup and swallows errors.**
- Where: `pinned_friends_selection_dialog.dart:110-121` (same at choose_pinned_friends_dialog.dart:109-120). It runs `Navigator.pop(context)` first, then `await widget.onSave`, then `if (mounted) showSuccess`.
- After the pop the State is disposed, so `mounted` is false and the success popup is dead code.
- Errors from `onSave` are unhandled (an unawaited exception).
- `searchController` is never disposed in either dialog (line 31 / 30).

**M4. Accept/Reject on AddFriendProfilePage has no loading state or double-submit guard.**
- Where: `widgets/add_friend_profile/add_friend_profile_action_button.dart:76,87` pass `isCancelling` to the Accept and Reject buttons. `AddFriendProfileController.acceptFriendRequest`/`rejectFriendRequest` toggle `isLoading` instead (add_friend_profile_controller.dart:115,142).
- Effect: no spinner, buttons stay enabled, and repeated taps fire repeated batch writes.
- Also, `AddProfileMainButton`'s `'pending'` branch (add_friend_profile_main_button.dart:70-71, 83-84) is unreachable, because the action button renders a separate Cancel button for `'pending'`. The yellow `0xFFFDDB07` and the "Pending" label are dead code.

**M5. Friend-request list rows have no in-flight guard, and success toasts never appear.**
- Where: `friend_requests_received_row.dart:69-79` and `friend_requests_sent_row.dart:56-60`. Rapid double tap on Accept, Reject or Cancel fires duplicate service calls.
- The `context` passed to the controller is the row's `FutureBuilder` context (received_list.dart:63,67; sent_list.dart:61). When the request disappears from the stream the row unmounts, so `PopupNotificationService` (which checks `context.mounted`) silently skips the "accepted", "rejected" or "cancelled" toast.
- There is a FutureBuilder per item (`getUserData`), i.e. N+1 reads on first load. Its future is recreated in `itemBuilder` on every Consumer rebuild.
- The `?? 'Unknown User'` / `?? 'unknown'` fallbacks (received_list.dart:53-54, sent_list.dart:51-52) are dead, because getUserData never returns nulls.

**M6. Page controllers are never disposed, which leaks listeners on the global `UserFriendsService`.**
- `pages/friends_pages/add_friends_page.dart:43-46` creates `AddFriendsPageController` (addListener in its constructor). `dispose` at lines 56-60 does not dispose it.
- `pages/friends_pages/friend_requests_page.dart:36-39` creates `FriendRequestsPageController`. `dispose` at lines 43-46 does not dispose it.
- Every visit leaves a permanent listener.

**M7. Header buttons are hard-positioned under the status bar, with no SafeArea.**
- `profile_page_header.dart:34` uses `Positioned(top: 35, right: 12)`. `friend_profile_action_buttons_row.dart:19` uses `top: 32`. The status bar on notch / Dynamic Island iPhones is 47–59px, so these buttons overlap the status bar.
- `permissions_settings_page.dart:225-290` puts its header at `screenHeight*0.16` with the back button at `bottom: 39`, also with no SafeArea.

**M8. Layout overflow and clipping risks from mixing fixed and ratio sizing.**
- `your_friend_profile_page.dart:40-44`: the avatar row sits at `top: screenHeight*0.108` with a 115px avatar, inside a Stack sized by a fixed 230px `ProfileHeaderBackground`. On tall screens (height ≥ about 1065, e.g. tablets) the avatar and name extend past 230 and are **clipped** by the Stack's default hardEdge clip.
- `profile_page_header.dart:39-46`: avatar at `top: 99` with height 115 = 214, inside 230. That works, but nothing scales.
- `add_friend_profile_page.dart:61-70`: `avatarRadius: 100` (a 200px avatar) is fixed, `bgHeight` is `0.32*h`, and there is a fixed `SizedBox(110)` while the bottom buttons sit at `0.1*h`. On small screens (e.g. 568pt tall) the name sits under the bottom action buttons.
- `add_friend_profile_action_button.dart:37-41`: `Positioned(left/right: 0.15w)` forces width 0.70w, so the child's `width: screenWidth*0.73` is ignored (dead value).
- Fixed-height modal containers: `profile_picture.dart:113` and `profile_background_picture.dart:108` use `height: 153`, which is exactly 37+1+37+2+37+2+37. Any text-scale increase clips the labels, and 264/37 boxes do not grow.
- `friend_requests_received_row.dart:46-57`: the name sits in a `FittedBox`, so `maxLines: 2` and the ellipsis never apply. Long names shrink to unreadable size instead. Sent row names (`sent_row.dart:42-47`) have no maxLines or ellipsis.
- `profile_page_my_friends_panel.dart:89`: `SizedBox(width: screenWidth - 95)` inside a card of width `screenWidth - 32` is a magic number tied to the 18+40+5 offsets.

**M9. `ProfileBackgroundPicture` uses the font family 'Inria', which is a typo for 'Irina'.**
- Where: `profile_background_picture.dart:246`. pubspec only declares `Irina`, so the "Updating..." caption silently renders in the platform default font (Roboto/SF).
- This is a visible difference from `ProfilePicture`'s loader. The refactor must decide whether to preserve it or fix it.

**M10. TODO buttons that do nothing (silent no-ops):**
- `friend_options_modal.dart:49-54` "Chat settings" only closes the modal (`// TODO`).
- `friend_options_modal.dart:57-62` "Capsules settings" only closes the modal.
- `friend_options_modal.dart:65-71` "Share profile to ..." only closes the modal (SharingService already exists).
- `friend_options_modal.dart:208-215` "Report" only closes the modal.
- `friend_options_modal.dart:217-224` "Block" only closes the modal.
- `your_friend_profile_page.dart:85` "Open chat": `onTap: () {}`.
- `your_friend_profile_page.dart:97` "Send Capsule": `onTap: () {}`.
- `your_friend_profile_page.dart:113-124`: "Friend's capsules will appear here" is a static placeholder with no data.
- The 5 stub settings pages (section 1).
- `permissions_settings_page.dart:5`: `// TODO: Refactor`.

**M11. Follow / unfollow and remove-friend use `currentLoggedInUid` without guarding against 'No User'.**
- `friend_options_modal.dart:121-127,146-163,295-297`. With `'No User'`, `followUser` writes to `users/No User/following/...`, and `removeFriend` `update()`s `users/No User` (fails).
- `contacts_list.dart:37,45` (unused file) would build the invite link `?userId=No User`.

**M12. `NameSettingsPage` uses context and setState after await without mounted checks.**
- `name_settings_page.dart:42-57`: `setState` at line 43 and `PopupNotificationService` with `context` at 46/52 run after `await` with no `mounted` check. Popping during the save throws "setState() called after dispose()".
- The current name and username are not pre-filled in either settings page.
- The trimmed name has no max length.

**M13. `RemoveFriendConfirmModal` double pop and a global popup hide.**
- Where: `friend_options_modal.dart:300-303`. It calls `Navigator.of(context).pop()` twice: once to close the sheet, then once more to close **YourFriendProfilePage** with the `'friend_removed'` result, which no caller reads.
- If YourFriendProfilePage was pushed from AddFriendProfilePage (add_friend_profile_page.dart:42-52), the user lands back on AddFriendProfilePage. Its `buttonState` updates only through the friends listener, and only after `refreshFriends` clears and reloads.
- `dispose` (line 276-280) calls `PopupNotificationService.hide()`, which hides the global popup. That includes the "Failed to remove friend" error the modal just showed, if the user dismisses quickly.
- `FriendOptionsModal` → `ManageFriendshipModal.show(context, …)` (line 42-43) and `ManageFriendshipModal` → `RemoveFriendConfirmModal.show(context, …)` (line 229-230) both call `show` on a context whose route was just popped. This works only during the exit animation and is fragile.

**M14. `PermissionsSettingsPage` shows stale status and uses context after await.**
- Statuses are loaded only in `initState` (line 55-58). Returning from the OS settings (`openAppSettings`, lines 123/167) does not refresh, because there is no `WidgetsBindingObserver` / resume hook. The Switch shows the old state.
- `_requestPermission` (85-94) calls `_showPermissionDialog(permission)` (which uses `context`) after `await` with no `mounted` check.
- The Switch `onChanged` while granted cannot actually revoke; it just opens a dialog. The Switch flips visually only after a refresh, which never happens.
- `import 'dart:io'` with `Platform.isIOS` in a field initializer (line 35) throws on web builds.

**M15. Async results applied without `mounted` checks (setState after dispose):**
- `profile_picture.dart:37-39` (`loadCachedImage`), `:62-65` (delete), `:73` (save success).
- `profile_background_picture.dart:89` (delete).
- `name_settings_page.dart:43`.
- Controllers used by these pages call `notifyListeners()` after `await` on possibly disposed instances, which produces "used after disposed" errors when the page is popped mid-request: `AddFriendProfileController` (finally blocks at 84-85, 109-110, 136-137, 163-164) and `MyFriendsPageController._preloadFriendsData` (line 102-103).

### LOW

- **L1.** `contacts_list.dart:74` contains `print('Error sending invite: $e')` in an unused file. Also, `contacts_list.dart:41-43` has no-op phone logic: `if (!phoneNumber.startsWith('+')) phoneNumber = phoneNumber.replaceAll('+','')`.
- **L2.** Unused parameters:
  - `ProfileBackgroundPicture.pictureWidth` and the misspelled `required Alignment allignment` (profile_background_picture.dart:12,17).
  - `ProfilePageAddFriendsButton.currentUserUid` (:9).
  - `ProfilePageMyFriendsPanel.currentUserUid` (:14).
  - `FriendRequestsActionButton.contentPadding` (:7).
  - `FriendRequestsToggleButton.contentPadding` (:7).
  - `PinnedFriendOptionsDialog.friendUid` is used, but `pinnedImages` in the controller is never read by the widgets.
  - `AddFriendProfilePage.onStateChanged` (add_friend_profile_page.dart:16) is never used.
- **L3.** Dead files: `contacts_list.dart`, `choose_pinned_friends_dialog.dart`, `add_friend_profile_background_image.dart`. The last one also calls Firebase Storage directly in `build` (line 28), creating a new FutureBuilder future per rebuild.
- **L4.** `suggested_friends_list.dart:30,109-110`: `AutomaticKeepAliveClientMixin` is pointless, because the widget is not in a lazy list or tab. `SuggestedFriendsListController` stores the widget's `BuildContext` (line 42).
- **L5.** `PinnedFriendOptionsDialog` (pinned_friend_options_dialog.dart:23-27) has no inner `GestureDetector(onTap:(){})`. Tapping the card body (e.g. the name) closes the dialog, which is inconsistent with the other modals.
- **L6.** `pinned_friends_row.dart:57`: `Navigator.pop(context)` uses the *profile page* context to close the sheet. It works only because the sheet is the top route.
- **L7.** `profile_picture.dart:181-183` / `profile_background_picture.dart:140-142`: the option buttons pop using the State's (page) context, which is the same fragility as L6.
- **L8.** `_ModalHeader` (friend_options_modal.dart:386-392) has a `BoxDecoration` with borderRadius but no colour, so it is a no-op decoration.
- **L9.** Destructive colours are inconsistent: "Remove from friends" uses `Colors.red` (0xFFF44336, friend_options_modal.dart:232), "Report"/"Block" use `#FD4140`, the Reject/Cancel default is `Colors.red` (add_friend_profile_request_handle_button.dart:35), and the delete options use `ARGB(253,253,65,64)` (alpha 253, almost certainly a typo).
- **L10.** Inline raw `Text` ignores DefaultText: `pinned_friends_row.dart:24-27` ("You have no friends yet", no colour, theme default) and the stub pages (`Colors.black54`, default Material `ElevatedButton` styled by `ColorScheme.fromSeed(Colors.green)`). Both are visually off-brand.
- **L11.** `add_friend_profile_controller.dart:120,147` builds the request id with `'$userId\_$currentUserUid'`. It is correct in Dart (`\_` becomes `_`) but obscure, and the analyzer flags `unnecessary_string_escapes`. Request ids are otherwise consistent (`{from}_{to}`) across the widgets' controllers.
- **L12.** `UserNameAndUsername` in the own-profile header reads `getUserData` with `listen:false` (profile_page_header.dart:49). The header updates after a name or username change only if a parent rebuilds.
- **L13.** `email_settings_page.dart:16` contains the unprofessional placeholder copy "Skebob...". Stub pages use background `#F5F5F5` while the friends pages use `#F6F6F6`.
- **L14.** No raw exception text is shown to users in scope; all errors are generic strings. There is no `print()` in scope apart from L1 (and the controller prints noted in M1).
- **L15.** `ContactsList.build` evaluates `_filteredContacts` twice (lines 186, 219, 221 re-filter on each call; O(n) per item in `itemBuilder`).

---

## 3. Design tokens observed

### 3.1 Colors
| Value | Form in code | Where (file:line) | Count |
|---|---|---|---|
| **#56C92E** brand green | `Color.fromARGB(255,86,201,46)` / `Color(0xFF56C92E)` | contacts_list:145; friend_requests_received_row:71; friend_requests_toggle_button:27,30,43; choose_pinned_friends_dialog:97; pinned_friends_selection_dialog:98; pinned_friend_options_dialog:35; pinned_friends_selection_dialog_header:25; profile_background_picture:123,134; profile_picture:128,139; add_friend_profile_action_button:75; add_friend_profile_main_button:88; permissions_settings_page:204,384. Also defaults in BoxDecorations.defaultBorderRadius and DefaultGreenButton | 17 in scope |
| **#FD4140** destructive red | `ARGB(255,253,65,64)` | friend_options_modal:214,223,345; friend_requests_received_row:77; friend_requests_sent_row:58 | 5 |
| #FDFD4140 (alpha 253, typo) | `ARGB(253,253,65,64)` | profile_background_picture:193; profile_picture:156 | 2 |
| Colors.red #F44336 | `Colors.red` | friend_options_modal:232; friend_requests_count:25; add_friend_profile_request_handle_button:35 | 3 |
| #FF5757 | `ARGB(255,255,87,87)` | permissions_settings_page:207 (denied status) | 1 |
| Colors.orange #FF9800 | | permissions_settings_page:211 | 1 |
| **#D3D3D3** divider grey | `ARGB(255,211,211,211)` | friend_options_modal:538; profile_page_divider:12 (default); profile_background_picture:158,181; profile_picture:145,151 | 6 |
| #5F5F5F | `ARGB(255,95,95,95)` | friend_options_modal:604 (Cancel text) | 1 |
| #5E5E5E secondary text | `Color(0xFF5E5E5E)` / `ARGB(255,94,94,94)` | suggested_friend_row:52; permissions_settings_page:265 (also UserNameAndUsername default) | 2 |
| #BBBBBB | `ARGB(255,187,187,187)` | profile_background_picture:222 (empty background) | 1 |
| #DFDFDF | `ARGB(255,223,223,223)` | profile_picture:209 (empty avatar) | 1 |
| #EAEAEA | `Color(0xFFEAEAEA)` | contacts_list:104 (also BoxDecorations.greyCard) | 1 |
| #2196F3 (= Colors.blue) | `ARGB(255,33,150,243)` | contacts_list:181; permissions_settings_page:129,173 | 3 |
| #3690FF | `ARGB(255,54,144,255)` | add_friend_profile_main_button:86 ("View Profile") | 1 |
| #FDDB07 | `ARGB(255,253,219,7)` | add_friend_profile_main_button:84 ("Pending", unreachable) | 1 |
| #6C757D | `ARGB(255,108,117,125)` | add_friend_profile_main_button:82 ("My Profile") | 1 |
| **#F6F6F6** page bg (friends) | `Color(0xFFF6F6F6)` | add_friend_profile_page:57; add_friends_page:67; friend_requests_page:53; my_friends_page:58; your_friend_profile_page:24 | 5 |
| **#F5F5F5** page bg (settings) | `Color(0xFFF5F5F5)` | app_theme:29; email:29; language:29; name:66; password:29; permissions:221; profile_customization:29; username:74 | 8 |
| Colors.grey[300] #E0E0E0 | | suggested_friend_placeholder_row:21,32,38; friend_options_modal:486 (Following bg); add_friend_profile_background_image:61,79 | 6 |
| Colors.grey[500] #9E9E9E | | add_friend_profile_background_image:70 | 1 |
| Colors.grey[600] #757575 | | contacts_list:116,136; friend_requests_received_row:63; friend_requests_sent_row:51; your_friend_profile_page:121; permissions_settings_page:354 | 6 |
| Colors.grey #9E9E9E | | choose_pinned_friends_dialog:93; pinned_friends_selection_dialog:94; permissions_settings_page:117,161,385; `Colors.grey.withValues(alpha:0.3)` :386 | 6 |
| Colors.black54 (#8A000000) | | 5 stub pages, line 17 each | 5 |
| Colors.black45 (#73000000) | | pinned_friend_options_dialog:39 | 1 |
| Colors.black12 (#1F000000) shadow | | add_friend_profile_main_button:30 (also BoxDecorations.whiteCard / softBlackShadow) | 1 (+ shared) |
| black @ 0.05 shadow | `Colors.black.withValues(alpha:0.05)` | contacts_list:95; permissions_settings_page:316 | 2 |
| **Barrier black @ 128/255 (≈0.5)** | `Colors.black.withAlpha(128)` | friend_options_modal:17,88,251; pinned_friends_row:52; profile_background_picture:99; profile_picture:104 (+ pinned_friends_controller:109) | 6 (+1) |
| status tint | `statusColor.withValues(alpha:0.1)` | permissions_settings_page:366 | 1 |
| Colors.white | | ubiquitous (cards, button text, header text on images) | many |
| `ARGB(255,255,255,255)` (white spelled out) | | profile_page_my_friends_panel:63 | 1 |
| Colors.black | | ubiquitous text and progress indicators | many |

### 3.2 Typography (family is 'Irina' unless noted; the theme default is also 'Irina', main.dart:183)
| Size | Weight | Where | Role |
|---|---|---|---|
| 32 / 20 | bold / bold | profile_page_header:51-52 (white) | own profile name / username |
| 25 | bold | friend_options_modal:397 (black); profile_background_picture:124 (green); profile_picture:129 (green) | modal title (3) |
| 22 | bold | pinned_friend_options_dialog:34 (green); pinned_friends_selection_dialog_header:23 (green) | dialog title (2) |
| 20 | bold | contacts_list:114 (grey600 initial); pinned_friends_row:26 (no family, theme) | (2) |
| 18 | bold | choose_pinned_friends_dialog:87; pinned_friends_selection_dialog:88; profile_page_my_capsules_panel:20; your_friend_profile_page:83,95,109 | section and list title (6) |
| 18 | w500 | contacts_list:125 | |
| 18 | w600 | permissions_settings_page:340 | |
| 17 | bold | friend_options_modal:449,489; pinned_friend_option_tile:23; profile_background_picture:147,171,195; profile_picture:188; contacts_list:203 | **modal option text (7 + 1)** |
| 16 | bold | friend_options_modal:335,572,606 | confirm modal text and buttons (3) |
| 16 | normal | profile_page_add_friends_button:54; your_friend_profile_page:120 (grey600) | (2) |
| 16 | normal, no family | 5 stub pages (black54) | (5) |
| 14 | normal | contacts_list:135; choose:92; selection:92 (grey); permissions:353 | subtitle |
| 14 | bold | pinned_friends_selection_dialog_header:30; permissions:263 (#5E5E5E) | |
| 14 | w500 | contacts_list:162 (white "Invite", no family) | |
| 14 (default) | normal/bold | DefaultText default; friend_requests_action_button (bold, white) | |
| 12 | bold | friend_requests_count:33 (white) | badge |
| 12 | normal | profile_background_picture:245 (**'Inria'** typo) | loader caption |
| 12 | w500 | permissions_settings_page:372 (no family) | status pill |
| sw*0.095 | bold | permissions_settings_page:247 | page title |
| sw*0.07 / sw*0.05 | bold (default) | your_friend_profile_page:59-60 | friend name / username |
| sw*0.055 | bold | my_friends_grouped_by_letter_list:36 | letter header |
| sw*0.045 | bold | suggested_friend_row:42; friend_requests_received_row:52; friend_requests_sent_row:45; add_friends_page:92; add_friend_profile_action_button:29 (button text) | **list name (5)** |
| sw*0.04 | normal/bold | suggested_friend_row:50 (username); friend_requests_toggle_button:37 (bold) | (2) |
| sw*0.035 | normal | friend_requests_received_row:62; friend_requests_sent_row:50 | username (2) |
| 30 (default) | bold | DefaultGreenButton default (used by pinned dialogs and name/username Save) | |

- letterSpacing: **none** anywhere in scope.
- Text `height`: none in scope (UserNameAndUsername uses 1.0).
- Families: 'Irina' (explicit about 25 times), 'Inria' (1, a typo), and default/theme.

### 3.3 Border radii
| Radius | Where | Count |
|---|---|---|
| **25** | friend_options_modal:326,369,389-390,428,431-432,436-437,565; choose:58; selection:59; pinned_friend_avatar:26-27 (top only); profile_background_picture:111,224-225 (bottom only); profile_header_background_image:13 (default param); profile_page_my_friends_panel:65-66 (bottom); profile_picture:116,158-159,210; add_friend_profile_background_image:21-22,35-36,53-54,63-64,81-82 (bottom); add_friend_profile_main_button:36; your_friend_profile_page:53; permissions:231-232 (bottom); suggested_friend_row:31 (InkWell). Shared: BoxDecorations.whiteCard/softBlackShadow/defaultBorderRadius, ElevatedButtonStyles.roundedButtonStyle, DefaultGreenButton | ~30 |
| 20 | contacts_list:146 (Invite pill); friend_requests_toggle_button:28 | 2 |
| 16 | BoxDecorations.blackShadow (profile_page_header:31) | 1 |
| 15 | contacts_list:92; permissions_settings_page:102,146,313 | 4 |
| 12 | permissions_settings_page:328 | 1 |
| 10 | friend_requests_count:26 (badge = height/2) | 1 |
| 8 | permissions_settings_page:367 (status pill) | 1 |
| 5 | choose:99; selection:100 (Checkbox) | 2 |
| 0 (explicit) | friend_options_modal:454,494; pinned_friend_option_tile:27; profile_picture:193 | 4 |

### 3.4 Shadows / elevation
| Token | Spec | Where |
|---|---|---|
| whiteCard shadow | black12, blur 9, spread 1, offset (0,4); white; r25 | via `BoxDecorations.whiteCard()`: received_row:31; sent_row:29; grouped_list:40; pinned_friend_options_dialog:29; profile_page_add_friends_button:32; my_capsules_panel:28; my_friends_panel:40; your_friend_profile_page:82,94,116 (10 uses) |
| softBlack shadow | black12, blur 16, spread 1, offset (0,6); r25 | `BoxDecorations.softBlackShadow()` request_handle_button:30; **duplicated inline** in add_friend_profile_main_button:28-36 |
| subtle card shadow | black @0.05, blur 5, spread 0, offset (0,2); white; r15 | contacts_list:93-99; permissions_settings_page:314-320 |
| header top shade | black (alpha 120), blur 20, spread 15, offset (0,6), on a 1px black bar, r16 | profile_page_header:28-32 (`BoxDecorations.blackShadow`). ShadowTopOverlay is used in the other two headers |
| Material elevation | 8, CircleBorder | add_friend_profile_avatar:24 |
| ElevatedButton elevation | 0 | ElevatedButtonStyles (main and request-handle buttons) |

### 3.5 Spacing / padding
| Value | Where | Count |
|---|---|---|
| **16** | add_friends_action_buttons_row:38 (gap); friend_options_modal:341; received_row:33 (all); sent_row:31 (all); grouped_list:29 (h); choose/selection:74/75 (h list), 108/109 (button all); dialog_header:18 (all); profile_page_header:40 (left) and screenWidth-32 (=16 each side) in about 8 places; your_friend_profile_page:74 (h), 77, 125; stub pages:10 (all); permissions:323 (ListTile all) | ~20 |
| 12 | friend_options_modal:323 (t/l/r); received_row:30, sent_row:28 (bottom margin); received_row:39, sent_row:37 (gap); dialog_header:34; add_friend_profile_action_button:83; friend_requests_page:66; your_friend_profile_page:91; contacts:143 (h); profile_page_header:35 (right) | 12 |
| 8 | suggested_friend_placeholder_row:13 (v); suggested_friend_row:72; contacts:143 (v), 197; friend_options_modal:517; grouped_list:64; friend_profile_action_buttons_row:39; your_friend_profile_page:112; permissions:357, 360 (h) | 10 |
| 4 | placeholder_row:34; contacts:89 (v margin); grouped_list:38; pinned_options:37 (v); dialog_header:27; profile_page_header_action_buttons:41; permissions:348, 361 (v) | 8 |
| 24 | my_friends_page:105; your_friend_profile_page:106; stub pages:20 (x5) | 7 |
| 18 | profile_page_add_friends_button:41,50; profile_page_my_friends_panel:78 | 3 |
| 15 | received_list:40; sent_list:39 (ListView all) | 2 |
| 5 | profile_page_header_action_buttons:57; my_friends_panel:87; LaterLoadingBar messageSpacing 5 (pp:223, bg:243) | 4 |
| 6 | contacts:157; friend_requests_count:23 (h) | 2 |
| 2 | pinned_friend_avatar:24 (h margin); my_capsules_panel:24 | 2 |
| 1 | friend_options_modal:323 (bottom) | 1 |
| 10 | permissions:269 | 1 |
| 20 / 65 | my_capsules_panel:34 (left 20), 50/69/76 (left 65), right 20 | |
| 60 / 80 | profile_background_picture:238 (bottom 60), 257 (top 80) | |
| 110 | add_friend_profile_page:76 | |
| Ratio-based | sw*0.05 / sh*0.015 (action_buttons_row:15-16); sw*0.02 (placeholder:12, suggested_row:34); sw*0.03 (placeholder:25 gap; action_button:26 h); sh*0.01 (action_button:26 v); sw*0.04 (contacts:89; profile_page_header:47; your_friend:42,55; permissions:297-299); sw*0.07 (add_friends_page:89); sw*0.02 / sw*0.01 (received_row:68,74); sh*0.007 / sh*0.12 (contacts:216-217); sh*0.45 (add_friend_profile_page:62); sh*0.108 (your_friend:43); sh*0.02 (name:77, username:82); sw*0.15 (name:87, username:90 SafeArea minimum); sw*0.05 (permissions:255); sh*0.04 / sh*0.015 (permissions:300,310) | |

### 3.6 Fixed sizes
| Value | Where | Notes |
|---|---|---|
| **264 width** | friend_options_modal:366,385,443,480,536; pinned_friend_option_tile:17; profile_background_picture:107,118,132,138,156,162,180,186; profile_picture:112,123,137,143,149,179 | Modal width: 20 occurrences |
| **37 height** | friend_options_modal:384,442,479; pinned_friend_option_tile:16; profile_background_picture:117,137,161,185; profile_picture:122,178 | Modal row height: 10 occurrences |
| 153 | profile_background_picture:108; profile_picture:113 | Picture-options modal height |
| 240 | friend_options_modal:322 | Confirm modal width |
| 250 | pinned_friend_options_dialog:28 | Pinned options card width |
| 140 x 45 | friend_options_modal:561-562 | Confirm button |
| 45 height | profile_page_add_friends_button:31; profile_page_my_friends_panel:61 | Card button row |
| 150 | profile_page_my_friends_panel:39 (card height); profile_picture:206-207 (default avatar) | |
| 80 | profile_page_my_capsules_panel:27; your_friend_profile_page:115 (card heights); received_list:49; sent_list:47; pinned_friends_row:17 (loading placeholders) | |
| 39 / 41 | my_capsules_panel:54, 70 (top 39), 80 | Split card rows |
| 70 | pinned_friends_row:22 | Empty state height |
| 230 | profile_page_header:25; profile_header_background_image:12 (default) | Header background height |
| 200 | profile_background_picture:219 (default) | |
| 115 | profile_page_header:46 (115x115); your_friend_profile_page:52 | Profile avatar |
| top 99 / top 35 / right 12 / left 16 | profile_page_header:34-35,39-40 | |
| top 32 / left 16 / right 16 | friend_profile_action_buttons_row:19-21 | |
| 40 x 40 | profile_page_add_friends_button:43-44; my_capsules_panel:36-37; my_friends_panel:80-81; LaterLoadingBar (pp:220-221, bg:240-241) | Panel icons |
| 35 x 35 | profile_background_picture:260-261; profile_picture:229-230 | "choose" placeholder icons |
| 35 height | friend_requests_toggle_button:25 | Toggle |
| 2 | friend_requests_toggle_button:33 (border width) | |
| 20 x minW 20 | friend_requests_count:21-22 | Badge |
| 72 x 72 | contacts_list:193-194 | Empty icon |
| 50 x 50 / 24 x 24 | permissions:325-326 / 332-333 | |
| 20 x 20 | contacts_list:153-154 | Invite icon |
| radius 25 | contacts_list:103 | CircleAvatar |
| radius 24 | choose:84; selection:85 | List avatar |
| radius sw*0.07 | suggested_row:37; received_row:38; sent_row:36 | List avatar (3) |
| avatarRadius 100 | add_friend_profile_page:69 | |
| sw/3.8 | pinned_friends_row:14 | Pinned avatar |
| sw*0.14 / 0.3 x 0.04 / 0.2 x 0.03 | suggested_friend_placeholder_row:18-19,30-31,36-37 | Skeleton |
| sw*0.09 / sw*0.07 | suggested_row:61-62,68-69 / 77-78; add_friends_page:79; my_friends_page:70 | Row icons, QR |
| sw*0.11 | permissions:283-284 | Back icon |
| sh*0.16 | permissions:227 | Header |
| sh*0.06 / sh*0.05, sw*0.73 / sw*0.5 | add_friend_profile_action_button:41-42,59-60,79,90 | Bottom buttons |
| sh*0.7 | choose:55; selection:56 | Sheet height |
| sh*0.32 | add_friend_profile_page:68 | bgHeight |
| sw-32 | profile_page_header:42; add_friends_button:30; my_capsules_panel:26,72; my_friends_panel:38,60,113; your_friend:46,114 | Content width (9) |
| sw-95 | my_friends_panel:89 | |

### 3.7 Icon and indicator sizes
- DefaultIconButton: **44**: profile_page_header_action_buttons:20 (notifications) and friend_profile_action_buttons_row:28,36,43 (back, share, menu), 4 uses. **41**: profile_page_header_action_buttons:43,59 (share, settings), 2 uses. Share is 41 on your own profile and 44 on a friend's profile, which is inconsistent.
- UnreadNotificationBadge size 18 at right 2, top 2 (profile_page_header_action_buttons:35-37).
- Material `Icon` size 20 (friend_options_modal:514) and size 50 (add_friend_profile_background_image:69).
- CircularProgressIndicator 16x16 with stroke 2 (friend_options_modal:502-506, 581-585); 20x20 with stroke 2 (main_button:48-52); `WhiteCircularProgressIndicator(size:16)` (request_handle_button:38); default size (contacts:180, permissions:294).

### 3.8 Durations / animation
| Value | Where | Count |
|---|---|---|
| **PageTransition fade 10ms / reverse 10ms** | add_friends_action_buttons_row:28-29,49-50; suggested_friends_list:130-131; received_list:74-75; sent_list:68-69; grouped_list:54-55; profile_page_header_action_buttons:27-28,50-51,66-67; profile_page_my_friends_panel:97-98; add_friend_profile_page:47-48 (+ pinned_friends_controller:126-127) | 11 (+1) |
| PageTransition bottomToTop 100ms / 100ms | profile_page_add_friends_button:22-24 | 1 |
| Popup durations 2s (success) / 3s (error) | profile_background_picture:66,75; profile_picture:79,88 | 4 |
| Future.delayed 300ms | choose:112; selection:113 | 2 |
| Modal option press feedback | `NoSplash.splashFactory` + `overlayColor: transparent` in friend_options_modal (456-457, 496-497, 576-577, 610-611). Default ink splash in pinned_friend_option_tile, profile_picture and profile_background_picture option buttons | Visual inconsistency |

---

## 4. Duplicated / near-duplicate components to merge

1. **Options modal ("action sheet card").**
   - Copies: `friend_options_modal.dart` (`_ModalContainer` 264/r25/white, `_ModalHeader` 37h/25 bold, `_ModalOption` 264x37/17 bold, `_ModalDivider` 2px #D3D3D3), the inline modals in `profile_picture.dart:97-199` and `profile_background_picture.dart:92-212` (264x153, 25 bold **green** title, **1px green** header divider, 2px #D3D3D3 dividers, 17 bold options, delete option in #FDFD4140), `pinned_friend_option_tile.dart` (same 264x37/17 bold, but with default splash) together with `pinned_friend_options_dialog.dart` (250w, whiteCard shadow, 22 bold green title, 1px black45/D3D3D3 dividers).
   - Differences: title colour (black vs green), header-divider colour and thickness (black 1 / green 1 / black45 1), option-divider thickness (2 vs 1), container width (264 vs 250), shadow (none vs whiteCard), splash (none vs default), bottom-corner shaping of the last option (only profile_picture and `_ModalOption.isLast`), and the fixed 153 height.
   - The sheet wrapper (`showModalBottomSheet(backgroundColor: transparent, isScrollControlled: true, barrierColor: black.withAlpha(128))` + `GestureDetector(opaque, pop)` + `Center` + `GestureDetector(onTap:(){})`) is copied 5 times: friend_options_modal:13-30, 84-101, 247-264; profile_picture:100-108; profile_background_picture:95-105. pinned_friends_row:48-63 and pinned_friends_controller:105-118 are variants. Make it one `showCenteredSheet(child)` helper.

2. **Image picker tiles.** `ProfilePicture` and `ProfileBackgroundPicture` are about 80% identical: state, load, pick (gallery and camera), save, delete, the modal, and the loader overlay. Differences: the AssetImageService method pair, the default size (150x150 r25 all corners vs 200 x inf r25 bottom), the empty colour (#DFDFDF vs #BBBBBB), the empty icon (`choose_pp.png` centred vs `choose_bg.png` at top 80), the loader alignment and padding, the 'Inria' caption style, the titles and labels ("Delete profile icon" vs "Delete background picture"), and the last-option shape. Merge into one `EditableImageTile(kind: profile|background)` driven by a controller.

3. **`ChoosePinnedFriendsDialog` vs `PinnedFriendsSelectionDialog`.** These are identical code (choose_pinned_friends_dialog.dart and pinned_friends_selection_dialog.dart). Delete the unused one.

4. **Friend-request rows.** `FriendRequestsReceivedRow` and `FriendRequestsSentRow` have the same card (whiteCard, margin-bottom 12, padding 16, avatar sw*0.07, gap 12, name sw*0.045 bold, username sw*0.035 grey600). Differences: the received row wraps the name in a FittedBox with maxLines 2 and has two action buttons (Accept green / Reject #FD4140) with sw*0.02 and sw*0.01 gaps; the sent row has one button (Cancel #FD4140). Make one `UserCardRow(actions: [...])`. `FriendRequestsReceivedList` and `FriendRequestsSentList` are also near-identical (Consumer, empty state, ListView padding 15, FutureBuilder getUserData, push AddFriendProfilePage). Differences: the source set, the empty texts, and the callbacks.

5. **User list row.** `SuggestedFriendRow` (ListTile, name sw*0.045 bold black, username sw*0.04 #5E5E5E), the request rows above, the `ListTile`s in the pinned dialogs (radius 24, 18 bold / 14 grey), the contacts tile (CircleAvatar 25, 18 w500 / 14 grey600), and `UserListTile` (used in grouped list). All are avatar, name, @username and trailing. Each has slightly different sizes and colours, so the token decision is needed.

6. **Destructive and confirm buttons.**
   - `AddProfileMainButton` and `AddProfileRequestHandleButton` are both ElevatedButton + roundedButtonStyle(r25, elev 0) + shadow (black12, blur 16, spread 1, (0,6)) + bold white DefaultText + spinner. They differ only in the spinner (20px raw vs WhiteCircularProgressIndicator 16) and in the shadow (inline vs `softBlackShadow()`).
   - `FriendRequestsActionButton` (pill r25, sw*0.03/sh*0.01 padding, 14 bold white) and `_ConfirmButton` (140x45 r25, 16 bold) are pill-button variants too.
   - `DefaultGreenButton` is used for Save in the pinned dialogs and the settings pages.

7. **Profile headers (3 variants).**
   - `ProfilePageHeader` (own): ProfileBackgroundPicture 230, 1px blackShadow bar, buttons at top 35/right 12, ProfilePicture 115 at top 99/left 16, name 32/20 white bold.
   - `YourFriendProfilePage` header: ProfileHeaderBackground 230, ShadowTopOverlay, ProfileActionButtonsRow top 32, UserSquareAvatar 115 r25 at top sh*0.108/left sw*0.04, name sw*0.07/sw*0.05 white.
   - `AddFriendProfileHeader`: UserRoundedBackgroundImage sh*0.32, ShadowTopOverlay, ProfileActionButtonsRow, round avatar radius 100 with elevation 8, name below in black 32/22 #5E5E5E (UserNameAndUsername defaults).
   - These can share one header with layout variants, but the differing offsets must be preserved.
   - `ProfileHeaderBackground` (unused-ish variant), `AddFriendProfileBackgroundImage` (unused) and `UserRoundedBackgroundImage` are all "background with bottom radius 25".

8. **Settings stub pages.** Five identical files (app_theme, email, language, password, profile_customization). Make one `ComingSoonPage(message)`.

9. **Page headers.** `PermissionsSettingsPage` re-implements `PageHeader` by hand (white, bottom r25, sh*0.16, title sw*0.095 bold, 14 bold #5E5E5E subtitle, go_back.png sw*0.11 at bottom 39 / left 8). Replace it with `PageHeader(mainText, description, leadingButton)` as in name and username settings.

10. **Card panels on the profile.** `ProfilePageAddFriendsButton` (whiteCard, 45h, 18+40+18 icon row at top 3, 16 normal text) and the bottom row of `ProfilePageMyFriendsPanel` (45h, 18+40+5 icon row at bottom 3, DefaultTextButton) are the same "icon + label card row". `ProfilePageMyCapsulesPanel` uses the same icon (40, left 20) plus a split-row pattern. Make one `ProfileCardRow`.

11. **Dividers.** `ProfilePageDivider` (1px #D3D3D3 default), `_ModalDivider` (2px #D3D3D3 default), and the inline `Container(width:264,height:1|2,color:…)` in profile_picture and profile_background_picture all express the same divider. Merge them into one `AppDivider(thickness, color)`.

12. **Empty and loading placeholders.** `const Center()` / `SizedBox(height:80, child: Center())` is used as an invisible loader in received_list:49, sent_list:47, pinned_friends_row:17,36, suggested_friends_list:62, my_friends_page:80. Make one `LoadingPlaceholder`.

13. **Toggle button vs action pill.** `FriendRequestsToggleButton` (35h, r20, 2px green border, selected green fill) is the only segmented control. Keep it as a shared `SegmentedPill`, but stop returning `Expanded` from it.

---

## 5. Asset paths referenced (all verified to exist on disk)

| Path | file:line |
|---|---|
| assets/images/icons/prof_page/share_button_black.png | widgets/friends/add_friends_page/add_friends_action_buttons_row.dart:34 |
| assets/images/icons/friends_page/friend_request.png | widgets/friends/add_friends_page/add_friends_action_buttons_row.dart:56 |
| assets/images/icons/friends_page/pending.png | widgets/friends/add_friends_page/suggested_friend_row.dart:60 |
| assets/images/icons/prof_page/add_friend.png | widgets/friends/add_friends_page/suggested_friend_row.dart:67; widgets/friends/contacts_list.dart:152; widgets/my_profile_page/profile_page_add_friends_button.dart:46 |
| assets/images/icons/friends_page/delete_reset.png | widgets/friends/add_friends_page/suggested_friend_row.dart:76 |
| assets/images/icons/prof_page/friend_search.png | widgets/friends/contacts_list.dart:192; pages/friends_pages/my_friends_page.dart:91 |
| assets/images/icons/friends_page/friend_request_page.png | widgets/friends/friend_requests_page/friend_requests_received_list.dart:35; friend_requests_sent_list.dart:34 |
| assets/images/icons/prof_page/choose_bg.png | widgets/my_profile_page/profile_background_picture.dart:259 |
| assets/images/icons/prof_page/choose_pp.png | widgets/my_profile_page/profile_picture.dart:228 |
| assets/images/icons/prof_page/notifications_button.png | widgets/my_profile_page/profile_page_header_action_buttons.dart:21 |
| assets/images/icons/prof_page/share_button.png | widgets/my_profile_page/profile_page_header_action_buttons.dart:44; widgets/add_friend_profile/friend_profile_action_buttons_row.dart:35 |
| assets/images/icons/prof_page/settings_button.png | widgets/my_profile_page/profile_page_header_action_buttons.dart:60 |
| assets/images/icons/prof_page/my_capsules.png | widgets/my_profile_page/profile_page_my_capsules_panel.dart:41 (as `AssetImage` in DecorationImage) |
| assets/images/icons/prof_page/my_friends.png | widgets/my_profile_page/profile_page_my_friends_panel.dart:83 |
| assets/images/icons/prof_page/go_back_circle.png | widgets/add_friend_profile/friend_profile_action_buttons_row.dart:27 |
| assets/images/icons/prof_page/open_menu.png | widgets/add_friend_profile/friend_profile_action_buttons_row.dart:42 |
| assets/images/icons/friends_page/qr_scan.png | pages/friends_pages/add_friends_page.dart:78; pages/friends_pages/my_friends_page.dart:69 |
| assets/images/icons/prof_page/send_message.png | pages/friends_pages/your_friend_profile_page.dart:87 |
| assets/images/icons/prof_page/send_capsule.png | pages/friends_pages/your_friend_profile_page.dart:99 |
| assets/images/icons/camera/Camerafull.png | pages/settings_pages/permissions_settings_page.dart:24 |
| assets/images/icons/capsule_creation/microphone_icon.png | pages/settings_pages/permissions_settings_page.dart:30 |
| assets/images/icons/capsule_creation/location_icon.png | pages/settings_pages/permissions_settings_page.dart:38 |
| assets/images/icons/prof_page/notifications_button_black_full.png | pages/settings_pages/permissions_settings_page.dart:44 |
| assets/images/icons/friends_page/friend_book.png | pages/settings_pages/permissions_settings_page.dart:50 |
| assets/images/icons/prof_page/go_back.png | pages/settings_pages/permissions_settings_page.dart:282 |

There are 25 distinct paths. Most repeated: `add_friend.png` (3), `share_button.png` (2), `friend_search.png` (2), `friend_request_page.png` (2), `qr_scan.png` (2). `UserProfileImage`'s `ProfilePlaceholderType.pinnedFriend` placeholder asset lives outside scope.
