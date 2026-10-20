import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/logging/app_logger.dart';
import '../data/firebase/firestore_mappers.dart';
import '../data/services/preferences_store.dart';

/// The phone's copy of Firestore (docs/map/COLD_START.md): every read of the
/// app goes through it first, and the map's first capsules come from it.
/// Bounded below the SDK's default (100 MB), so documents no query has asked
/// for in a long time are collected; indexed by the SDK itself for the
/// queries it runs (off by default); emptied once whenever
/// [_cacheGeneration] changes, before anything else uses Firestore (it held
/// 3,727 capsules of old test data, most read again by every map query).
/// Only this phone's copy: the server's data is never touched. Writes not
/// yet sent at that moment are dropped with it (docs/map/BLOCKERS.md).
Future<void> configureFirestoreCache(PreferencesStore prefs) async {
  final firestore = FirebaseFirestore.instance;
  // How the SDK answers each query (full scan, index, last results), in the
  // device log: --dart-define=FIRESTORE_LOG=true.
  if (const bool.fromEnvironment('FIRESTORE_LOG')) {
    await FirebaseFirestore.setLoggingEnabled(true);
  }
  firestore.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: _cacheBytes,
  );
  if (prefs.deviceStringSync(_cacheGenerationKey) != '$_cacheGeneration') {
    try {
      await firestore.clearPersistence();
    } on Object catch (e) {
      AppLogger.warning('Firestore cache not cleared', error: e);
    }
    await prefs.setDeviceString(_cacheGenerationKey, '$_cacheGeneration');
  }
}

/// Lets the SDK index its cache for the queries it runs (after
/// [configureFirestoreCache] and the emulator settings: it starts the
/// instance).
void indexFirestoreCache() {
  final indexes = FirebaseFirestore.instance.persistentCacheIndexManager();
  if (indexes == null) return;
  unawaited(
    indexes.enableIndexAutoCreation().catchError((Object e) {
      AppLogger.warning('Firestore cache indexes not enabled', error: e);
    }),
  );
}

const _cacheBytes = 40 * 1024 * 1024;
const _cacheGeneration = 1;
const _cacheGenerationKey = 'firestore_cache_generation';

/// Opt-in local Firebase Emulator Suite, for development and testing only:
/// `flutter run --dart-define=USE_FIREBASE_EMULATOR=true`.
const useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
const _firebaseEmulatorHost = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
  defaultValue: '10.0.2.2',
);

/// Points Auth, Firestore and Storage at the local emulators in emulator
/// builds (the app, and the background upload worker); nothing otherwise.
Future<void> connectEmulatorsIfAsked() async {
  if (!useFirebaseEmulator) return;
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
