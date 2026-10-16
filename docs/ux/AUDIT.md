# AUDIT.md: findings at the start of the mission

Baseline: commit 9cb4be8 (= polish branch + CI fix). Every Appendix A finding is listed with what the code does
today, the root cause, and the planned fix. Status is tracked in REPORT.md. File references are `path:line`.

## Loading and caching
**F-01 Photos reload on every navigation.** Images come from `Image.network` in seven widgets
(`shared/widgets/app_network_image.dart:25`, `shared/widgets/user/user_profile_image.dart:28`,
`user_background_image.dart:22`, `history/widgets/capsule_list_tile.dart:253`,
`notifications/widgets/notification_thumbnail.dart:23`, `notification_avatar.dart:35`,
`profile/widgets/edit_profile_image.dart:20`). Memory cache only; the same URL is decoded under different
`ResizeImage` keys (map card, history and chat use different `cacheWidth`, chat hard-codes ×3), and every miss is a
new download (`dart:io` has no HTTP cache). Avatars switch between the 256 px and 1024 px files by size, so a person
is downloaded twice. Full-size decodes (1024², 1600×900) fill the 100 MB cache and evict. Avatars and backgrounds
show nothing while loading. **Fix:** one cached image widget with a disk cache, decode sizes bucketed from layout
size × DPR, thumbnails for small sizes, shaped placeholders.

**F-02 Everything reloads after a restart.** No disk cache (`cached_network_image` / `flutter_cache_manager`
absent); avatar URLs come from `getDownloadURL` again every session (`data/services/profile_image_cache.dart`,
in-memory, wiped on attach), up to two sequential calls per avatar. Capsule `imageUrl` is stored and stable.
**Fix:** persistent cache keyed by storage path + version (not the token URL); keep resolved avatar URLs across
sessions.

**F-03 Chat photos vanish when re-entering a chat.** Every `ChatPage` builds a new `ChatController` starting at
`_loaded = false` (`chat_controller.dart:41`); `_body` swaps the list for a spinner (`chat_page.dart:222`), then
rebuilds every bubble; images not in memory download again. **Fix:** keep each chat's last messages in
`ChatsStore` and start from them; disk cache.

## Map
**F-10 Map stutters.** google_maps_flutter 2.18 (Android TLHC, default), kept alive in an `IndexedStack`.
Markers are a new `Set<Marker>` on every build (`map_page.dart:133`); `visibleCapsules` recomputed three times per
update; every position update (10 m filter) and every snapshot of three streams rebuilds the whole `GoogleMap`
(`map_controller.dart:126`); crossing zoom 12 adds/removes all markers in one frame; the heatmap is rebuilt each
time; the info-window package does a platform call and `setState` per camera frame. Queries: all own capsules, all
friends' capsules, public capsules in a ±2° latitude band (limit 300), nothing viewport-bounded.
**Fix:** position out of the map rebuild, memoized markers, clustering, viewport-bounded queries, own popup.

**F-11 Compass top-left under the status bar.** No `padding` on `GoogleMap`. **Fix:** top padding = status bar.
**F-12 Zoom buttons behind the nav pill.** Native zoom controls bottom-right, no padding. **Fix:** own control
cluster above the pill (or bottom padding).
**F-13 No my-location button.** `myLocationEnabled` never set; a custom marker shows the user. **Fix:** own
recenter button that animates the camera.
**F-14 Google logo hidden.** Same missing padding; terms require it visible. **Fix:** padding, never removal.
**F-15 Map green duller than the brand.** Cloud styling via `mapId` (`map_page.dart:55`); a JSON `style` is ignored
while a mapId is set. **Fix:** a JSON style (light + dark) with brand greens; drop the mapId (or keep it only
for satellite).
**F-16 Heatmap.** Native heatmap, weight 1, fixed 50 px radius, `Colors.green/yellow/red`, drawn at every zoom,
over markers. **Fix:** see DECISIONS.md (density clusters in brand colours).
**F-17 Popup cannot be dismissed.** `custom_info_window` re-shows the window after an `await` even if it was
hidden meanwhile (`custom_info_window.dart:78`); no close button; survives back, tab switch and zoom-out.
**Fix:** drop the package; own animated card dismissible by map tap, swipe down, X, back and tab change.
**F-18 Capsules in strange places.** The code never writes 0,0, but nothing rejects it: rules only check
`location is latlng` (`firestore.rules:308`), the mapper accepts any GeoPoint, the map filters only missing ones.
Likely legacy documents or devices that report 0/0 before a fix. **Fix:** validate in controller and rules
(reject ~0,0 and out of range, check fix age/accuracy), hide invalid points, allow manual pin.

