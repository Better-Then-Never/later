# Audit notes (scratch, raw) — branch refactor/architecture-and-stabilization

## Config / platform
- pubspec: flutter_lints declared under `flutter_icons:` (wrong section) -> lints NOT active; analysis_options has empty rules, no include.
- pubspec: flutter_launcher_icons in dependencies (should be dev). `google_maps` (web JS) package unused? `location` + `geolocator` both (dup). `http` usage? `image` usage? `path_provider`? `custom_info_window`? `collection`? check. google_sign_in ^6 (old API). firebase_messaging pinned 16.1.0.
- pubspec assets: duplicate entries (login_signup_pages, prof_page twice).
- firestore.rules in repo: open-all until 2025-09-03 => expired => denies everything if deployed from repo. Deployed prod rules unknown.
- storage.rules in repo: deny all. If deployed, all storage would fail -> prod must differ.
- firestore.indexes.json empty, but query capsules where ownerId== orderBy createdAt desc needs composite index.
- firebase.json flutter section references OLD app IDs (6969e7…/a5d6320…).
- AndroidManifest: Maps API key hard-coded (committed) — SECURITY. Same key in ios AppDelegate.swift. WRITE_EXTERNAL_STORAGE + requestLegacyExternalStorage (obsolete). showWhenLocked/turnScreenOn on activity (odd). No default_notification_icon meta. READ_CONTACTS. No ACCESS_BACKGROUND_LOCATION (fine).
- MainActivity: deep link channel later.app/deeplink; handleIntent in onCreate before engine? configureFlutterEngine runs during super.onCreate so flutterEngine != null at handleIntent -> sendLinkToFlutter invoked before Dart handler set -> cold-start link LOST (initialLink never set). BUG.
- iOS Info.plist: usage strings placeholder-y ("Camera"), NO NSPhotoLibraryUsageDescription (image_picker gallery -> crash), no UIBackgroundModes remote-notification, no push entitlements file, orientations allow landscape while app locks portrait. AppDelegate: no Firebase messaging delegate setup (FlutterFire handles swizzling). Cannot build iOS on Windows -> blocker.
- debug SHA-1 FE:77:7D:3A… not registered on new android app (Google Sign-In).

## Functions (functions/index.js, v2)
- getUserData: public unauthenticated HTTP, returns any user's EMAIL, makes profile image PUBLIC (makePublic) — security. CORS *. debug field in response.
- sendFollowerNotification: triggers on users/{uid}/notifications create, only type=='follow'; single fcmToken field. Invalid token cleanup ok.
- sendCapsuleNotification: capsules/{id} create, reads capsule.creatorId — APP WRITES ownerId -> never runs (BUG). Uses followers/following subcollections w/ notificationsEnabled — check app model (app has friends?). N+1 sequential reads.
- index.js.backup leftover file.
- No region set; package.json no lint.

## main.dart
- push init awaited before runApp, rethrows -> splash freeze (BUG-001). onBackgroundMessage registered after await.
- Providers created all at root; FirebaseAuth.instance.authStateChanges StreamBuilder direct in widget.
- PermissionGatePage onAllGranted -> pushReplacement (inside home StreamBuilder; on sign-out?).
- Deep link: Future.delayed 2s hacks.
- Named routes map + MaterialPageRoute + PageTransition mix.
- Snowfall overlay over entire app (keep - design).
- Theme: seed green, font Irina (InriaSans files - "Irina" family name typo but consistent).

## data
- notifiers.dart global ValueNotifier selectedPageNotifier.
- TimeCapsule model: fromMap throws on unknown privacy (firstWhere w/o orElse), createdAt cast throws if null (serverTimestamp pending). ownerId. Model maybe unused vs Map<String,dynamic> in CapsuleDataService.
- CapsuleDataService: maps not models; fetchCapsulesByOwner cache never invalidated; errors swallowed; subscribeToCapsules notifyListeners inside stream map (rebuild loop risk); color default 'blue' vs model default 'red' inconsistency; deleteCapsules doesn't delete storage images (orphans).
- CacheService static map.
- DeepLinkService: swallow errors; host hardcoded.
- FirebaseAuthService: username uniqueness check via query (race; needs rules allowing unauth query of users!) done BEFORE createUser -> unauthenticated read of users collection required. addUserToDatabase dup. signOut doesn't clean listeners/tokens. Error messages missing 'invalid-credential' (new default for wrong pw) -> generic msg.

