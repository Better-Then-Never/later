# REPORT.md — Architectural refactor and stabilization of Later

Branch **`refactor/architecture-and-stabilization`**, cut from `notifications_page` (f8a3de3). Nothing was merged, force-pushed or deployed, and no production data was touched. Every runtime check ran against the Firebase Emulator Suite. Supporting documents live in `docs/refactor/`: AUDIT, FIREBASE_AUDIT, BUGS, DESIGN_SPEC, SECURITY_FINDINGS, BLOCKERS, MIGRATIONS_NEEDED, IDEAS_NOT_DONE, REFACTOR_PLAN, PROGRESS, and the screenshots with COMPARISON.md.

---

## 1. The new architecture

```
lib/
  main.dart                  → bootstrap()
  app/                       wiring of the whole app
    bootstrap.dart           Firebase init, emulator switch, error handlers, runApp
    app_scope.dart           composition root: creates every repository, service and store once
    later_app.dart           MaterialApp (theme, snowfall overlay, home = AuthGate)
    router/                  AppRoutes (every navigation), page routes, deep-link handler
    session/                 SessionController (who is signed in) + AuthGate (which root screen)
    shell/                   home shell: navbar, IndexedStack of the 4 tabs, selected tab
  core/                      app-wide basics (no feature or data access)
    theme/                   AppColors, AppTextStyles, AppDimens, AppTheme (design tokens)
    assets/                  typed asset paths (AppIcons, AppImages, AppAnimations)
    errors/                  AppFailure (sealed: Auth/Validation/Permission/Network/NotFound/Unknown)
    logging/                 AppLogger (debugPrint in debug, token redaction)
    session/                 SessionScoped: interface of everything that belongs to one user
  data/                      the only place that talks to Firebase
    models/                  Capsule, UserProfile, FriendRequest, AppNotification, GeoPosition
    repositories/            interfaces (AuthRepository, CapsuleRepository, …)
    firebase/                Firebase implementations + tolerant mappers
    services/                device services: location, geocoding, image processing, push, prefs, image cache
  features/                  one folder per area of the app, each with its own state
    auth/  map/  capsules/{camera,creation}/  history/  friends/  users/
    profile/{widgets,share}/  notifications/  settings/  messages/
  shared/                    the component library (see §6)
    widgets/  styles/
```

