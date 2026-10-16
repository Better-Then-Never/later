# REFACTOR_PLAN.md

## 1. Decisions

| Topic | Decision | Why |
|---|---|---|
| State management | **Keep Provider + ChangeNotifier**, used one way everywhere: session-scoped *stores* (app-wide state per signed-in user) and screen *controllers* (per page), both `ChangeNotifier`, created/disposed by providers; widgets only `watch`/`select`/`read`. No `setState` except ephemeral UI state (focus, animation, local toggles). No statics/globals for state. | Provider is already the dominant, mainstream pattern (34 files). A Riverpod migration would rewrite every widget with no user-visible benefit and high regression risk. The bugs come from *how* it is used (no session lifecycle, Firebase in widgets), not from Provider. |
| Navigation | **Navigator 1.0 with one central router**: `AppRoutes` (typed `static Future<T?> toX(context, args)` methods + `onGenerateRoute`), one `fadeRoute` transition reproducing the current 10 ms fade (and the 100 ms bottom-to-top one), a root `AuthGate` driven by the session (welcome/login → permission gate → home). Deep links and notification taps go through `AppLinkHandler` → `AppRoutes`. | Keeps the exact current transitions and back-stack behaviour, avoids platform-view issues (GoogleMap, camera) during the migration, removes `page_transition`. go_router would add a dependency and a rewrite without fixing a user-facing problem. |
| Layering | `ui → controller/store → repository (interface) → Firebase`. Only `lib/data/**` and `lib/app/bootstrap.dart` import Firebase SDKs. | Testability with fakes; one place per collection. |
| Models | Immutable hand-written classes with `fromFirestore`/`toFirestore` and **tolerant readers** (missing/unknown fields → safe defaults, both legacy and new shapes). No code generation. | Small model surface (5 entities); avoids build_runner. |
| DI | Providers in `app/app_scope.dart`; repositories behind abstract classes, injectable in tests. | |
| Errors & logging | `AppFailure` (typed, user-facing message), `AppLogger` (wraps `dart:developer` log, redacts tokens). No `print`. | |
| Theme | Tokens in `lib/core/theme/*` exactly matching DESIGN_SPEC.md; `AppTheme.light` sets the font, colours, input and button defaults so widgets use tokens instead of literals. | |
| Components | `lib/shared/widgets/` library (buttons, inputs, page header, navbar, dialogs/sheets, toasts, loaders, empty states, avatars, user rows, pills, badges). Small, `const` where possible, no business logic. | Weakest area per the team. |
| Assets | `assets/icons/<group>/<snake_case>.png`, `assets/images/`, `assets/animations/`, `assets/fonts/`; typed `AppIcons`/`AppImages`/`AppAnimations` (hand-written, checked by a test that every path exists and every file is referenced). | No raw strings in UI. |
| Config | Maps key via `local.properties`/xcconfig placeholders; emulator via `--dart-define`; Firebase config files stay local. | No secrets in git. |
| Lints | `flutter_lints` + a few extra rules (`prefer_const_*`, `avoid_print`, `unawaited_futures`, `use_build_context_synchronously`, `cancel_subscriptions`, `close_sinks`); target 0 issues. | |

## 2. Target structure

```
lib/
  main.dart                    → bootstrap()
  app/
    bootstrap.dart             Firebase init, emulator, background handler, runApp
    later_app.dart             MaterialApp, theme, snowfall overlay, AuthGate
    app_scope.dart             providers (repositories, services, stores)
    router/app_routes.dart     typed routes + transitions
    router/app_link_handler.dart  deep links + notification taps
    session/session_controller.dart  auth → start/stop stores, push token
    session/auth_gate.dart
  core/
    theme/  assets/  logging/  errors/  utils/
  shared/widgets/  (component library)
  data/
    models/  repositories/ (interfaces + firebase impls)  services/ (push, location, geocoding, image processing, prefs)
  features/
    auth/ home/ map/ capsules/ camera/ profile/ friends/ notifications/ settings/ share/
      <feature>/{presentation pages + widgets, controllers}
```

## 3. Ordered steps (the app compiles and runs after each)

1. **Tooling** — fix pubspec (lints in dev deps, remove unused deps, `flutter_launcher_icons` → dev), commit `pubspec.lock`, real `analysis_options.yaml`, delete the failing template test.
2. **Core foundations** — tokens/theme, logger, failures, utils, `fadeRoute`, typed asset accessors (pointing at current paths). No visual change.
3. **Asset reorganisation** — move/rename files, update accessors, pubspec, remove orphans after usage check. Screenshot spot-check.
4. **Data layer** — models + repository interfaces + Firebase implementations + services (push, location, geocoding cache, image processing in isolates, uid-scoped prefs), unit tests with fakes. Not wired yet.
5. **App shell** — bootstrap, app scope, session controller, auth gate, central router, deep-link handler; replace `main.dart` flow and the three permission-gate pushes; logout through the session. Fixes BUG-001/002/005/006/007/010/011/012/109.
6. **Notifications** — stores + push service wired to session; realtime list; tap routing; no client re-writes; monochrome icon; Android manifest; iOS plist/entitlements. Fixes BUG-020…033.
7. **Map** — geolocator-based location with fallback/timeout/error, icon preloading, bounded visibility-correct queries via repository, controller lifecycle, info window sizing. Fixes BUG-041…047 (BUG-040 blocked).
8. **Camera + capsule creation** — lifecycle, flash, error states, guards, compression/upload pipeline, temp cleanup, controller disposal. Fixes BUG-050…059.
9. **History** — store-backed list ordered by date, timers fixed, null safety, delete with Storage cleanup. Fixes BUG-060…066.
10. **Profile / friends / share / settings** — stores and controllers, bounded suggestions, request state, pinned friends, image editing pipeline, username transaction, modals consolidated. Fixes BUG-070…092.
11. **Auth pages** — controllers, error mapping, Google sign-in username, signup transaction. Fixes BUG-003/004/008/009.
12. **Component library consolidation** — replace remaining duplicates; delete dead widgets/services.
13. **Firebase backend** — rules + rules tests, indexes, functions fixes + tests, firebase.json cleanup.
14. **Tests & gates** — unit/controller/widget/golden tests, format, analyze 0, build, after-screenshots, REPORT.md.

Each step updates `PROGRESS.md` and `BUGS.md`.
