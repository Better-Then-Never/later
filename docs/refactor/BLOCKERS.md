# BLOCKERS.md

Each blocker: what is blocked · what was tried · best hypothesis · exact manual step for the project owner.

## B-01 — Google Maps tiles do not load (Android)
- **Blocked:** verifying the map visually (tiles, cloud styling via `mapId`).
- **Tried:** ran the app on the emulator; logcat shows `Google Android Maps SDK: Authorization failure … Android Application (<cert_fingerprint>;<package_name>): FE:77:7D:3A:18:E3:26:53:1E:78:20:16:5F:C4:63:8F:0F:A8:F0:6E;com.example.later`. No `gcloud` access to inspect the key.
- **Hypothesis:** the Maps API key is restricted to other Android apps (e.g. the teammate's debug SHA-1), or "Maps SDK for Android" is not enabled for it, or the key was rotated during the secrets cleanup.
- **Manual step:** Google Cloud Console → APIs & Services → Credentials → the Maps key (or a new restricted key, see SEC-01) → Application restrictions → Android apps → add `com.example.later` with every developer's debug SHA-1 (`keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`) and the release SHA-1; API restrictions → Maps SDK for Android (+ iOS for the iOS key). Put the key in `android/local.properties` as `MAPS_API_KEY=...` (git-ignored) — see REPORT.md.
- **Code-side status:** the map no longer depends on tiles to load: location fallback, capsule queries (counts logged in debug builds) and error states were verified with tiles missing. Marker rendering and the position of the custom info window could not be verified: without an authorised key the SDK draws no overlays and returns no usable projection (the info window appeared in the top-right corner). Manual check once the key works: markers appear at zoom ≥ 12, tapping one opens the info window right above it, the heatmap shows below zoom 12, tapping a capsule in History moves the map and opens its info window.

## B-02 — Google Sign-In on this developer's machine
- **Blocked:** end-to-end Google sign-in test.
- **Hypothesis:** the new Firebase Android app only lists SHA-1 `c4432e…`; this machine's debug SHA-1 `FE:77:7D:3A…` is not registered → `DEVELOPER_ERROR`. Also not testable against the Auth emulator without the Google provider configured.
- **Manual step:** `firebase apps:android:sha:create 1:250917243354:android:9ef498aa834b1cb22758e3 FE:77:7D:3A:18:E3:26:53:1E:78:20:16:5F:C4:63:8F:0F:A8:F0:6E --project later-da778` (writes to the shared project — owner's decision), then download the refreshed `google-services.json`.

## B-03 — Push notifications end to end
- **Blocked:** sending a real FCM message (needs a service account for the production project; the Functions emulator cannot deliver FCM to a device).
- **Verified instead:** token registration/removal against the Firestore emulator; foreground display and tap routing by injecting `RemoteMessage`s through the same handlers (widget/unit tests) and by posting local notifications on the emulator; Cloud Functions logic with unit tests (mocked `messaging().sendEach`).
- **Manual step:** after deploying functions and rules, sign in on two devices (A, B), have B follow A → A receives "New Follower" in background, foreground and terminated states; tap opens B's profile. Optionally use `tools/push/send_test.js` with a service-account JSON (never commit it).

## B-04 — iOS build and iOS push
- **Blocked:** building/running iOS (Windows host), APNs configuration, Push capability.
- **Done in code:** Info.plist usage strings + `UIBackgroundModes/remote-notification`, `Runner.entitlements` with `aps-environment`, Maps key moved to xcconfig.
- **Manual step (on a Mac):** open `ios/Runner.xcworkspace`, Signing & Capabilities → add *Push Notifications* and *Background Modes → Remote notifications* (check that Xcode links the provided `Runner.entitlements`), upload an APNs auth key in Firebase Console → Project settings → Cloud Messaging, `pod install`, run on a real device.

## B-05 — Test account credentials
- **Blocked:** using a provided test account (`TEST_ACCOUNT_EMAIL`/`TEST_ACCOUNT_PASSWORD` not set, no `.env.local`).
- **Done instead:** emulator-only accounts created by `tools/emulator/seed.js` (`alice@later.test`, …; password from `TEST_ACCOUNT_PASSWORD` or an emulator-only default). Nothing touched production.

## B-06 — Production rules and data shape are unknown
- **Blocked:** confirming that the new rules accept every existing production document.
- **Manual step:** before deploying rules, export a sample (`gcloud firestore export` or the console) and run `tools/rules-tests` against it, or deploy to a staging project first. See MIGRATIONS_NEEDED.md.
