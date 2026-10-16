import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/logging/app_logger.dart';
import '../../core/session/session_scoped.dart';
import '../../data/services/preferences_store.dart';

/// How the map draws the world.
enum MapLook {
  standard('Standard'),
  satellite('Satellite'),
  hybrid('Satellite with labels');

  const MapLook(this.label);
  final String label;

  static MapLook parse(String? value) =>
      values.firstWhere((v) => v.name == value, orElse: () => standard);
}

/// Which camera the capsule camera opens with.
enum StartCamera {
  back('Back camera'),
  front('Front camera');

  const StartCamera(this.label);
  final String label;

  static StartCamera parse(String? value) =>
      values.firstWhere((v) => v.name == value, orElse: () => back);
}

/// Preferences of this device for the signed-in user (map look, starting
/// camera). Kept on the device: they describe how this phone behaves, not
/// the account.
class DeviceSettingsStore extends ChangeNotifier implements SessionScoped {
  DeviceSettingsStore(this._prefs);

  final PreferencesStore _prefs;

  static const _mapKey = 'map_look';
  static const _cameraKey = 'start_camera';

  String? _uid;
  MapLook _map = MapLook.standard;
  StartCamera _camera = StartCamera.back;

  MapLook get mapLook => _map;
  StartCamera get startCamera => _camera;

  @override
  void attach(String uid) {
    _uid = uid;
    unawaited(_load(uid));
  }

  Future<void> _load(String uid) async {
    try {
      final map = await _prefs.string(uid, _mapKey);
      final camera = await _prefs.string(uid, _cameraKey);
      if (_uid != uid) return;
      _map = MapLook.parse(map);
      _camera = StartCamera.parse(camera);
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
}
