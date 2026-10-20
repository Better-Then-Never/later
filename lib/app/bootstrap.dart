import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/logging/app_logger.dart';
import '../core/theme/themed_asset_bundle.dart';
import '../data/services/preferences_store.dart';
import '../core/theme/font_warmup.dart';
import '../features/achievements/achievement_icon.dart';
import '../features/map/map_licenses.dart';
import '../firebase_options.dart';
import 'app_scope.dart';
// The background upload job's entry point (UploadWorker.kt) must be part
// of the compiled app; nothing here calls it.
// ignore: unused_import
import 'background_uploads_main.dart' show backgroundUploadsMain;
import 'firebase_setup.dart';
import 'appearance/appearance_controller.dart';
import 'later_app.dart';
import 'shell/startup_report.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  StartupReport.begin();
  MapLicenses.register();

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

  await configureFirestoreCache(preferences);
  await connectEmulatorsIfAsked();
  indexFirestoreCache();

  // No FirebaseMessaging.onBackgroundMessage handler on purpose: every push
  // carries a `notification` payload, which the OS displays by itself while
  // the app is in the background or terminated, and taps arrive through
  // getInitialMessage/onMessageOpenedApp. Registering a handler starts a
  // second Flutter engine on Android's main thread at every launch; with an
  // empty handler that cost bought nothing and froze startup (POL-001).

  StartupReport.mark('run');
  runApp(
    AppScope(
      preferences: preferences,
      appearance: appearance,
      child: const LaterApp(),
    ),
  );
}
