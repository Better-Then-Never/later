# FIREBASE_AUDIT.md

Project: `later-da778` (Firestore location `europe-central2`). Products used: **Auth** (email/password, Google), **Firestore**, **Storage**, **Cloud Messaging**, **Cloud Functions** (v2, Node 22), **Hosting** (`public/` landing page for profile links). Not used: Analytics (the Android Gradle file pulls `firebase-analytics` but nothing initialises or logs events), Crashlytics, App Check, Remote Config.

16 Dart files touch Firebase directly (`grep FirebaseFirestore.instance|FirebaseStorage.instance|FirebaseAuth.instance|FirebaseMessaging`): 9 services, 1 page controller, 4 pages, 1 widget, `main.dart`. Target: only `lib/data/**` may import Firebase SDKs (plus bootstrap).

---

## 1. Data model as it actually exists in code

### `users/{uid}`
| Field | Type | Written by | Read by | Notes |
|---|---|---|---|---|
| uid | string | signup, Google sign-in | — | redundant with doc id |
| email | string | signup, Google sign-in | Settings (own) | **readable by every user** under any rule set that allows friend search |
| name | string | signup, name settings | everywhere | no max length |
| username | string | signup (lower-cased), username settings (**not** lower-cased, not unique) | everywhere, prefix search | uniqueness checked with an unauthenticated query before signup |
| createdAt | timestamp (server) | signup | — | |
| friends | array<uid> | accept/remove friend — **including the other user's doc** | friends service, map visibility | cross-user writes |
| favorites | array<capsuleId> | favourites toggle | history | |
| fcmToken | string | push service | `sendFollowerNotification`, `sendCapsuleNotification` | **single device**; readable by every user; never removed on logout |
| fcmTokenUpdatedAt | timestamp | push service | — | |
| displayName / firstName / profilePicture | — | **never written** | `getUserData`, functions, follower notification | dead reads → fallbacks always used |

### `users/{uid}/notifications/{autoId}`
`type` ('follow' | 'capsule' | 'notification' fallback), `fromUserId`, `fromUserName`, `fromUserAvatar` (asset path string or `''`), `message`, `timestamp` (server), `isRead`, optional `title`, `thumbnailImage`, `capsuleId`.
Written by: the follower's client (`follow`, **cross-user write**), `sendCapsuleNotification` (server), and **the recipient's own client on every received push** (duplicates; see BUG-023).

### `users/{uid}/following/{targetUid}` — `{followedAt, notificationsEnabled: true}`
### `users/{uid}/followers/{followerUid}` — `{followedAt}` (written by the follower: cross-user write)

### `friend_requests/{fromUid}_{toUid}`
`fromUserId`, `toUserId`, `status` ('pending' | 'accepted'), `createdAt`, `acceptedAt`. Accepted requests are kept; rejected/cancelled are deleted; both directional docs are deleted on unfriend.

### `capsules/{autoId}`
`ownerId`, `imageUrl` (Storage download URL with token), `title`, `description` (string|null), `location` (GeoPoint), `privacy` ('private'|'friends'|'public'), `createdAt` (**client** `Timestamp.now()`), `isScheduled` (always `true`), `openAt` (timestamp|null), `color` ('red'|'blue'|'green'|'yellow'|'orange'|'purple').
The Cloud Function expects `creatorId` (never written).

### Storage
| Path | Written by | Notes |
|---|---|---|
| `userdata/{uid}/assets/images/profile_image` | profile picture | full-size, no content type, no size limit |
| `userdata/{uid}/assets/images/profile_image_small` | profile picture | 128×128 forced (aspect distortion), produced on UI isolate |
| `userdata/{uid}/assets/images/background_image` | profile background | full-size |
| `userdata/{uid}/capsules/{capsuleId}/image.jpg` | capsule creation | full camera JPEG, never deleted with the capsule |

### SharedPreferences (device)
`profile_image`, `background_image` (base64 bytes, **not uid-scoped**), `pinned_friend_uids` (**not uid-scoped**).

---

## 2. Usage inventory, problems and target design

### 2.1 Initialisation (`main.dart`)
- Initialised once with `DefaultFirebaseOptions.currentPlatform` — correct. The local options/google-services files were stale (deleted Firebase apps → `FIS_AUTH_ERROR`); refreshed outside git on 2026-10-16 (`firebase apps:sdkconfig`). `firebase.json` still lists the old app IDs (BUG-105).
- Push initialisation is awaited before `runApp` and rethrows (BUG-001); background handler registered after that await.
- **Target:** `app/bootstrap.dart` initialises Firebase, optional emulators, registers the background handler, then `runApp`. Push setup runs after the first frame and never blocks or crashes startup.

