import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/logging/app_logger.dart';
import '../data/firebase/firebase_capsule_repository.dart';
import '../data/firebase/firebase_chat_repository.dart';
import '../data/services/preferences_store.dart';
import '../features/capsules/outbox/capsule_outbox.dart';
import '../features/settings/device_settings_store.dart';
import '../firebase_options.dart';
import 'firebase_setup.dart';

/// The job's Dart side: signs in as the app last did, tries every waiting
/// capsule once, and answers how many still wait (-1 when it could not
/// look: the job then tries again later).
@pragma('vm:entry-point')
Future<void> backgroundUploadsMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('later.app/uploads_worker');
  var remaining = -1;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      await connectEmulatorsIfAsked();
    } catch (e) {
      // The app already set them up in this process.
      AppLogger.debug('Emulators already connected: $e');
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      remaining = 0; // Signed out: nothing of anyone's to send.
    } else {
      final wifiOnly = await DeviceSettingsStore.readUploadsWifiOnly(
        PreferencesStore(),
        uid,
      );
      final outbox = CapsuleOutbox(
        FirebaseCapsuleRepository(),
        chats: FirebaseChatRepository(),
        // WorkManager waited for Wi-Fi already when it is asked for.
        wifiOnly: () => wifiOnly,
      )..attach(uid);
      await outbox.loading;
      remaining = outbox.pending.length;
      AppLogger.info('Background uploads: $remaining still waiting');
      outbox.dispose();
    }
  } catch (e, st) {
    AppLogger.warning('Background uploads failed', error: e, stackTrace: st);
  }
  await channel.invokeMethod<void>('done', remaining);
}
