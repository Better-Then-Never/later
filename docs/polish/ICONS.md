# ICONS.md — icon inventory

**Family:** hand-drawn PNG artwork with thick black strokes, some filled with the brand colours (navbar, profile
cards, map pins). Raster images at large sizes (displayed at 5–9% of the screen width); they are not an icon font
and not SVG, so new icons must be PNGs drawn in the same hand. Every file under `assets/icons/` is reachable only
through `AppIcons` (`lib/core/assets/app_assets.dart`), and `test/core/app_assets_test.dart` fails if a file is
missing or unreferenced.

**Colour:** icons are artwork, not tinted; dark icons sit on light surfaces, the `*White`/`cameraBack` variants on
photos and the camera. Material icons appear only where the original design used them (allow-list in
`tool/design_tokens_allowlist.txt`).

## Custom icons
| Accessor | File (`assets/icons/`) | Used in |
|---|---|---|
| `authGoogle` | `auth/google.png` | auth/widgets/social_login_buttons |
| `authFacebook` | `auth/facebook.png` | auth/widgets/social_login_buttons |
| `authPasswordHidden` | `auth/password_hidden.png` | auth/widgets/auth_text_field |
| `authPasswordShown` | `auth/password_shown.png` | auth/widgets/auth_text_field |
| `cameraShutter` | `camera/shutter.png` | capsules/camera/camera_page |
| `cameraSwitch` | `camera/switch_camera.png` | capsules/camera/camera_page |
| `cameraFull` | `camera/camera_full.png` | auth/permission_gate_page, settings/pages/permissions_settings_page |
| `cameraFlashOff` | `camera/flash_off.png` | capsules/camera/camera_page |
| `cameraFlashOn` | `camera/flash_on.png` | capsules/camera/camera_page |
| `cameraBack` | `camera/back_white.png` | capsules/camera/camera_page |
| `capsuleClose` | `capsule/close.png` | capsules/creation/capsule_creation_page |
| `capsuleLocation` | `capsule/location.png` | auth/permission_gate_page, capsules/creation/capsule_creation_page, history/widgets/capsule_list_tile, map/widgets/capsule_preview_card, settings/pages/permissions_settings_page |
| `capsuleMicrophone` | `capsule/microphone.png` | auth/permission_gate_page, settings/pages/permissions_settings_page |
| `capsulePinColor` | `capsule/pin_color.png` | capsules/creation/capsule_creation_page |
| `capsulePrivacy` | `capsule/privacy.png` | capsules/creation/capsule_creation_page, history/widgets/capsule_list_tile |
| `capsuleTimer` | `capsule/timer.png` | capsules/creation/capsule_creation_page, history/widgets/capsule_list_tile |
| `friendsDeleteReset` | `friends/delete_reset.png` | friends/widgets/add_friends/suggested_friend_row |
| `friendsBook` | `friends/friend_book.png` | auth/permission_gate_page, settings/pages/permissions_settings_page |
| `friendsRequest` | `friends/friend_request.png` | friends/widgets/add_friends/add_friends_action_buttons_row |
| `friendsRequestPage` | `friends/friend_request_page.png` | friends/pages/friend_requests_page |
| `friendsLookFor` | `friends/look_for.png` | shared/widgets/default_search_bar |
| `friendsPending` | `friends/pending.png` | friends/widgets/add_friends/suggested_friend_row |
| `friendsQrScan` | `friends/qr_scan.png` | friends/pages/add_friends_page, friends/pages/my_friends_page |
| `historyFilter` | `history/filter.png` | history/history_page |
| `historySort` | `history/sort.png` | history/history_page |
| `mapPinUser` | `map/pin_user.png` | map/marker_icons |
| `messagesNew` | `messages/new_message.png` | messages/widgets/messages_header |
| `messagesChatMenu` | `messages/chat_menu.png` | messages/chat_page |
| `messagesSend` | `messages/send.png` | messages/widgets/message_input |
| `navbarAdd` | `navbar/add.png` | app/shell/navbar_widget |
| `navbarHistory` | `navbar/history.png` | app/shell/navbar_widget |
| `navbarMap` | `navbar/map.png` | app/shell/navbar_widget |
| `navbarMessages` | `navbar/messages.png` | app/shell/navbar_widget |
| `navbarProfile` | `navbar/profile.png` | app/shell/navbar_widget |
| `profileAddFriend` | `profile/add_friend.png` | friends/widgets/add_friends/suggested_friend_row, profile/widgets/profile_page_add_friends_button |
| `profileBackgroundPlaceholder` | `profile/background_placeholder.png` | shared/widgets/user/user_background_image |
| `profileChooseBackground` | `profile/choose_background.png` | profile/widgets/profile_background_picture |
| `profileChoosePhoto` | `profile/choose_photo.png` | profile/widgets/profile_picture |
| `profileFriendSearch` | `profile/friend_search.png` | friends/pages/my_friends_page |
| `profileMyCapsules` | `profile/my_capsules.png` | profile/widgets/profile_page_my_capsules_panel |
| `profileMyFriends` | `profile/my_friends.png` | profile/widgets/profile_page_my_friends_panel |
| `profileNoPhoto` | `profile/no_photo.png` | notifications/widgets/notification_avatar, shared/widgets/user/user_profile_image |
| `goBack` | `profile/go_back.png` | capsules/creation/capsule_creation_page, messages/chat_page, settings/pages/permissions_settings_page, shared/widgets/buttons/go_back_button |
| `goBackCircle` | `profile/go_back_circle.png` | friends/widgets/profile/friend_profile_action_buttons_row |
| `goBackWhite` | `profile/go_back_white.png` | shared/widgets/buttons/go_back_button |
| `goHere` | `profile/go_here.png` | shared/widgets/options/options_settings_row |
| `notifications` | `profile/notifications.png` | profile/widgets/profile_page_header_action_buttons |
| `notificationsBlack` | `profile/notifications_black.png` | notifications/widgets/notifications_list |
| `notificationsBlackFull` | `profile/notifications_black_full.png` | auth/permission_gate_page, settings/pages/permissions_settings_page |
| `openMenu` | `profile/open_menu.png` | friends/widgets/profile/friend_profile_action_buttons_row |
| `reply` | `profile/reply.png` | notifications/widgets/notifications_list |
| `sendCapsule` | `profile/send_capsule.png` | friends/pages/your_friend_profile_page |
| `sendMessage` | `profile/send_message.png` | friends/pages/your_friend_profile_page, notifications/widgets/notifications_list |
| `settings` | `profile/settings.png` | profile/widgets/profile_page_header_action_buttons |
| `share` | `profile/share.png` | friends/widgets/profile/friend_profile_action_buttons_row, profile/widgets/profile_page_header_action_buttons |
| `shareBlack` | `profile/share_black.png` | friends/widgets/add_friends/add_friends_action_buttons_row |
| `capsulePin(colour)` | `capsule/pin_<colour>.png (6 colours)` | capsules/creation/capsule_creation_page, history/widgets/capsule_list_tile |
| `mapPin(colour)` | `map/pin_<colour>.png (6 colours)` | map/marker_icons |

## Material icons kept from the original design
QR scanner flash on/off; follow bell (filled/outline) in "Manage friendship"; history favourite heart, locked-capsule
badge, selection bar close/delete and filter-menu back/chevron; notification selection bar (mark read, delete,
close) and thumbnail placeholder; share-profile share/copy/info; toast icons (success, error, info); capsule photo
error placeholder.

## New / replaced icons
(Filled in as the messages and settings work lands.)
