# BUGS.md — living bug list

Status values: `open`, `fixed`, `blocked` (see BLOCKERS.md), `wontfix` (reason given), `kept` (intentional behaviour preserved).
Severity: **S1** crash / data loss / security, **S2** broken feature, **S3** visible defect, **S4** minor.
"Repro" = reproduced on the Android emulator against the local Firebase emulators (screenshots in `screenshots/before/`), or "code" = proven by reading code/config.
Detailed widget-level findings with line numbers live in `audit/WIDGETS_AUDIT_A.md` (A-xx) and `audit/WIDGETS_AUDIT_B.md` (B-xx); they are referenced here instead of duplicated.

## Startup, auth, session

| ID | Screen | Symptom | Root cause | Sev | Repro | Status | Fix |
|---|---|---|---|---|---|---|---|
| BUG-001 | Splash | App stays on the native splash forever when push setup fails (seen with stale Firebase config: `FIS_AUTH_ERROR`). | `main()` awaits `PushNotificationService.initialize()` before `runApp`, and `initialize()` rethrows. | S1 | repro | fixed | 7518612 |
| BUG-002 | Startup | Notification permission is requested at cold start, before the user has seen anything or logged in (system dialog over a blank screen). | `initialize()` calls `requestPermission()` unconditionally at startup. The permission gate also asks for it later. | S3 | repro (`startup_notification_permission_prompt.png`) | fixed | 7fd29c8 |
| BUG-003 | Login | Wrong-password message shows `Exception: Wrong password provided.` | `FirebaseAuthService` throws `Exception(msg)` and the UI prints `e.toString()`. | S3 | repro (`login_error_wrong_password.png`) | fixed | 7518612 |
| BUG-004 | Login | New Firebase SDKs return `invalid-credential` (email enumeration protection); the app maps it to the generic "An error occurred". | Error-code table lacks `invalid-credential`, `too-many-requests`, `network-request-failed`, `user-disabled`. | S3 | code | fixed | 7518612 |
| BUG-005 | Login/Signup | Two permission gates are stacked after login; navigation stack is inconsistent (Login→Signup uses `pushReplacementNamed`, Signup→Login uses `push`). | `SubmitButton` pushes a `PermissionGatePage` while the root `StreamBuilder` also switches to one; navigation is spread over widgets. | S3 | code | fixed | 7518612 |
| BUG-006 | Home | After the permission gate, the root auth `StreamBuilder` is replaced (`pushReplacement`), so the app no longer reacts to auth changes (token expiry, account deletion → stays "logged in" with failing calls). | `onAllGranted` replaces the home route. | S2 | code | fixed | 7518612 |
| BUG-007 | Login | `TextEditingController`s created inside `build()` of a `StatelessWidget` (never disposed; typed text can be lost on rebuild). | `LoginPage.build`. Signup controllers never disposed. | S4 | code | fixed | 7518612 |
| BUG-008 | Signup | Username uniqueness is checked with an **unauthenticated** query on `users` before the account exists (requires world-readable `users`), and is racy (two signups can take the same username). | `createUserWithEmailAndPassword` queries `users where username ==` before auth. | S1 (security) | code | fixed | 7518612 |
| BUG-009 | Google sign-in | If the derived username (email prefix) is taken, the Firebase account is created but **no `users` document** is written → broken account (profile "Unknown"). | `addUserToDatabase` throws after `signInWithCredential`. | S2 | code | fixed | 7518612 |
| BUG-010 | Logout | Logout does not reset all session state: capsule cache, pinned friends (global prefs key), push token association, friends listener (`_friendsSub` never cancelled); `FirebaseAuthService().signOut()` is not awaited. | Session state is scattered over singletons; no single sign-out path. | S2 | code | open | |
| BUG-011 | Session | `UserDataService.currentLoggedInUid` returns the literal `'No User'` until the profile is fetched; widgets use it for Firestore/Storage paths (`users/No User`, `userdata/No User/...`) and for the share QR link. | Sentinel string instead of nullable/auth uid. | S2 | code | fixed | 7518612 |
| BUG-012 | Session | Data of the previous account can survive into the next session (profile/background image bytes cached in SharedPreferences under global keys; pinned friends under a global key; negative image cache). | Global, non-uid-scoped caches. | S2 | code | open | |
| BUG-013 | Permission gate | All five permissions (camera, mic, location, notifications, contacts) are mandatory; denying one blocks the app forever. A permission that is already granted shows "Granted" without advancing. | Product decision in `PermissionGatePage`. | S3 | repro | kept (behaviour preserved; auto-advance fixed) — see IDEAS_NOT_DONE.md | |