### 2.2 Auth (`firebase_auth_service.dart`, `login_with_social.dart`, `login_page.dart`, `submit_button.dart`, `settings_page.dart`, `logout_button.dart`)
Problems: auth state read ad hoc from `FirebaseAuth.instance` in 9 files; root auth stream replaced after the permission gate (BUG-006); unauthenticated username query before signup (BUG-008); Google account without user doc on username clash (BUG-009); error mapping incomplete (BUG-003/004); sign-out does not clean up (BUG-010/022).
**Target:** `AuthRepository` (only place that touches `FirebaseAuth`), one `SessionController` listening to `authStateChanges()` that starts/stops all per-user stores and the push token registration; signup = create Auth user → reserve username in a transaction (`usernames/{name}`) + create profile → on failure delete the Auth user; Google sign-in picks a free username automatically; typed `AuthFailure` with user-facing messages.

### 2.3 Firestore
| Location | Operation | Problem | Target |
|---|---|---|---|
| map_page.dart | `collection('capsules').snapshots()` in `build()` | **Unbounded, all users incl. private, re-subscribed on every rebuild** (BUG-043) | `CapsuleRepository.watchVisible(viewer, bounds)`: own (`ownerId == uid`), friends (`ownerId in chunk(friends,30)` + `privacy == 'friends'`), public in the visible latitude band (`privacy == 'public'`, `location` range); subscriptions owned by a controller, refreshed on camera idle |
| capsule_data_service.dart | `where ownerId ==` listener (no orderBy) + get with `orderBy createdAt` | listener order undefined; `notifyListeners` inside stream `map`; errors swallowed | `watchOwn(uid)` ordered by `createdAt desc` (needs index) |
| capsule_data_service.deleteCapsules | batch delete | images orphaned | delete docs in batches of ≤ 500, then delete Storage images |
| capsule_creation_page_controller | `doc().id`, `putFile`, `set` | Firebase in controller; client timestamp; orphan on failure | `CapsuleRepository.create(draft)`: compress → upload with content type → `set` with `serverTimestamp()`; delete upload if the write fails |
| user_data_service | `doc(uid).get()` cached forever, fallbacks cached on error | stale data, `'No User'` sentinel | `UserRepository.watchProfile(uid)` / `getProfiles(ids)` (batched `whereIn`), typed `UserProfile` |
| user_data_service.updateUsername | `update({username})` | no normalisation/uniqueness | transaction on `usernames/{new}` + `users/{uid}` + delete old reservation |
| user_friends_service | 3 listeners + `getSuggestedFriends` (whole collection, BUG-071) + follow writes | lifecycle leaks, cross-user writes, N+1 | `FriendsRepository`: requests/friends listeners scoped to the session; suggestions = `orderBy username` + prefix range + `limit(20)` on lower-cased input; accept = batch validated by rules |
| user_favorite_capsules_service | `arrayUnion/arrayRemove` | no rollback, fails if doc missing | `set(merge)` + rollback on error |
| push_notification_service | `update({fcmToken})`, notifications `get(limit 100)`, `add()` on every push, batch read/delete | see §2.5 | `NotificationRepository.watch(uid, limit)` realtime; mark-read/delete by id; batches chunked |
| login_with_social | `users/{uid}` get + set | Firebase in widget | `AuthRepository.signInWithGoogle()` |
| pinned_friends_controller | SharedPreferences global key | cross-account leak | uid-scoped key, intersect with friends |

Listener hygiene problems found: listeners created in `build()` (map, suggested friends, pinned friends `FutureBuilder`, request rows), `_friendsSub` never cancelled, controllers never disposed (B-M6), `UserFriendsService()` instantiated in modals (B-H1).

