import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/l10n/l10n.dart';
import '../core/logging/app_logger.dart';
import '../core/theme/app_colors.dart';
import '../data/firebase/firebase_capsule_repository.dart';
import '../data/firebase/firebase_settings_repository.dart';
import '../data/models/app_notification.dart';
import '../data/services/geocoding_service.dart';
import '../data/services/location_service.dart';
import '../data/services/preferences_store.dart';
import '../data/services/country_names.dart';
import '../features/capsules/opening/capsule_openings.dart';
import '../features/map/map_pin_store.dart';
import '../features/places/place_alerts.dart';
import '../features/settings/device_settings_store.dart';
import '../firebase_options.dart';
import 'firebase_setup.dart';

/// The place alerts' check (capsule v3 phase 4), run about every half hour
/// by PlacesWorker.kt while the app is closed: where the phone is, then
/// "You're near …" for a capsule within 200 m the user may open there (F4)
/// and "Welcome to …" after two hours in a new country (F3). The capsules
/// come from the map's pins kept on the phone; only a candidate's title is
/// read. Nothing about the position leaves the phone but the country lookup
/// (the system's geocoder, as for a new capsule's place).
@pragma('vm:entry-point')
Future<void> backgroundPlacesMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('later.app/places_worker');
  try {
    await _check();
  } catch (e, st) {
    AppLogger.warning('Place alerts check failed', error: e, stackTrace: st);
  }
  await channel.invokeMethod<void>('done');
}

Future<void> _check() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await connectEmulatorsIfAsked();
  } catch (e) {
    AppLogger.debug('Emulators already connected: $e');
  }
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  final prefs = PreferencesStore();
  await prefs.init();
  final on = await DeviceSettingsStore.readPlaceAlerts(prefs, uid);
  if (!on.nearby && !on.country) return;
  final fix = await const LocationService().currentFix(
    timeout: const Duration(seconds: 20),
  );
  if (fix == null) return;
  final now = DateTime.now();
  final memory = await PlaceAlertsMemory.read(prefs, uid);
  final notes = <_Note>[];

  String? country;
  if (on.country) {
    country = (await GeocodingService().place(fix.position))?.countryCode;
    final welcome = PlaceAlerts.welcome(memory, country, now);
    if (welcome != null) notes.add(_Note.welcome(welcome));
  }

  if (on.nearby) {
    final capsules = FirebaseCapsuleRepository();
    final pins = await MapPinStore.readFile(uid);
    final unlocked = await capsules.watchUnlocked(uid).first;
    final openings = CapsuleOpenings(prefs);
    final found = PlaceAlerts.nearby(
      capsules: [for (final p in pins.pins) p.capsule],
      at: fix.position,
      now: now,
      unlocked: unlocked,
      wrapped: (c) => openings.isWrapped(
        // The pins keep no creation time: their date stands for it.
        c,
        uid,
        now,
      ),
      announced: memory.nearby,
    );
    // The nearest one only: one alert at a time.
    for (final (pin, metres) in found.take(1)) {
      final capsule = await capsules.getById(pin.id);
      if (capsule == null) continue;
      PlaceAlerts.announced(memory, pin.id);
      notes.add(_Note.nearby(pin.id, capsule.title, metres));
    }
  }

  await memory.save(prefs, uid);
  if (notes.isEmpty) return;
  final settings = await FirebaseSettingsRepository().watch(uid).first;
  final n = settings.notifications;
  // Capsule notifications on, and not in quiet hours.
  if (!n.enabled || !n.capsules || PlaceAlerts.quiet(n.quietHours, now)) {
    return;
  }
  final l10n = AppL10n.forLanguage(settings.language);
  final names = country == null
      ? const <String, String>{}
      : await CountryNames().of([country], l10n.localeName);
  final local = FlutterLocalNotificationsPlugin();
  await local.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_stat_notification'),
    ),
  );
  final channelId = !n.sound
      ? 'activity_silent'
      : !n.vibrate
      ? 'activity_novibrate'
      : 'activity';
  for (final note in notes) {
    final (title, body) = switch (note) {
      _Welcome(:final country) => (
        l10n.placesWelcomeTitle(names[country] ?? country),
        l10n.placesWelcomeBody,
      ),
      _Nearby(:final title, :final metres) => (
        l10n.placesNearbyTitle(title),
        l10n.placesNearbyBody(((metres / 10).round() * 10).toInt()),
      ),
    };
    await local.show(
      note.id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          l10n.notificationsChannelActivity,
          icon: '@drawable/ic_stat_notification',
          color: AppColors.brandGreen,
          actions: [
            if (note is _Welcome)
              AndroidNotificationAction(
                'leave',
                l10n.placesLeaveCapsule,
                showsUserInterface: true,
              ),
          ],
        ),
      ),
      payload: jsonEncode(note.payload),
    );
  }
}

/// An alert to show.
sealed class _Note {
  const _Note();

  factory _Note.welcome(String country) = _Welcome;
  factory _Note.nearby(String capsuleId, String title, double metres) = _Nearby;

  int get id;
  Map<String, String> get payload;
}

final class _Welcome extends _Note {
  const _Welcome(this.country);

  final String country;

  @override
  int get id => 'welcome:$country'.hashCode;

  @override
  Map<String, String> get payload => {
    'type': NotificationType.newCountry.name,
    'country': country,
  };
}

final class _Nearby extends _Note {
  const _Nearby(this.capsuleId, this.title, this.metres);

  final String capsuleId;
  final String title;
  final double metres;

  @override
  int get id => 'nearby:$capsuleId'.hashCode;

  @override
  Map<String, String> get payload => {
    'type': NotificationType.capsuleNearby.name,
    'capsuleId': capsuleId,
  };
}
