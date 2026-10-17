import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/logging/app_logger.dart';
import '../core/theme/themed_asset_bundle.dart';
import '../data/services/preferences_store.dart';
import '../core/theme/font_warmup.dart';
import '../features/achievements/achievement_icon.dart';
import '../firebase_options.dart';
import 'app_scope.dart';
import 'appearance/appearance_controller.dart';
import 'later_app.dart';
import '../data/firebase/firestore_mappers.dart';

/// Opt-in local Firebase Emulator Suite, for development and testing only:
/// `flutter run --dart-define=USE_FIREBASE_EMULATOR=true`.
const _useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
const _firebaseEmulatorHost = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
  defaultValue: '10.0.2.2',
);

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error(
      // In debug builds the full report names the widget that failed (e.g.
      // the creator of an overflowing Flex); release builds stay terse.
      kDebugMode ? 'Flutter error\n$details' : 'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Everything the first frame needs, in parallel: Firebase, the device
  // settings (theme, language, interface size: no flash of the wrong ones)
  // and the list of dark icon variants.
  final preferences = PreferencesStore();
  await Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    preferences.init(),
    ThemedAssetBundle.preload(),
    AchievementIcon.preloadArt(),
  ]);
  // Fonts loaded and shaped now, not on the first frame of a page.
  FontWarmup.run();
  final appearance = AppearanceController(preferences);
  await appearance.load();
  // Draw under transparent status and navigation bars (styles.xml); screens
  // pad themselves with the real insets.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  if (_useFirebaseEmulator) {
    // No automatic host mapping: FlutterFire would turn 127.0.0.1 into
    // 10.0.2.2 on Android, but a USB phone reaches this computer at
    // 127.0.0.1 through `adb reverse` (docs/feel/RIG.md).
    await FirebaseAuth.instance.useAuthEmulator(
      _firebaseEmulatorHost,
      9099,
      automaticHostMapping: false,
    );
    FirebaseFirestore.instance.useFirestoreEmulator(
      _firebaseEmulatorHost,
      8080,
      automaticHostMapping: false,
    );
    await FirebaseStorage.instance.useStorageEmulator(
      _firebaseEmulatorHost,
      9199,
      automaticHostMapping: false,
    );
    // Its download links are plain http: loop frames from it are accepted.
    FirestoreMappers.storageEmulatorOrigin =
        'http://$_firebaseEmulatorHost:9199/';
  }

  // No FirebaseMessaging.onBackgroundMessage handler on purpose: every push
  // carries a `notification` payload, which the OS displays by itself while
  // the app is in the background or terminated, and taps arrive through
  // getInitialMessage/onMessageOpenedApp. Registering a handler starts a
  // second Flutter engine on Android's main thread at every launch; with an
  // empty handler that cost bought nothing and froze startup (POL-001).

  runApp(
    AppScope(
      preferences: preferences,
      appearance: appearance,
      child: const LaterApp(),
    ),
  );
}