## Camera and creation
**F-20/F-21 No zoom, focus, exposure.** `camera_page.dart`: preset `high`, flash only always/off, front/back,
lifecycle handled; no zoom, tap-to-focus, exposure, grid. Preview is a plain `Column` (bars or overflow).
**F-22 Shutter delay.** `takePicture` (`:149`) then `pushReplacement`; compression happens later in an isolate.
The delay is the plugin's still capture at preset `high` plus the route build. **Fix:** instant feedback (haptic,
shutter flash, frozen frame), measure tap-to-file, lighter preset where acceptable.
**F-23 Flash.** Works (always/off); no auto or torch. **Fix:** off/auto/on/torch, verify.
**F-24 Location takes long.** The yellow pill shows "No location" while waiting for an 8 s high-accuracy fix,
"Loading..." during geocoding, "Unknown location" on failure; no manual choice. **Fix:** last known position first,
refine in background, cached reverse geocoding, mini-map pin.
**F-25/F-29 Creation UI and settings.** One page: photo, title (30 chars), description (2200 chars), cycling
pills for privacy, open date, colour. Back reopens the camera and loses the photo; keyboard covers the button
(`resizeToAvoidBottomInset: false`). **Bug:** the description allows 2200 characters but the rules allow 2000:
2001–2200 fail to save with permission-denied. **Fix:** step flow, composer, settings (visibility, author shown,
comments, reactions, co-authors, location precision).
**F-26 No offline creation.** No connectivity check; the upload retries up to 10 min while spinning; no outbox; the
photo is lost on leaving. **Fix:** local outbox with background upload and idempotent ids.
**F-27 Stock date picker.** `showDatePicker` (`capsule_creation_page.dart:73`). **Fix:** own calendar.
**F-28 Dated inputs.** Hint "Add Title... " with a trailing space; plain fields. **Fix:** modern composer.

## Design
**F-30 Messages:** avatars squashed because `ListTile` caps the leading widget at 56 dp tall while the avatar is
0.14·w wide (ellipse on screens wider than 400 dp: `chat_list_item.dart:50`, `user_list_tile.dart:28`,
`suggested_friend_row.dart:45`). `messages/new_message.png` is 36×36 px drawn at ~45 dp (blurry);
`navbar/messages.png` is 403×352 drawn into a 46 dp square.
**F-31 History controls:** Sort/Filter/Reset are 5 % of the screen tall with 32 px icons; Reset reuses the sort icon;
"Find Capsules..." uses 22 pt text; the Sort/Filter dialogs (`NestedMenu`) have another radius and a 14 pt title.
**F-32/F-37 Sheets and dialogs:** six different implementations (centred sheet 264 wide, confirm dialog, image
options with fixed 153 dp height, new-chat bottom sheet, pinned friends dialogs, password reset, transparent
`Dialog` for capsule previews, stock `AlertDialog`s, stock date and time pickers); no grab handles; titles 16–25 pt.
**F-33 Headers and status bar:** `PageHeader` title 4 % of height, top padding 4 % of height instead of the real
status bar; no `SystemUiOverlayStyle` anywhere, no edge-to-edge setup (enforced on Android 15).
**F-34 Nav pill:** 80 dp tall, icons 46 dp (55 selected), add 69 dp; no accessibility labels.
**F-35 My capsules jitter:** fixed header (about 25 % of the screen) + `ListView.builder`, default physics, no
reserved image sizes.
**F-36 Too big:** see F-31/F-33/F-34; no UI-size setting.
**F-38 Add friends transition:** a 150 ms slide (about 9 frames) while a 50-user query fires, a non-lazy list builds
all rows, each avatar calls `getDownloadURL`, and several 270–410 px icons decode for the first time.
**F-39 Friends section:** "You have no friends yet" at 20 pt, no action, blank while loading; no section header; the
profile is a non-scrolling `Column`.
**F-40 Placeholders:** `no_photo.png`, flat greys `#DFDFDF` / `#BBBBBB`, `background_placeholder.png` (flat grey).
**F-41 Requests toggle:** custom 35 dp pills with a green border vs the notifications `TabBar`; the "Comments" tab
overflows at ≤ 360 dp or 1.3× text (and Replies/Comments are always empty: the server never creates them).
**F-42 Permission screens:** five mandatory full pages (camera, microphone, location, notifications, contacts),
titles squeezed by `FittedBox` so sizes differ; microphone and contacts are never used.
**F-43 Share profile:** `Icons.info_outline`; the share icon is the same paper plane as "send".
**F-44/F-45 Consistency and motion:** see above; the notifications tab pill is the motion reference.

