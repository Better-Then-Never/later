import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../core/session/session_scoped.dart';
import '../../data/services/preferences_store.dart';

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

  String? _uid;
  MapLook _map = MapLook.standard;
  StartCamera _camera = StartCamera.back;
  DistanceUnit _unit = DistanceUnit.kilometres;
  PhotoQuality _quality = PhotoQuality.standard;
  bool _saveToGallery = false;

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
      if (_uid != uid) return;
      _map = MapLook.parse(map);
      _camera = StartCamera.parse(camera);
      _unit = DistanceUnit.parse(unit);
      _quality = PhotoQuality.parse(quality);
      _saveToGallery = gallery == 'true';
      notifyListeners();
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

  Future<void> setSaveToGallery(bool value) async {
    final uid = _uid;
    if (uid == null || value == _saveToGallery) return;
    _saveToGallery = value;
    notifyListeners();
    await _prefs.setString(uid, _galleryKey, '$value');
  }
}