## Storage / images
- Paths: userdata/{uid}/assets/images/{profile_image, profile_image_small, background_image}. No content type set on putData. No size limits.
- 3 duplicate URL-cache implementations: CacheService (static), FirebaseStorageService (static), AssetImageService._imageUrlCache, + UserImageService (to read). Negative results cached forever (null) -> after upload, stale null until restart.
- AssetImageService caches profile/background bytes base64 in SharedPreferences under GLOBAL keys 'profile_image'/'background_image' (not per uid) -> after logout/login as other user shows previous user's images (BUG) unless clearLocalCache on logout. Base64 of full image in prefs = huge.
- _resizeImage forces 128x128 ignoring aspect ratio (distorts non-square).
- deleteProfileImage throws if small missing.
- getDownloadURL 404 logged as StorageException noise (seen in logs) for users without images.

## Location / map services
- LocationService uses `location` pkg while elsewhere geolocator? both deps. startLocationUpdates no permission check; dispose closes controller.
- MapMarkerService BitmapDescriptor.asset each call (no cache).
- CapsuleJumpService: clear() doesn't notify (ok), Map<String,dynamic>.

## PopupNotificationService: static overlay; OK-ish, uses global state. Colors hardcoded (design tokens: success 86,201,46; error 255,87,87; info 33,150,243; default grey800).

## Push (push_notification_service.dart)
- Singleton ChangeNotifier also provided via provider.
- initialize() at app start BEFORE auth known; token saved only if a user already signed-in at cold start. No auth-state listener -> after login/signup the token is never saved until next cold start; after logout token stays on old user doc (pushes for user A delivered to device now used by B). BUG.
- Notifications list loaded only at init (cold start) -> after login list empty until restart. BUG.
- rethrow -> startup freeze (BUG-001).
- requestPermission at startup before login (also PermissionGate requests?).
- onMessage foreground: _saveNotificationToFirestore ADDs a NEW notification doc (duplicate of server-created one). For type 'follow' that new doc re-triggers sendFollowerNotification -> another push -> loop while app in foreground (BUG, severe). onMessageOpenedApp + getInitialMessage also add duplicates.
- Android small icon '@mipmap/ic_launcher' (full-color -> white square on status bar). No default_notification_icon meta.
- Tap handler TODO (no routing). payload = data.toString() (unparseable).
- markAsRead/deleteNotification by list index (fragile w/ filters). unreadCount from local list.
- markAllAsRead/clearAll batch unbounded (>500 docs fails).
- print everywhere; prints FCM token (secret-ish).
- background handler: no-op; fine but must be registered before runApp (it is after await init).
- notification title computed from type, stored title ignored.

## User services
- users/{uid} fields seen: uid,email,name,username,createdAt, friends[]?(UserDataService.getUserFriends reads array 'friends'), favorites[] (capsule ids), fcmToken, fcmTokenUpdatedAt.
- UserDataService: caches Map<String,String>; fallbacks 'Unknown'/'unknown@example.com' cached forever on error; name getter 'Loading...'. getCurrentUserProfile sets _currentUid then early return if _isFetched (switch user w/o logout -> stale). updateUsername: NO uniqueness check, NO lowercase normalization (signup normalizes) -> duplicates/case mismatch (BUG). 
- FavoriteCapsuleService: optimistic update w/o rollback on failure; update() fails if doc missing.
- UserImageService: ValueNotifier per user; reads only profile_image (full-size!) not small for lists -> heavy; negative cached forever: after user uploads avatar, others/self not refreshed unless invalidated; onLogout disposes notifiers still listened by mounted widgets -> "used after disposed" errors; preload* inverted condition (precache only when NOT NetworkImage). duplicate `userHasAvatar[userId] = false`.
- SharingService: link https://later-da778.web.app/?userId= ; fetches user data just to get name.