## Notifications (push + in-app list)

| ID | Screen | Symptom | Root cause | Sev | Repro | Status | Fix |
|---|---|---|---|---|---|---|---|
| BUG-020 | Notifications | In-app list is **empty after login** even though notifications exist (3 seeded). | Notifications are loaded only once, at cold start, before any user is signed in. No auth listener / realtime listener. | S2 | repro (`notifications_all.png`) | fixed | 7fd29c8 |
| BUG-021 | Push | FCM token is saved only if a user is already signed in at cold start; after login/signup the token is never saved → the user receives no pushes until the next cold start. | Token sync not tied to auth state. | S1 (feature broken) | code | fixed | 7fd29c8 |
| BUG-022 | Push | After logout the token stays on the previous user's document → that user's pushes go to whoever uses the device next. | No token removal on sign-out. | S1 (privacy) | code | fixed | 7fd29c8 |
| BUG-023 | Push | Receiving a `follow` push while the app is in the foreground writes a **new** `follow` notification document for the current user, which triggers `sendFollowerNotification` again → push loop while the app is open; every push also duplicates the in-app entry (`onMessage`, `onMessageOpenedApp`, `getInitialMessage` all write). | Client re-saves server-created notifications. | S1 | code | fixed | 7fd29c8 |
| BUG-024 | Push | Tapping a notification (system or local) does nothing. | `_onNotificationTapped` and list `onTap` are TODOs; local payload is `Map.toString()` (unparseable). | S2 | code | fixed | 7fd29c8 |
| BUG-025 | Push | Foreground notification small icon is the full-colour launcher icon (renders as a white square on Android status bar); no `default_notification_icon` metadata. | Android requires a monochrome icon. | S3 | code | fixed | 7fd29c8 |
| BUG-026 | Push | `sendCapsuleNotification` never notifies anyone. | Function reads `capsule.creatorId`; the app writes `ownerId`. | S2 | code | open | |
| BUG-027 | Push | Once fixed, `sendCapsuleNotification` would notify followers about **private** capsules and about friends-only capsules to non-friends. | No privacy check. | S1 (privacy, latent) | code | open | |
| BUG-028 | Push | Follow notification is only created when the target already has an FCM token; avatar field stores a local asset path string (`assets/images/...`) in Firestore. | `_sendFollowerNotification` preconditions and missing `profilePicture` field. | S3 | code | open | |
| BUG-029 | Notifications | "Replies" and "Comments" tabs are always empty (types never produced). | Tabs filter `reply`/`comment`. | S3 | repro (`notifications_replies.png`) | kept (tabs are part of the design; documented) | |
| BUG-030 | Notifications | Mark-as-read / delete operate by list index captured at build time → can hit the wrong notification after a refresh. | Positional API. | S2 | code (A-B10) | fixed | 7fd29c8 |
| BUG-031 | Notifications | 'capsule' notifications build `AssetImage('')` → asset load exception and grey avatar. | Function writes `fromUserAvatar: ''`. | S3 | code (A-B2) | fixed | 7fd29c8 |
| BUG-032 | Notifications | `markAllAsRead`/`clearAll` use a single batch → fail above 500 documents. | Unbounded batch. | S4 | code | open | |
| BUG-033 | Notifications | iOS: no `UIBackgroundModes/remote-notification`, no `aps-environment` entitlement → no pushes on iOS. | Missing iOS config. | S2 | code | blocked (needs Xcode/APNs, see BLOCKERS.md) | |

## Map

