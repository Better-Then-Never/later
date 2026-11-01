import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../core/session/session_scoped.dart';
import '../../data/services/preferences_store.dart';
import '../places/background_places.dart';

/// How the map draws the world.
enum MapLook {
  standard,
  satellite,
  hybrid;

  /// The name shown in settings, in the app's language.
  String get label => switch (this) {
    standard => AppL10n.current.settingsMapLookStandard,
    satellite => AppL10n.current.settingsMapLookSatellite,
    hybrid => AppL10n.current.settingsMapLookHybrid,
  };

  static MapLook parse(String? value) =>
      values.firstWhere((v) => v.name == value, orElse: () => standard);
}

/// Which camera the capsule camera opens with.
enum StartCamera {
  back,
  front;

  /// The name shown in settings, in the app's language.
  String get label => switch (this) {
    back => AppL10n.current.settingsCameraBack,
    front => AppL10n.current.settingsCameraFront,
  };

  static StartCamera parse(String? value) =>
      values.firstWhere((v) => v.name == value, orElse: () => back);
}

/// How distances are written.
enum DistanceUnit {
  kilometres,
  miles;

  /// The name shown in settings, in the app's language.
  String get label => switch (this) {
    kilometres => AppL10n.current.settingsUnitsKilometres,
    miles => AppL10n.current.settingsUnitsMiles,
  };

  static DistanceUnit parse(String? value) =>
      values.firstWhere((v) => v.name == value, orElse: () => kilometres);
}

/// How big capsule photos are sent.
enum PhotoQuality {
  /// 1600 px, JPEG 85: quick on a slow connection.
  standard,

  /// 2560 px, JPEG 90: sharper, about twice the size.
  high;

  /// The name shown in settings, in the app's language.
  String get label => switch (this) {
    standard => AppL10n.current.settingsPhotoQualityStandard,
    high => AppL10n.current.settingsPhotoQualityHigh,
  };

  static PhotoQuality parse(String? value) =>
      values.firstWhere((v) => v.name == value, orElse: () => standard);
}

/// Preferences of this device for the signed-in user (map look, starting
/// camera, distance unit, photo quality, saving photos to the gallery).
/// Kept on the device: they describe how this phone behaves, not the
/// account.
class DeviceSettingsStore extends ChangeNotifier implements SessionScoped {
  DeviceSettingsStore(this._prefs);

  final PreferencesStore _prefs;

  static const _mapKey = 'map_look';
  static const _cameraKey = 'start_camera';
  static const _unitKey = 'distance_unit';
  static const _qualityKey = 'photo_quality';
  static const _galleryKey = 'save_to_gallery';
  static const _wifiKey = 'uploads_wifi_only';
  static const _nearbyKey = 'alerts_nearby';
  static const _countryKey = 'alerts_country';

  String? _uid;
  MapLook _map = MapLook.standard;
  StartCamera _camera = StartCamera.back;
  DistanceUnit _unit = DistanceUnit.kilometres;
  PhotoQuality _quality = PhotoQuality.standard;
  bool _saveToGallery = false;
  bool _wifiOnly = false;
  bool _nearbyAlerts = false;
  bool _countryAlerts = false;

  /// "You're near …" while the app is closed (phase 4, F4). Needs location
  /// all the time; off until the user turns it on.
  bool get nearbyAlerts => _nearbyAlerts;

  /// "Welcome to …" after a while in a new country (phase 4, F3).
  bool get countryAlerts => _countryAlerts;

  /// Capsules wait for Wi-Fi (no upload on a metered network).
  bool get uploadsWifiOnly => _wifiOnly;

  MapLook get mapLook => _map;
  StartCamera get startCamera => _camera;
  DistanceUnit get distanceUnit => _unit;
  PhotoQuality get photoQuality => _quality;

  /// Capsule photos also go to the phone's gallery once the capsule is made.
  bool get saveToGallery => _saveToGallery;

  @override
  void attach(String uid) {
    _uid = uid;
    unawaited(_load(uid));
  }