## UserFriendsService
- Data: friend_requests/{from}_{to} {fromUserId,toUserId,status:'pending'|'accepted',createdAt,acceptedAt}; users.friends array; users/{uid}/following/{target} {followedAt, notificationsEnabled}; users/{uid}/followers/{follower} {followedAt}; users/{uid}/notifications/{auto} {type,fromUserId,fromUserName,fromUserAvatar,message,timestamp,isRead, title?, thumbnailImage?, capsuleId?}
- init() in constructor reads currentUser at provider creation; if created while signed out OR user changes -> listeners never (re)attached -> friend requests/friends stale until app restart (BUG). onLogout doesn't cancel _friendsSub; dispose doesn't cancel _friendsSub (leak).
- acceptFriendRequest writes OTHER user's doc (friends arrayUnion) -> needs rules permitting cross-user writes (security); local state adds fromUserId even if current user is fromUser? (accept always by receiver, ok).
- accepted requests docs remain with status 'accepted'; sendFriendRequest .set overwrites an 'accepted' doc? if re-adding after removal removeFriend deletes both docs ok.
- reverse pending request: if B already sent to A, A sending to B creates second doc; no auto-accept. requestExists check.
- getSuggestedFriends: UNBOUNDED snapshot listener on entire users collection (documentId != uid), client filters friends; with search: username range + documentId != (two inequality fields -> needs index/ may fail). Exposes all user docs incl email & fcmToken to every user (security/privacy). Search is case-sensitive prefix on normalized lowercase username (ok if query lowercased?). Re-subscribes on each search change?
- follow system: followUser/unfollowUser/isFollowing (subcollections) + _sendFollowerNotification creates notification ONLY if target has fcmToken (in-app list should not depend on token) and uses nonexistent 'profilePicture' field -> stores asset path string 'assets/images/...' as avatar in Firestore. Notification uses username as name.
- print usage.

## Controllers
- capsules/{id}: {ownerId,imageUrl,description?,title,location GeoPoint,privacy 'private|friends|public',createdAt Timestamp (CLIENT Timestamp.now()),isScheduled (always true),openAt Timestamp?, color name}. Storage: userdata/{uid}/capsules/{capsuleId}/image.jpg (putFile full-size, no compression, no contentType).
- CapsuleCreationPageController: uses static MapPage.currentPositionStatic (global mutable static on a widget); error message shows raw exception "$e" to user; double-tap protection? isSaving flag but check button; Storage upload not cleaned on Firestore failure; openAt null allowed though isScheduled=true; default privacy public.
- AddFriendProfileController: stringly-typed buttonState; requestId with '$userId\_$currentUserUid' (escaped underscore -> literal "\_"? In Dart '\_' is just '_' ... fine). currentLoggedInUid returns 'No User' fallback -> writes with 'No User' id if profile not fetched (BUG risk). context used after await w/o mounted check.
- MyFriendsPageController: _preloadFriendsData on every service notify (sequential N reads; concurrent runs race); groupedFilteredFriends friend['name'][0] crashes on empty name (RangeError) BUG.
- FriendRequestsPageController: fine-ish; context after await.
- HistoryPageController: maps; sort by createdAt Timestamp compareTo ok; distance uses MapPage.currentPositionStatic.
- NotificationsPageController selection ids.
- SuggestedFriendsListController: holds BuildContext; listener on notifier never removed if image never arrives.
- PinnedFriendsController: pinned uids in SharedPreferences GLOBAL key 'pinned_friend_uids' (not per user) -> leaks across accounts; sequential reads; prints; getDisplayFriends shuffles every call -> random friends each rebuild?; showChoosePinnedFriendsDialog pops then uses context (possibly deactivated).