**How the layers work together**
- **app/** builds everything once (`AppScope`) and provides it through `provider`. `SessionController` listens to Firebase Auth. On sign-in it *attaches* every `SessionScoped` store (friends, capsules, favourites, notifications, push registration, image cache, user directory). On sign-out it detaches them, so nothing from one account can leak into the next. `AuthGate` picks the root screen (welcome / login / permission gate / home) from the session state.
- **data/** hides Firebase behind interfaces. Widgets, stores and controllers never import Firebase SDKs; outside `data/` only `bootstrap.dart` (initialisation), the generated `firebase_options.dart` and `AppFailure.from` (to turn `FirebaseException` codes into messages) do. Mappers accept legacy and malformed documents without crashing. Writes use server timestamps, batches and transactions.
- **features/** each own a `ChangeNotifier` controller or store (one state approach: Provider + ChangeNotifier) and their pages and widgets. Pages call controllers; controllers call repositories; errors come back as an `AppFailure` with a user-facing message.
- **shared/** holds reusable, design-exact widgets with no business logic.
- **Navigation** goes through `AppRoutes` (Navigator 1.0, the same 10 ms fade and 100 ms slide-up transitions as before). Deep links and notification taps wait until the home screen is ready.

## 2. Bugs

`BUGS.md` lists **91 bugs** found by reading the whole code base, running the app and testing the backend. Each has a severity, evidence, status and the commit that fixed it. **86 are fixed**, each verified on the emulator or by a test (most by both).

Highlights:
- **Startup / session:** crashes on startup and push init (BUG-001), the permission prompt at cold start (BUG-002), the "No User" uid placeholder (BUG-011), previous-account data surviving logout (BUG-010/012/114).
- **Map:** a native crash with no capsules (BUG-048), an unbounded query downloading every capsule including private ones (BUG-043), an 18 s load.
- **Camera / capsules:** double capture and double save (BUG-053/054), images stored uncompressed without a content type and never deleted (BUG-055/062).
- **History:** a crash on a capsule without a location (BUG-060).
- **Friends:** cross-user writes (BUG-076), an unbounded user listener exposing e-mails (BUG-071), listener leaks (BUG-074/075/085).
- **Notifications:** a Firestore write loop on every push (BUG-023), and pushes never sent for capsules (BUG-026) or sent for private ones (BUG-027).
- **Backend:** expired rules (BUG-100/101), a public function leaking e-mails (BUG-103).

Two bugs were found during final verification and fixed with regression tests: a "used after dispose" exception after every login (BUG-113), and avatars missing after an account switch (BUG-114).

Not fixed, with reasons:

| Bug | Status | Reason |
|---|---|---|
| BUG-029 | kept | "Replies"/"Comments" notification tabs are always empty: no reply/comment feature exists, and the tabs are part of the design. |
| BUG-033 | code done, unverified | iOS push: Info.plist background mode and `aps-environment` entitlement added; needs Xcode and an APNs key (BLOCKERS B-04). |
| BUG-040 | blocked | Map tiles blank: the Maps API key rejects this machine's SHA-1 (BLOCKERS B-01, Cloud Console). |
| BUG-088 | partly | Placeholder buttons (chat, report, block, send capsule…) are new features (IDEAS_NOT_DONE.md). "Share profile to…" now opens the share sheet. |
| BUG-112 | open | A one-off 7 px overflow logged once when the keyboard first opened; not reproducible. Debug builds now log the full widget report so the next occurrence names the widget. |

## 3. Firebase changes

**Data model** (details in FIREBASE_AUDIT.md):
- New `usernames/{username} → {uid}` reservation documents make usernames unique.
- New `users/{uid}/fcmTokens/{token}` documents, one per device, replace the single public `fcmToken` field.
- The client no longer writes `email`/`fcmToken` into the public user document.
- Capsules are created with server timestamps, `isScheduled` reflects whether an open date was set, and images are compressed JPEGs with a content type.

**Rules** (`firestore.rules`, `storage.rules`, commit 76e3a75) replace the expired test-mode rule and the deny-all Storage rule:
- Owner-only writes with field validation.
- Friendship edits on another user's document only to add or remove yourself, and only while accepting their request.
- Capsules visible to the owner, everyone (public) or friends (friends-only).
- Notifications and tokens private.
- Storage uploads limited to images under a size limit.
- Covered by **31 tests** in `tools/rules-tests` on dedicated emulators. These also verify the map's latitude-band GeoPoint query.

**Indexes** (`firestore.indexes.json`): `capsules (ownerId ASC, createdAt DESC)` for History; `capsules (privacy ASC, location ASC)` for the public map band.

**Functions** (`functions/`, commit b0ea48e; logic in `lib/notify.js`, **10 tests** on the emulators):
- Pushes go to every device plus the legacy token, and dead tokens are pruned.
- Capsule notifications read `ownerId`, skip private capsules, and go only to friends for friends-only capsules.
- `getUserData` returns only a name and an avatar URL: no e-mail, no `makePublic`.

**Data migration** (`tools/migrations/migrate.js`):
- Dry run by default; it refuses to touch a real project without `--production`.
- Tested on the emulator, and rehearsed on the seeded dev data.

**`firebase.json`** now lists the current app ids; it has an emulators block.

### Deployment steps — MANUAL, in this order (owner only)

> None of these were run. Order matters: see MIGRATIONS_NEEDED.md §1.

1. Indexes, then wait until they show *Enabled*:
   `firebase deploy --only firestore:indexes --project later-da778`
2. Cloud Functions:
   `cd functions && npm ci && firebase deploy --only functions --project later-da778`
3. Release the app built from this branch.
4. Back up the data (`gcloud firestore export gs://<bucket>/backup-<date>`). Then run the migration as a dry run, then apply:
   `cd tools/migrations && npm install && GOOGLE_APPLICATION_CREDENTIALS=<service-account.json> node migrate.js --project later-da778 --production` (add `--apply` after reviewing the dry run).
5. Run the rules tests (`cd tools/rules-tests && npm install && npm run emulate`), then deploy the rules last, once most users run the new version:
   `firebase deploy --only firestore:rules,storage --project later-da778`
6. Remove the public ACLs the old function set on profile images (MIGRATIONS_NEEDED.md §3).

## 4. Notifications, map and camera

**Notifications**
- *Root causes:*
  - Push init was awaited before `runApp` and could crash startup.
  - The permission prompt appeared at cold start.
  - A single token lived in a public field and was never removed at logout.
  - Every received push was written back into Firestore (duplicates and loops).
  - The list loaded once and was addressed by position; taps did nothing.
  - The capsule function read a field that is never written and ignored privacy.
- *Fixes:*
  - `PushMessagingService` initialises after the first frame.
  - `PushRegistration` (session-scoped) saves a per-device token at sign-in and deletes it at sign-out.
  - `NotificationsStore` is a live, bounded list addressed by id.
  - `NotificationRouter` routes taps (FCM, local notifications, cold start) once the home screen is ready.
  - The Android notification icon is monochrome.
  - The functions were rewritten (§3).
- *Verified:*
  - Token document created at sign-in and removed at sign-out (checked after an account switch).
  - In-app list, unread badge and mark-read under the new rules.
  - Follow writes plus the follow notice under the rules.
  - Tap routing of an in-app notification.
  - Payload parser and function tests.
- *Needs a real device:* real FCM delivery in foreground, background and terminated states, and taps on system notifications (BLOCKERS B-03). iOS needs the Xcode/APNs steps in B-04.

**Map**
- *Root causes:*
  - The whole `capsules` collection was streamed and re-subscribed on every rebuild, private capsules included.
  - A native crash when the heatmap had no points.
  - A blocking 18 s location wait.
  - No fallback without a location permission.
- *Fixes:*
  - `MapController` queries own capsules, friends' friends-only capsules (chunked `whereIn`) and public capsules in a ±2° latitude band.
  - The same visibility rule is enforced on the client and by the security rules.
  - The heatmap is skipped when empty.
  - The last known position is used first, with a 5 s fresh fix and a fallback camera.
  - History → map focus.
- *Verified on the emulator:* counts per source (own/friends/public), another user's private capsule excluded, works with location off, the rules accept all three queries.
- *Needs a real device / key:* tiles, markers and info-window placement, because the Maps key does not authorise this machine (B-01). The key moved out of tracked files and must be rotated (SEC-01).

**Camera / capsule creation**
- *Root causes:* the camera was not released on pause, the flash button was dead, a black screen with no error, double captures, double saves, uncompressed uploads without a content type, orphaned images, `setState` after dispose.
- *Fixes:*
  - Lifecycle-aware `CameraPage` with an error view and a flash toggle.
  - `CapsuleCreationController` with a re-entrancy guard and a location fallback.
  - The repository compresses the photo in an isolate (≤ 1600 px JPEG), uploads it with a content type, and removes the upload if the document write fails.
- *Verified:*
  - Flash, background/resume, capture.
  - Double tap → one capsule.
  - Stored image/jpeg (99 KB, was 151 KB octet-stream).
  - Delete removes the document and the image.
  - Create under the new rules.
- *Needs a real device:* a real camera (the emulator uses a virtual scene) and iOS.

## 5. Assets

Assets were grouped by feature: `assets/icons/{auth,camera,capsule,friends,history,map,navbar,profile}`, `assets/images/later_logo.png`, `assets/animations/later_logo_loading.gif`, `assets/fonts/inria_sans/`. Unused artwork moved to `design/unused_assets/` (kept, not bundled).

Use the typed accessors in `lib/core/assets/app_assets.dart` instead of string paths:

```dart
Image.asset(AppIcons.cameraShutter);
Image.asset(AppIcons.capsulePin(capsule.color.name)); // per-colour pins
Image.asset(AppImages.laterLogo);
```

`test/core/app_assets_test.dart` fails if a path is mistyped or an asset is missing from `pubspec.yaml`.

## 6. Component library (`lib/shared/`)

| Component | Use it for |
|---|---|
| `widgets/page_header.dart` | The rounded white page header (title, back button, search bar, action row). |
| `widgets/default_text.dart` | Text in the app font with the standard defaults. |
| `widgets/default_search_bar.dart` | Grey rounded search field with optional trailing button. |
| `widgets/buttons/` | `DefaultGreenButton` (primary action, built-in loading state), `DefaultButtonWithIcon`, `DefaultIconButton`, `DefaultTextButton`, `GoBackButton`. |
| `widgets/options/` | `OptionsSettingsRow` (settings list rows; navigates with the app fade), `OptionsInputField`. |
| `widgets/confirm_dialog.dart` | Yes/cancel confirmation (logout, delete). |
| `widgets/popup/` | `PopupNotificationService.showSuccess/showError/showInfo` toasts. |
| `widgets/user/` | `UserRoundAvatar`, `UserSquareAvatar`, `UserProfileImage`, `UserBackgroundImage`, `UserNameAndUsername`, `UserListTile`. They read the shared `ProfileImageCache`/`UserDirectory`, so every avatar of a user updates together. |
| `widgets/capsule/` | `CapsulePlacePill` (cached place name), `CapsuleDatePill`. |
| `widgets/` (misc.) | `DefaultEmptyInboxInfo`, `LaterLoadingBar`, `ProfilePageDivider`, `ShadowTopOverlay`, `WhiteCircularProgressIndicator`. |
| `styles/` | `BoxDecorations` (white card, shadows), elevated/text button styles. |

Colours, text styles, radii, spacing and shadows come from `lib/core/theme/` (tokens taken from the existing design, DESIGN_SPEC.md). 72 identical literals were replaced by tokens. Three golden tests (`test/goldens/`) lock the look of a capsule tile, a friend-request row and the image options sheet.

## 7. Dependency changes

| Change | Package | Reason |
|---|---|---|
| removed | `location` | Replaced by `geolocator` (already a dependency): one location API, with timeouts and last-known position. |
| removed | `page_transition` | Routes go through `AppRoutes` with Flutter's own `PageRouteBuilder` (same 10 ms fade / 100 ms slide). |
| removed | `http`, `google_maps`, `auto_size_text`, `path_provider`, `cupertino_icons` | Not used anywhere. |
| removed | `url_launcher`, `flutter_contacts` | Only used by dead code (deleted, recoverable from git). |
| added (dev) | `fake_cloud_firestore` | Repository tests without a backend. |
| moved | `flutter_lints` | Was declared under `flutter_icons:` so no lints ran (BUG-107); now a dev dependency, and the analysis options include it. |
| moved | `flutter_launcher_icons` | To dev dependencies (a build tool). |
| tracked | `pubspec.lock` | Reproducible builds (BUG-106). |
| build | Kotlin Gradle plugin 2.3.10, `compilerOptions`, `kotlin.incremental=false`, `minSdk 24` | The project did not build with the installed toolchain. |

Tooling added under `tools/` (Node, emulator-only): `emulator` (seed data), `rules-tests`, `migrations`. Plus the tests in `functions/test`.

## 8. Security findings (SECURITY_FINDINGS.md)

- **SEC-01:** the Google Maps API key was committed in plain text (Android manifest, iOS AppDelegate, so also in git history). It is now read from git-ignored `android/local.properties` / `ios/Flutter/Secrets.xcconfig`. **Rotate it and restrict it** (package + SHA-1s / bundle id, Maps SDK APIs only). History was not rewritten.
- **SEC-02:** Firebase client config lives in history. The files are git-ignored now.
- **SEC-04/05:** the repo rules were expired or deny-all; the production rules must have been permissive. They are rewritten and tested, and must be deployed last.
- **SEC-06:** the public function leaked e-mails and made images public. Fixed in code; deploy, and reset the ACLs.
- **SEC-07:** e-mail and FCM token were readable by every user. No longer written; the migration removes them.
- **SEC-08 to SEC-11:** unauthenticated username check, token kept at logout, tokens in logs, and lock-screen flags. All fixed.
- **SEC-12:** no App Check (recommended).

## 9. Tests and quality gates (final run)

| Gate | Result |
|---|---|
| `dart format --set-exit-if-changed lib test` | clean |
| `flutter analyze` | **No issues found** (lints enabled; it was 442 issues once lints were turned on) |
| `flutter test` | **94 passed**, 1 skipped (the GeoPoint band query, which `fake_cloud_firestore` cannot order; it is covered by the rules tests on the real emulator). Includes 3 golden tests. |
| Security rules tests (`tools/rules-tests`) | **31 passed** |
| Cloud Functions tests (`functions`, `npm run test:emulate`) | **10 passed** |
| Migration tests (`tools/migrations`) | **4 passed** |
| `flutter build apk --debug` / `--release` | both build |
| Emulator run-through with the new rules and migrated data | every read/write flow passed, with no `PERMISSION_DENIED` (PROGRESS.md) |
| Before/after screenshots | 56 + 56, same names; differences are bug fixes only (`screenshots/COMPARISON.md`) |

Not run: iOS build (Windows host) and real-device push (B-03/B-04).

## 10. Recommended next steps (deliberately not done)

1. **Owner actions:** rotate and restrict the Maps key; register the developers' SHA-1s (B-01/B-02); deploy in the order of §3; set up APNs/iOS signing (B-04).
2. **App Check**, Crashlytics, and Analytics events.
3. **Functions region** next to Firestore (`europe-central2`).
4. **Geohash map queries** instead of latitude bands, for dense areas (needs a migration).
5. **Features** that are placeholders today: chat, send capsule, friend's capsules, report/block, Facebook login, e-mail/password change, dark mode, localisation, "load more" in History and Notifications.
6. **Optional permissions:** ask for contacts and microphone just in time instead of at onboarding.
7. **More widget and golden tests** per screen, and CI that runs the gates in §9.
8. A bigger emulator image (the 2 GB AVD stalled under load once during testing).

Full list: IDEAS_NOT_DONE.md.

---

**Branch:** `refactor/architecture-and-stabilization` · **Commits:** 41 on top of `notifications_page` (f8a3de3), including this report.

**In short:** The app now works the same and looks the same, but its insides were rebuilt so it is reliable and safe. Startup no longer crashes. Signing out really signs you out: nothing from the previous account stays behind. The map only loads what you may see. The camera, capsule saving, history, friends, notifications and settings each had their bugs fixed, and each was checked on the emulator. The database and storage now have proper security rules, with tests, instead of an expired test rule. The cloud functions no longer leak e-mails, and they send pushes correctly. The code is organised into clear layers (app, data, features, shared components) that are easy to extend, and about 140 automated tests and clean analyzer and format checks guard it. Nothing was deployed. Before the new rules and functions go live, you need to do a few things yourself, in order: deploy the indexes and functions, release the app, migrate the data, deploy the rules last, and rotate the Maps key. Section 3 gives every step with the exact command.
