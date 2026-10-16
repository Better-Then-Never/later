# CI and releases

Workflows in `.github/workflows/`:

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `release.yml` | every push to `main` | builds a signed APK and an unsigned IPA and publishes them as GitHub release `v0.0.N` (N = latest `v0.0.*` tag + 1) |
| `android.yml` | manual | builds a signed APK, publishes it as release `v0.0.<run number>` |
| `dart.yml` | manual | builds an unsigned IPA, publishes it as release `v0.0.<run number>` |

A merge into `main` therefore always produces a public release.

## Firebase config in CI

The Firebase config files are git-ignored (see `docs/refactor/MIGRATIONS_NEEDED.md`).
`tools/ci/write-config.sh android|ios` recreates them from repository secrets
before the build, and fails with a clear error when a secret is missing.

## Required repository secrets

Settings → Secrets and variables → Actions → New repository secret.

| Secret | Content | Used by |
| --- | --- | --- |
| `FIREBASE_OPTIONS_DART_BASE64` | base64 of `lib/firebase_options.dart` | Android, iOS |
| `GOOGLE_SERVICES_JSON_BASE64` | base64 of `android/app/google-services.json` | Android |
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | base64 of `ios/Runner/GoogleService-Info.plist` | iOS |
| `MAPS_API_KEY_ANDROID` | Google Maps key restricted to Android app `com.btn.later` | Android |
| `MAPS_API_KEY_IOS` | Google Maps key restricted to iOS bundle `com.btn.later` (optional; without it maps are blank on iOS) | iOS |
| `KEYSTORE_BASE64` | base64 of the release keystore (already set) | Android |
| `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` | release keystore credentials (already set) | Android |

Encode a file without line breaks:

```sh
base64 -w0 lib/firebase_options.dart          # Linux / Git Bash
base64 -i lib/firebase_options.dart | tr -d '\n'  # macOS
```

With the GitHub CLI the file can be piped in directly:

```sh
base64 -w0 lib/firebase_options.dart | gh secret set FIREBASE_OPTIONS_DART_BASE64
```

## Local builds

- Android Maps key: `MAPS_API_KEY=...` in `android/local.properties`, or the
  `MAPS_API_KEY` environment variable, or `GOOGLE_MAPS_API_KEY=...` in `.env`.
- iOS Maps key: `GMS_API_KEY=...` in `ios/Flutter/Secrets.xcconfig`.
- Release signing: set `KEYSTORE_FILE` (relative to `android/app`),
  `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`; without `KEYSTORE_FILE`
  release builds are signed with the debug key.