## Auth pages
- LoginPage Stateless: TextEditingControllers created in build (never disposed; text lost if rebuilt). Forgot password calls FirebaseAuth directly in widget. Hardcoded colors F6F6F6 bg, 56C92E green, width 325 fixed.
- Login->Signup pushReplacementNamed; Signup->Login push (stack grows). Welcome->Login push via PageTransition fade 10ms (effectively instant).
- SignupPage controllers never disposed. "Nickname" = username.
- PermissionGatePage: requires ALL 5 (camera, mic, location, notifications, contacts) granted, else user is stuck forever (hard gate). Product decision -> preserve, but log as BUG/IDEA? (Play policy risk). onAllGranted -> pushReplacement replaces the auth StreamBuilder home with WidgetTreeWrapper => app no longer reacts to auth state (logout must navigate manually).
- Welcome uses Transform.translate offsets for layout (design, keep). global `pages` list unused.
- SubmitButton: after login/signup pushReplacement(PermissionGate) on navigatorKey replacing LoginPage route; meanwhile home StreamBuilder ALSO switches to PermissionGate => two gates stacked (Welcome? no: home is the StreamBuilder) -> stack: [home(PermissionGate#1), PermissionGate#2]. Duplicate permission checks/navigation. After signup via Signup->Login? etc. Error text shows "Exception: ..." raw. Validation only empty fields.
- Google sign-in (login_with_social.dart): Firebase/Firestore calls in widget; username from email prefix -> if taken, addUserToDatabase throws AFTER Firebase sign-in => signed-in user with NO users doc (BUG). Facebook button no-op (TODO) - keep as is (no new features). google_sign_in v6 API. Errors e.toString() snackbar.
- LogOutButton: signs out then clearLocalCache; does NOT call services' onLogout (UserDataService, Friends, Capsules, Favorites, UserImageService) -> previous user's data visible after re-login (BUG) — check settings page onSignedOut. setState in finally w/o mounted check (setState after dispose BUG when navigating away). Text style `/* ... */` empty.
- RegistrationInputField width 325 fixed, hint dynamic. Shown/Hidden icons swapped semantics? isObscured -> "Shown.png" (shows eye to reveal) fine.
- PasswordResetDialog: uses showModalBottomSheet with Center (custom dialog). After pop uses context (deactivated) for ScaffoldMessenger -> may throw. 

## Core pages
- NotificationsPage tabs: All / Replies / Comments (check list filter vs types follow/capsule). markAsRead loop sequential per id; message uses selectedCount after loop (ok since not cleared yet).
- QRScannerPage: MobileScannerController; _isScanning flag not setState; invalid QR snackbar; delayed re-enable. Torch state local may desync. Fine.
- SettingsPage: logout = FirebaseAuthService().signOut() (new instance, NOT awaited) then clears caches; does not clear CapsuleDataService/Push/Pinned; then pushAndRemoveUntil(LoginPage). Logout flow lands on LoginPage (keep). context.watch of 4 services -> rebuild storms. Email/Password/Language/Appearance/Customize pages are 32-line stubs (check). 'MY ACCOUNT' header.
- ShareProfilePage: userId from UserDataService.currentLoggedInUid ('No User' fallback -> QR encodes 'No User').
- WidgetTree: global `pages` list; IndexedStack keeps all 4 pages alive (Map always alive; camera?). selectedPageNotifier global.
- WidgetTreeWrapper.initState: loads favorites, profile, friends init with currentUser! (crash if null), preload images.

## Navbar pages
### Camera (camera_page.dart)
- No WidgetsBindingObserver lifecycle handling (camera not released on background/resume -> black preview / CameraException after resume).
- availableCameras() empty -> cameras.first StateError crash. No error UI: if init fails, blank screen forever (Center()).
- Flash button: TODO no-op (Flashoff.png) -> unresponsive button BUG (check if Flashon asset exists).
- takePicture no try/catch, no double-tap guard (multiple captures/navigations).
- Back arrow pops; camera reached via '/camera' named route with args {'privacy'}.
- ResolutionPreset.high; full-size JPEG uploaded later with no compression.
- Preview: Column>Stack>ClipRRect(CameraPreview) unconstrained -> aspect overflow on small screens possible.
- Captured temp file never deleted.
### History
- screenWidth = MediaQuery.size.height (typo) used for gap SizedBox(width: screenWidth*0.01) -> visual depends on height; preserve px.
- deleteCapsules: no error handling; no Storage image deletion (orphans).
- Favorites toast message double space "  favorites".
- stray `;` line.
- Empty state text plain Text (design).
- Subscribes with currentUser! in initState.
### Map (map_page.dart) — "not working" root-cause candidates
- Map rendered only after first location event from `location` plugin stream; no initial getLocation, no timeout, no permission/service handling -> infinite LaterLoadingBar if GPS off / no fix (emulator) / permission missing. LIKELY MAIN SYMPTOM.
- `_capsuleIcons['user']!` and `icon!` null-check crash if icons not yet loaded (async _initIcons race) or capsule color unknown -> red error screen. LIKELY.
- data['location'] cast GeoPoint w/o null check; createdAt.toDate() null crash.
- UNBOUNDED StreamBuilder on entire `capsules` collection (all users incl. PRIVATE) filtered client-side -> privacy leak + cost. Stream recreated on every build? (`FirebaseFirestore.instance.collection('capsules').snapshots()` inside build -> new stream each setState => re-subscribe on every location update & zoom change!!) PERF/COST BUG.
- setState in async callbacks w/o mounted; jumpService listener never removed; locationStream listen subscription not cancelled (service closes controller).
- MapPage.currentPositionStatic global static.
- Maps API key hardcoded; restriction unknown (needs gcloud) -> blocker; mapId cloud styling ids hardcoded.
- friends list loaded once (stale).
- Heatmap always + markers above zoom 12.
### Messages: placeholder "Messages Page" (keep).
### Profile: AutomaticKeepAlive in IndexedStack (no effect), uid from UserDataService.currentLoggedInUid ('No User' until fetched!) -> widgets built with 'No User' uid on first frame (BUG: queries for 'No User').
