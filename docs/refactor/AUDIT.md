# AUDIT.md — state of the app before the refactor

Snapshot: branch `refactor/architecture-and-stabilization`, commit `9f17db0` (plus emulator tooling), 2026-10-16.
Scope read in full: `lib/` (153 files, ~15 000 lines), `test/`, `android/`, `ios/`, `functions/`, `public/`, Firebase config/rules/indexes, `pubspec.yaml`, assets.
Appendices with line-level detail: `audit/CORE_AUDIT_NOTES.md` (services, controllers, pages, platform), `audit/WIDGETS_AUDIT_A.md` and `audit/WIDGETS_AUDIT_B.md` (every widget file, exact design values). Bugs are tracked in `BUGS.md`; Firebase specifics in `FIREBASE_AUDIT.md`.

## 1. What the app is

"Later" is a time-capsule app: a user takes a photo, attaches a title/description, a colour, a privacy level (private/friends/public) and an optional opening date, and pins it at their current location. Capsules appear on a Google Map (markers + heatmap) and in a "My Capsules" history list with search/sort/filter/favourites. There is a friends system (requests, QR/deep-link profile sharing, pinned friends), a follow system that drives push notifications, an in-app notifications page, a profile with avatar/background images, and a settings area (several pages are placeholders). Android is the primary target; iOS is configured but cannot be built here.

## 2. Current architecture map

```
lib/
  main.dart                     bootstrap + MaterialApp + named routes + deep-link channel + snowfall overlay + global navigatorKey
  firebase_options.dart         (git-ignored, local)
  data/
    notifiers.dart              global ValueNotifier<int> selectedPageNotifier (navbar tab)
    models/time_capsule.dart    TimeCapsule model (unused by the UI; maps are used instead)
  services/                     ChangeNotifier "services" provided at the root via MultiProvider,
                                plus static helpers; each talks to Firebase directly
    firebase_auth_service, user_data_service, user_friends_service, capsule_data_service,
    user_favorite_capsules_service, user_image_service, image_assets_service, firebase_storage_service,
    cache_service, push_notification_service, location_service, map_marker_service,
    map_capsule_jump_service, sharing_service, deep_link_service, popup_notification_service
  controllers/                  page/widget ChangeNotifier controllers (some own Firebase calls)
  views/
    pages/{auth_pages, core_pages, navbar_pages, friends_pages, settings_pages, capsule_related_pages}
    widgets/{_common/*, auth, capsule_creation, history_page, map, notifications, friends/*, my_profile_page/*, add_friend_profile, share_profile, user}
    styles/                     two small ButtonStyle helpers
```

**State management.** Provider + `ChangeNotifier` is the dominant pattern (34 files import provider), but it is mixed with: a global `ValueNotifier` for the tab index, static mutable fields (`MapPage.currentPositionStatic`, `CacheService`, `FirebaseStorageService`, `PopupNotificationService`), a singleton `PushNotificationService` that is *also* provided, per-widget `ValueNotifier<ImageProvider>` maps inside `UserImageService`, `FutureBuilder`s whose futures are created in `build()`, and services instantiated directly inside widgets (`UserFriendsService()`, `AssetImageService()`, `FirebaseAuthService()`).

**Navigation.** Navigator 1.0 used four different ways: a `routes:` map with string names (`'/camera'`, `'/loginPage'`…), `MaterialPageRoute`, `PageTransition` (10 ms fade, 17 files), and `navigatorKey.currentState` from widgets. The home route is a `StreamBuilder` on `FirebaseAuth.authStateChanges()` that is later *replaced* (`pushReplacement`) by the permission gate, so auth changes stop driving the UI. Deep links arrive through a custom `MethodChannel` (`later.app/deeplink`) and are handled with fixed delays (2 s / 500 ms).

**Data flow.** Widgets/controllers call services; services call `FirebaseFirestore.instance` / `FirebaseStorage.instance` / `FirebaseAuth.instance` directly and return `Map<String, dynamic>` (no typed models). Several widgets and pages call Firebase directly (map page, capsule creation controller, Google sign-in widget, login page password reset, avatar background widget). Caches live in four places with different keys and invalidation rules.

**Theme.** `ThemeData(colorScheme: fromSeed(Colors.green), fontFamily: 'Irina')` only. All colours, sizes, radii and text styles are hard-coded in widgets (≈ 30 radius-25 sites, 28 `Colors.white`, five different reds, three near-identical greys, text sizes as fractions of screen height/width). See `DESIGN_SPEC.md`.

## 3. Dependency review