| ID | Screen | Symptom | Root cause | Sev | Repro | Status | Fix |
|---|---|---|---|---|---|---|---|
| BUG-040 | Map | Map tiles are blank (beige), no markers. Logcat: `Google Android Maps SDK: Authorization failure … FE:77:7D:3A…;com.example.later`. | The Maps API key does not authorise this app/signing certificate (or Maps SDK for Android is disabled for the key). | S1 | repro (`map_blank_tiles_auth_failure.png`) | blocked (Cloud Console, see BLOCKERS.md) | |
| BUG-041 | Map | Infinite loading logo when no location fix arrives (GPS off, no fix yet, permission revoked). | Map renders only after the first `location` stream event; no initial fix, timeout, fallback or error. | S2 | repro (`map_loading.png`, ~20 s on emulator) | open | |
| BUG-042 | Map | Red error screen possible: `_capsuleIcons['user']!` / `icon!` null-check when a location event arrives before marker icons finish loading, or for an unknown colour. | Async icon loading race, force unwraps. | S1 | code | open | |
| BUG-043 | Map | Downloads the **entire** `capsules` collection (all users, incl. private) and filters on the client; the stream is re-created in `build()` on every location update and zoom change → re-subscribe storms and cost. | Unbounded query inside `build`. | S1 (privacy + cost) | code | open | |
| BUG-044 | Map | Crash for capsules without `location`/`createdAt`. | Unchecked casts. | S2 | code | open | |
| BUG-045 | Map | Map info window overflows on most phones (fixed `0.171 × height`). | Fixed-size `CustomInfoWindow`. | S3 | code (A-L2) | open | |
| BUG-046 | Map | Friends list for friends-only capsules is loaded once and never refreshed; listeners never removed (`CapsuleJumpService` listener leak, `setState` without `mounted`). | Lifecycle. | S3 | code | open | |
| BUG-047 | Map/History | Distance and capsule creation rely on a mutable static `MapPage.currentPositionStatic`. | Global state on a widget. | S3 | code | open | |

## Camera / capsule creation

| ID | Screen | Symptom | Root cause | Sev | Repro | Status | Fix |
|---|---|---|---|---|---|---|---|
| BUG-050 | Camera | Flash button does nothing. | `// TODO` (icons `Flashon`/`Flashoff` exist). | S3 | repro (`camera_preview.png`) | open | |
| BUG-051 | Camera | No app-lifecycle handling: preview breaks after backgrounding (camera not released/re-initialised). | No `WidgetsBindingObserver`. | S2 | code | open | |
| BUG-052 | Camera | Blank black screen forever if no camera / init fails; `cameras.first` throws on devices without cameras. | No error state. | S2 | code | open | |
| BUG-053 | Camera | Double tap on shutter takes two pictures / pushes twice; `takePicture` errors unhandled. | No guard / try-catch. | S3 | code | open | |
| BUG-054 | Capsule creation | Two taps on "Create Capsule" create two capsules. | No re-entrancy guard. | S2 | code (A-B33) | open | |
| BUG-055 | Capsule creation | Full-resolution photo uploaded with no compression/content type; temp file never deleted; if Firestore write fails the uploaded image is orphaned. | No image pipeline. | S3 | code | open | |
| BUG-056 | Capsule creation | Raw exception text shown: `Failed to save capsule: <exception>`. | `'$e'` in message. | S3 | code | open | |
| BUG-057 | Capsule creation | Capsule saved without an open date is marked `isScheduled: true` with `openAt: null` and shows "Capsule is opened!" immediately. | Model defaults. | S3 | repro (`history_with_new_capsule.png`) | kept (current semantics: no date = opened); documented | |
| BUG-058 | Capsule creation | Controllers never disposed; `setState` after `await` without `mounted`; reverse geocoding re-runs on every rebuild. | Lifecycle. | S3 | code (A-B21, A-B27, A-B28) | open | |
| BUG-059 | Capsule creation | "Back" re-opens the camera without the original privacy argument. | `pushReplacementNamed('/camera')` without arguments. | S4 | code (A-B23) | fixed | 7518612 |

## History (My Capsules)

