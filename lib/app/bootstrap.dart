import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/logging/app_logger.dart';
import '../firebase_options.dart';
import '../data/services/push_messaging_service.dart';
import 'app_scope.dart';
import 'later_app.dart';

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

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (_useFirebaseEmulator) {
    await FirebaseAuth.instance.useAuthEmulator(_firebaseEmulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(
      _firebaseEmulatorHost,
      8080,
    );
    await FirebaseStorage.instance.useStorageEmulator(
      _firebaseEmulatorHost,
      9199,
    );
  }

  // Must be registered before runApp and must be a top-level function.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const AppScope(child: LaterApp()));
}