| Package | Used? | Notes / action |
|---|---|---|
| firebase_core 4.7, firebase_auth 6.4, cloud_firestore 6.3, firebase_storage 13.3, firebase_messaging 16.1 (pinned) | yes | One major version behind (5/7/7/14/17 available). Keep current majors during the refactor (behaviour change risk); upgrade listed as a next step. |
| provider | yes | Keep (consolidate usage). |
| google_maps_flutter (+ `google_maps_flutter_ios` pinned direct) | yes | Keep. The iOS pin is a documented CocoaPods workaround — keep. |
| custom_info_window | yes | Old, unmaintained, imperative API with `!` callbacks. Keep for parity, wrap. |
| location 8 **and** geolocator 14 | both | Duplicate functionality. Consolidate on `geolocator` (permission/service checks, last-known fallback). Remove `location`. |
| geocoding | yes | Reverse geocoding for the yellow location pill; needs caching. |
| camera, image_picker, image | yes | `image` is used for thumbnails on the UI isolate — move to a background isolate. |
| permission_handler | yes | Keep. |
| flutter_local_notifications 19 | yes | Keep. |
| shared_preferences | yes | Keep (scope keys per user). |
| mobile_scanner, qr_flutter, share_plus | yes | Keep. |
| page_transition | yes (17 files) | Only used for a 10 ms fade. Replace with one in-house `PageRouteBuilder` in the router → remove dependency. |
| intl, collection | yes | Keep. |
| snow_fall_animation | yes | Seasonal overlay over the whole app (design). Keep. |
| url_launcher, flutter_contacts | only in `contacts_list.dart`, which is **never referenced** | Dead feature code. Remove file and both dependencies (git history keeps it). |
| http, google_maps (JS), auto_size_text, path_provider, cupertino_icons | **unused** | Remove. |
| flutter_launcher_icons | tool | Belongs in `dev_dependencies`. |
| flutter_lints | **not active** | Declared under the `flutter_icons:` section, not under `dev_dependencies`; `analysis_options.yaml` has no `include`. Fix and enable. |

Other: `pubspec.lock` is git-ignored (`*.lock`) — wrong for an application; `assets:` lists two folders twice; the font family is declared as `Irina` for the "Inria Sans" files (consistent throughout, keep the family name).

## 4. Platform configuration

- **Android:** Kotlin/Gradle fixed on this branch (Kotlin 2.3.10, `compilerOptions`). `minSdk 24`, NDK `27.0.12077973` (the `jni` plugin asks for 28.2 — warning only). Maps API key hard-coded in `AndroidManifest.xml` (committed). Obsolete `WRITE_EXTERNAL_STORAGE` + `requestLegacyExternalStorage`. `showWhenLocked`/`turnScreenOn` on the main activity (unusual for a social app). No monochrome notification icon. Deep-link intent filter for `later://profile`. Application id `com.example.later`.
- **iOS:** Maps key hard-coded in `AppDelegate.swift`. `Info.plist` usage strings are one-word placeholders, `NSPhotoLibraryUsageDescription` missing (image_picker gallery), no `UIBackgroundModes` for remote notifications, no entitlements file (no Push capability), landscape allowed in plist while the app forces portrait. No `GoogleService-Info.plist` (Dart options are used — fine). **Cannot be built or verified on this Windows machine.**
- **Web/desktop:** `flutter build web` compiles, but there are no web Firebase options, so the app cannot run on web. Windows desktop cannot be built (no Visual Studio). Linux/macOS folders are template leftovers. Not in scope.

## 5. Quality gate baseline (before any refactor)

| Gate | Result |
|---|---|
| `flutter pub get` | OK (80 packages have newer incompatible versions) |
| `flutter analyze` | "No issues found" — **meaningless**: no lint set is active (see §3) |
| `flutter test` | **1 failing** — the template counter smoke test (`test/widget_test.dart`) |
| `flutter build apk --debug` | OK after the Kotlin fix (warnings: incremental-cache errors due to C:/D: split → `kotlin.incremental=false`; NDK version warning) |
| `flutter build web --debug` | Compiles; unusable at runtime (no web Firebase options) |
| Windows / iOS / macOS builds | Not possible in this environment |
| Runtime walkthrough (emulator + Firebase emulators) | 55 screenshots in `screenshots/before/`; reproduced BUG-001/002/003/013/020/029/040/041/057/063/070/078 |

## 6. Structural problems, prioritised

1. **Security / privacy (S1).** No real Firestore/Storage rules in the repo; the client design *requires* world-readable `users` (email, FCM token) and `capsules` (including private ones), and cross-user writes (`friends` arrays, other users' `notifications`). Public Cloud Function leaks emails and makes images public. Secrets committed (Maps key; Firebase config historically). → `FIREBASE_AUDIT.md`, `SECURITY_FINDINGS.md`.
2. **No session lifecycle.** Nothing owns "the signed-in user". Services read `FirebaseAuth.instance.currentUser` at random times, cache per process, and are only partly reset on logout. Root cause of BUG-006/010/011/012/020/021/022/075.
3. **Firebase access everywhere.** Firestore/Storage/Auth calls in widgets, pages, controllers and 9 services; untyped maps; duplicated queries and caches; unbounded queries and listeners re-created in `build()` (map, suggested friends, pinned friends, request rows).
4. **Push notification pipeline is broken end to end** (BUG-020…033): startup-only init, token never re-synced, client re-writes server notifications (loop), no tap routing, function field mismatch, no privacy check, iOS not configured.
5. **Map is not robust** (BUG-040…047): API key authorisation (blocker), infinite loader without location, null-check crashes, whole-collection listener re-created on every location tick.
6. **Navigation is ad hoc**: four navigation styles, auth-driven root replaced, permission gate pushed from three places, string routes with untyped `arguments`, fixed delays for deep links.
7. **No design system**: hard-coded values everywhere, many near-duplicate components (13 groups in audit B, 10+ in audit A), screen-ratio sizing that ignores text scale.
8. **Lifecycle bugs**: controllers/text controllers not disposed, `setState`/`notifyListeners` after dispose, timers never cancelled, futures created in `build()`.
9. **Assets**: inconsistent naming (`Flashon (2).png`, `123.png`, `Camerafull.png`, mixed case), raw string paths in ~60 places, one orphan asset (`pin_pink_icon.png`).
10. **Tooling**: no lints, one failing template test, no CI, no emulator setup, lockfile ignored.