**Indexes required by the target queries** (the Firestore *emulator does not enforce composite indexes*, so these were derived from the query shapes, not from emulator errors):
- `capsules`: `ownerId ASC, createdAt DESC` (own history).
- `capsules`: `privacy ASC, location ASC` (public capsules in a latitude band).
- Equality-only queries (`friend_requests` by `fromUserId/toUserId + status`, friends' capsules by `ownerId in + privacy ==`) are served by automatic single-field indexes.

### 2.4 Storage
Problems: no content type, no size limits, no compression, thumbnail distortion on the UI isolate, four duplicate URL caches with permanent negative caching, base64 bytes in SharedPreferences, delete throws when an object is missing (BUG-081), capsule images orphaned on delete. `getUserData` makes profile images public.
**Target:** `ImageStorageRepository` with `uploadProfileImage` (square-crop 1024 + 256 thumbnail, JPEG, background isolate), `uploadBackground`, `uploadCapsuleImage` (max 1600 px, JPEG 85), `delete*` tolerant of `object-not-found`; `ProfileImageCache` keyed by uid with explicit invalidation after upload; rules enforce owner, `image/*`, size.

### 2.5 Cloud Messaging (+ local notifications)
Full chain review — every break found:
1. Init at cold start only, before auth (BUG-021); permission prompt at startup (BUG-002).
2. Token stored in a single public field; not refreshed per user; not removed on logout (BUG-022); multiple devices overwrite each other.
3. Foreground: shows a local notification (good) with a colour launcher icon (BUG-025) **and** re-writes the notification into Firestore (BUG-023 loop).
4. `onMessageOpenedApp` / `getInitialMessage`: re-write again; no navigation (BUG-024).
5. Background handler: top-level with `@pragma('vm:entry-point')` (good) but registered after the startup await.
6. Notification list: one-shot load at cold start (BUG-020); positional mark-read (BUG-030).
7. Android: channel `high_importance_channel` created by the app and referenced by the manifest meta-data and by the functions (consistent). Missing `default_notification_icon`. `POST_NOTIFICATIONS` declared and requested (gate + startup).
8. iOS: no `remote-notification` background mode, no `aps-environment` entitlement, no APNs key evidence in this repo (BUG-033) — cannot be verified here.
9. Server: `sendFollowerNotification` (trigger on notifications create, `type == 'follow'`) sends to the legacy single token and removes it on invalid-token errors (good). `sendCapsuleNotification` reads `creatorId` (wrong field, BUG-026), ignores privacy (BUG-027), N sequential reads per follower.
**Target:** tokens in `users/{uid}/fcmTokens/{token}` (owner-only; `platform`, `updatedAt`), registered by the session on sign-in and on `onTokenRefresh`, deleted (doc + `deleteToken()`) on sign-out; client never writes notifications for received pushes; one `NotificationRouter` handles taps from FCM (`onMessageOpenedApp`, `getInitialMessage`) and local notifications (JSON payload) through the central router; foreground display via `flutter_local_notifications` with a monochrome icon; functions send to all tokens of the user (new subcollection + legacy field), prune invalid tokens, respect privacy, and read `ownerId` (with `creatorId` fallback).

### 2.6 Cloud Functions (`functions/index.js`)
| Function | Problem | Fix |
|---|---|---|
| `getUserData` (HTTPS, public, CORS `*`) | Returns **email** of any uid; calls `makePublic()` on the profile image; lists bucket prefix on every call; returns a `debug` object | Return only `displayName` (name/username) and a token download URL of the *small* image built from object metadata; validate `userId`; no `makePublic`, no email, no debug |
| `sendFollowerNotification` | single token | multi-token + legacy, prune invalid |
| `sendCapsuleNotification` | wrong field, no privacy check, sequential N+1 reads | `ownerId ?? creatorId`; skip `private`; for `friends` only notify followers who are friends; parallel reads; multi-token |
Region: default `us-central1` while Firestore is in `europe-central2` — cross-region latency; changing the region of deployed functions is a deployment decision → documented, not changed. `index.js.backup` is a stale copy (removed). No lint/test setup.

### 2.7 Security rules review
- `firestore.rules` (repo): test-mode rule expired 2025-09-03 → denies everything. Production must be running *different*, unknown rules (the app works in production). Given the client code, production rules are necessarily permissive: any signed-in user must be able to read every `users` doc (email, FCM token), read every capsule (private ones included, because the map downloads the whole collection), update other users' `friends` arrays and write into other users' `notifications`/`followers`.
- `storage.rules` (repo): deny-all; production differs.
**Target (implemented in this refactor, deployment left to the user):** least-privilege rules matching the real model — owner-only writes with field/type validation, participants-only friend requests, friendship edits on another user's document limited to adding/removing exactly the caller and only when an accepted request exists, capsule reads limited to owner/public/friends, notifications readable only by the recipient and creatable by others only as `follow` from themselves, `fcmTokens` owner-only, Storage owner-only writes with content-type/size limits. Covered by `@firebase/rules-unit-testing` tests in `tools/rules-tests/`.

### 2.8 Not present
App Check, Crashlytics, Analytics events, Remote Config: not initialised → nothing to fix; adding them would be a new feature (listed in IDEAS_NOT_DONE.md).