| ID | Screen | Symptom | Root cause | Sev | Repro | Status | Fix |
|---|---|---|---|---|---|---|---|
| BUG-060 | History | Crash for a capsule without `location` (`location!`). | Force unwrap. | S1 | code (A-B1) | open | |
| BUG-061 | History | Every tile runs a 1-second timer forever (N rebuilds per second). | `Timer.periodic` never cancelled when opened. | S3 | code (A-B29) | open | |
| BUG-062 | History | Deleting capsules leaves their images in Storage; errors unhandled. | `deleteCapsules` only deletes documents. | S3 | code | open | |
| BUG-063 | History | Default order is undefined (document-id order). | Listener has no `orderBy` (the fetch method has one). | S4 | repro (`history_populated.png`) | open | |
| BUG-064 | History | "No image" placeholder is 0.2×0.15 px (invisible). | Typo in sizes. | S4 | code (A-B15) | open | |
| BUG-065 | History | Info rows overflow on 320–360 dp phones. | Rows without `Flexible`. | S3 | code (A-L1) | open | |
| BUG-066 | History | Favourite toggle: optimistic update without rollback; `update()` fails if the user doc is missing. | Service logic. | S4 | code | open | |

## Friends / profile

| ID | Screen | Symptom | Root cause | Sev | Repro | Status | Fix |
|---|---|---|---|---|---|---|---|
| BUG-070 | Add friends | Received request (Dave → Alice) shows the same "pending" clock as a sent request; it should offer accept. | `requestExists` merges sent and received. | S3 | repro (`add_friends.png`) | open | |
| BUG-071 | Add friends | Suggested users = unbounded realtime listener on the whole `users` collection, re-created on each rebuild/keystroke; exposes every user's email and FCM token to every client. | `getSuggestedFriends`. | S1 (privacy + cost) | code (B-H2) | open | |
| BUG-072 | Add friends | Search is case-sensitive against lower-case usernames ("Dave" finds nothing); query errors (missing index) are swallowed → silently empty list. | Raw query text; no error handling. | S3 | code (B-H2) | open | |
| BUG-073 | Add friends | N+1 reads + image preloads per suggested user from `build`. | `SuggestedFriendsListController.loadUser`. | S3 | code (B-H3) | open | |
| BUG-074 | Friends | Each opening of "Manage friendship"/remove-friend modal creates a new `UserFriendsService` with 3 never-cancelled listeners. | `UserFriendsService()` in widgets. | S2 | code (B-H1) | open | |
| BUG-075 | Friends | `UserFriendsService` initialises its listeners at provider creation; a different user logging in without app restart relies on `WidgetTreeWrapper` calling `init()`; `_friendsSub` is never cancelled. | Session lifecycle. | S2 | code | open | |
| BUG-076 | Friends | Accepting a request writes the **other** user's document (`friends` arrayUnion) → requires rules that let any user edit any user's `friends`. | Cross-user write without server validation. | S1 (security) | code | open | |
| BUG-077 | My friends | Crash (RangeError) when a friend has an empty name. | `friend['name'][0]`. | S2 | code (B-H7) | open | |
| BUG-078 | Profile | Pinned friends row reshuffles randomly on every rebuild and re-fetches images. | `FutureBuilder(future: getDisplayFriends())` in `build`. | S3 | repro (`profile_own.png` vs later captures) | open | |
| BUG-079 | Profile | Pinned-friends limit can be blocked by stale uids (global prefs key). | Not intersected with friends. | S3 | code (B-M2) | open | |
| BUG-080 | Profile | Profile/background upload: no compression/size limit/content type; base64 copy in SharedPreferences; 128×128 thumbnail squashes non-square photos on the UI thread; other avatars not refreshed after upload. | Image pipeline. | S2 | code (B-H4) | open | |
| BUG-081 | Profile | "Delete profile icon/background" without an existing image locks the widget in "Updating…" forever. | No try/catch. | S2 | code (B-H5) | open | |
| BUG-082 | Profile/Add friends | Request-count badge wraps `Positioned` in `Positioned` → ParentDataWidget error in debug. | Widget returns `Positioned`. | S3 | code (B-H6) | open | |
| BUG-083 | Settings | Username change: no lower-casing, no uniqueness, no validation. | `updateUsername`. | S2 | code (B-H8) | open | |
| BUG-084 | Friends | Accept/Reject/Cancel without loading state or double-submit guard; success toasts never show (row unmounted). | UI state handling. | S3 | code (B-M4, B-M5) | open | |
| BUG-085 | Friends | Page controllers never disposed → listeners leak on the global friends service. | Missing `dispose`. | S3 | code (B-M6) | open | |
| BUG-086 | Profile | Header buttons positioned at fixed `top: 35` without SafeArea → overlap status bar on notched iPhones. | Fixed offsets. | S3 | code (B-M7) | open | |
| BUG-087 | Profile | "Updating…" caption uses font family `Inria` (typo) → system font. | Typo. | S4 | code (B-M9) | open | |
| BUG-088 | Friend options | Chat settings, Capsules settings, Share profile to…, Report, Block, Open chat, Send Capsule: buttons do nothing. | Unimplemented features. | S3 | repro (`friend_options_modal.png`) | kept (adding them = new features; see IDEAS_NOT_DONE.md). "Share profile to…" wired to the existing share flow — see fix column | |
| BUG-089 | Friend remove | Double `pop()` after removing a friend; global popup hidden on dispose. | Modal flow. | S3 | code (B-M13) | open | |
| BUG-090 | Settings | `setState`/context used after `await` without `mounted` (name settings, permissions, profile pictures). | Lifecycle. | S3 | code (B-M12, B-M14, B-M15) | open | |
| BUG-091 | Permissions settings | Status not refreshed after returning from OS settings. | No resume hook. | S3 | code (B-M14) | open | |
| BUG-092 | Share profile | QR/link built from `'No User'` until profile loaded. | BUG-011. | S3 | code | open | |

