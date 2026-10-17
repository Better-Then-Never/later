import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../data/firebase/firestore_mappers.dart';

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