## Social
**F-50 Share, reactions, comments:** none (only a private favourite heart); `share_plus` shares profile links only.
**F-51 Co-authors:** none (`ownerId` only). **F-52 Quick reply:** none.
**F-53 Follower counts:** follows exist (`followers`/`following` subcollections) but no counts; rules prevent
counting from the client, so a server counter is needed.
**F-54/F-55 Friend profile:** background, avatar, name, Open chat, Send capsule; "Friend's capsules" is a static
placeholder; two menu items and "Report" do nothing (`friend_options_modal.dart:39,47,154`).
**F-56 Pinned friends:** up to 3, device-only, random friends fill empty slots.
**F-57 People search:** username prefix, limit 50; **with an empty query Add Friends lists the first 50 users of the
app**. **F-58 Verified badge:** none. **F-59 Customize profile:** pictures, name, username only.
**F-60 Author visibility:** the author is never shown on capsules (map popup and preview card are anonymous).

## Chat
**F-70 Opens in the middle:** the current code opens at the newest message (reversed list, `limitToLast(50)`), fixed
in the polish branch; re-entering still shows a spinner first (F-03).
**F-71 Groups:** impossible (chat id = pair of uids; rules require exactly two members).
**F-72 Stickers / F-73 Voice:** none. **F-76 Design:** redesigned in the polish branch; still `text` and `capsule`
messages only (no images, reply, reactions, delete one message).

## Settings
**F-80 Email row "loading":** fixed in the polish branch (email from Auth). **F-81 Password change:** done (polish).
**F-82 Password reset:** exists on login (`password_reset_dialog.dart`); verify end to end. **F-83 Language:** none.
**F-84 Appearance:** none (light only; the polish branch removed a placeholder page). **F-85 Customize profile:**
pictures, name, username. **F-86 Log out / permissions rows:** consistent since polish. **F-87 UI size:** none.
**F-88 Notification settings:** done in polish (server-enforced).

## Gamification
**F-90 Streak, F-91 Achievements, F-92 placeholder icons, F-93 Loop capsule:** none of it exists.

## Also found
- Navbar items have no accessibility labels.
- Strings: about 610 user-visible strings (settings ~220, friends ~75, messages ~65, auth ~55, data layer ~50).
  Push texts are written in `functions/lib/notify.js` (~15 strings), so the server needs localization too.
- Colours: 325 `AppColors` uses outside the theme; seven tokens unused.
- Intl formats are hard-coded English (`dd.MM.yyyy`, `HH:mm`, `EEEE`).
- The emulator cannot measure raster time (about 110 ms per frame with both Impeller and Skia, see PERFORMANCE.md).