  Future<void> _load(String uid) async {
    try {
      final map = await _prefs.string(uid, _mapKey);
      final camera = await _prefs.string(uid, _cameraKey);
      final unit = await _prefs.string(uid, _unitKey);
      final quality = await _prefs.string(uid, _qualityKey);
      final gallery = await _prefs.string(uid, _galleryKey);
      final wifi = await _prefs.string(uid, _wifiKey);
      final nearby = await _prefs.string(uid, _nearbyKey);
      final country = await _prefs.string(uid, _countryKey);
      if (_uid != uid) return;
      _map = MapLook.parse(map);
      _camera = StartCamera.parse(camera);
      _unit = DistanceUnit.parse(unit);
      _quality = PhotoQuality.parse(quality);
      _saveToGallery = gallery == 'true';
      _wifiOnly = wifi == 'true';
      _nearbyAlerts = nearby == 'true';
      _countryAlerts = country == 'true';
      notifyListeners();
      if (_nearbyAlerts || _countryAlerts) {
        unawaited(BackgroundPlaces().schedule());
      }
    } catch (e, st) {
      AppLogger.warning(
        'Loading device settings failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  void detach() {
    _uid = null;
    _map = MapLook.standard;
    _camera = StartCamera.back;
    _unit = DistanceUnit.kilometres;
    _quality = PhotoQuality.standard;
    _saveToGallery = false;
    _wifiOnly = false;
    _nearbyAlerts = false;
    _countryAlerts = false;
    notifyListeners();
  }

  @override
  Future<void> beforeSignOut(String uid) async {}

  Future<void> setMapLook(MapLook value) async {
    final uid = _uid;
    if (uid == null || value == _map) return;
    _map = value;
    notifyListeners();
    await _prefs.setString(uid, _mapKey, value.name);
  }

  Future<void> setStartCamera(StartCamera value) async {
    final uid = _uid;
    if (uid == null || value == _camera) return;
    _camera = value;
    notifyListeners();
    await _prefs.setString(uid, _cameraKey, value.name);
  }

  Future<void> setDistanceUnit(DistanceUnit value) async {
    final uid = _uid;
    if (uid == null || value == _unit) return;
    _unit = value;
    notifyListeners();
    await _prefs.setString(uid, _unitKey, value.name);
  }

  Future<void> setPhotoQuality(PhotoQuality value) async {
    final uid = _uid;
    if (uid == null || value == _quality) return;
    _quality = value;
    notifyListeners();
    await _prefs.setString(uid, _qualityKey, value.name);
  }

  /// The Wi-Fi only switch of [uid], read without a store (the background
  /// upload job runs without the app).
  static Future<bool> readUploadsWifiOnly(
    PreferencesStore prefs,
    String uid,
  ) async => await prefs.string(uid, _wifiKey) == 'true';

  Future<void> setUploadsWifiOnly(bool value) async {
    final uid = _uid;
    if (uid == null || value == _wifiOnly) return;
    _wifiOnly = value;
    notifyListeners();
    await _prefs.setString(uid, _wifiKey, '$value');
  }

  /// The place alerts' switches of [uid], read without a store (the
  /// background check runs without the app).
  static Future<({bool nearby, bool country})> readPlaceAlerts(
    PreferencesStore prefs,
    String uid,
  ) async => (
    nearby: await prefs.string(uid, _nearbyKey) == 'true',
    country: await prefs.string(uid, _countryKey) == 'true',
  );

  Future<void> setNearbyAlerts(bool value) async {
    final uid = _uid;
    if (uid == null || value == _nearbyAlerts) return;
    _nearbyAlerts = value;
    notifyListeners();
    await _prefs.setString(uid, _nearbyKey, '$value');
  }

  Future<void> setCountryAlerts(bool value) async {
    final uid = _uid;
    if (uid == null || value == _countryAlerts) return;
    _countryAlerts = value;
    notifyListeners();
    await _prefs.setString(uid, _countryKey, '$value');
  }

  Future<void> setSaveToGallery(bool value) async {
    final uid = _uid;
    if (uid == null || value == _saveToGallery) return;
    _saveToGallery = value;
    notifyListeners();
    await _prefs.setString(uid, _galleryKey, '$value');
  }
}