## Data, security, backend

| ID | Area | Symptom | Root cause | Sev | Repro | Status | Fix |
|---|---|---|---|---|---|---|---|
| BUG-100 | Firestore rules | Repo `firestore.rules` is the expired test-mode rule (denies everything after 2025-09-03); production rules are unknown but must be permissive for the app to work. | No real rules. | S1 | code | open | |
| BUG-101 | Storage rules | Repo `storage.rules` denies everything; production differs. | No real rules. | S1 | code | open | |
| BUG-102 | Firestore | Required composite indexes are not declared (`capsules: ownerId + createdAt`; friend requests `fromUserId/toUserId + status`). | Empty `firestore.indexes.json`. | S2 | code | open | |
| BUG-103 | Functions | `getUserData` is a public unauthenticated endpoint that returns any user's email and calls `makePublic()` on their profile image. | Function design. | S1 | code | open | |
| BUG-104 | Model | `TimeCapsule.fromMap` throws on unknown privacy/colour or null `createdAt`; the model is unused (maps everywhere) and defaults disagree (`blue` vs `red`). | No mapper layer. | S3 | code | open | |
| BUG-105 | Config | `firebase.json` `flutter` section still references the deleted Firebase app IDs. | Stale FlutterFire config. | S4 | code | open | |
| BUG-106 | Repo | `pubspec.lock` is git-ignored (`*.lock`) → non-reproducible builds for an application. | `.gitignore`. | S3 | code | open | |
| BUG-107 | Lints | `flutter_lints` is declared under `flutter_icons:` in pubspec and `analysis_options.yaml` has no `include`, so no lints run ("No issues found" is meaningless). | pubspec/analysis options. | S3 | code | open | |
| BUG-108 | Android | Obsolete `WRITE_EXTERNAL_STORAGE`/`requestLegacyExternalStorage`; activity forced `showWhenLocked`/`turnScreenOn`. | Manifest. | S4 | code | fixed | 7fd29c8 |
| BUG-109 | Deep links | Cold-start deep link can be lost: Kotlin sends it before the Dart handler exists, and Dart then waits a fixed 2 s. | Race in `MainActivity`/`main.dart`. | S3 | code | fixed | 7518612 |
| BUG-110 | iOS | No `NSPhotoLibraryUsageDescription` → crash when picking a profile picture from the gallery on iOS; usage strings are placeholders ("Camera"). | Info.plist. | S1 (iOS) | code | fixed | 7fd29c8 |
| BUG-111 | Tests | The only test is the default counter smoke test, which fails. | Template leftover. | S4 | repro | open | |
