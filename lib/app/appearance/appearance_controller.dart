import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/services/preferences_store.dart';

/// How big the whole interface is drawn (Settings > Appearance).
enum UiSize {
  small(0.9),
  standard(1.0),
  large(1.12);

  const UiSize(this.scale);

  /// Multiplier for everything on screen (see `UiScaleView`).
  final double scale;

  static UiSize parse(String? value) =>
      values.firstWhere((v) => v.name == value, orElse: () => standard);
}

/// Theme, language and interface size of this device. Loaded before the first
/// frame (no flash of the wrong theme or language), saved on change.
class AppearanceController extends ChangeNotifier {
  AppearanceController(this._prefs);

  final PreferencesStore _prefs;

  static const supportedLanguages = ['en', 'ru', 'pl', 'de', 'es'];

  /// Each language in its own name (never translated).
  static const languageNames = {
    'en': 'English',
    'ru': 'Русский',
    'pl': 'Polski',
    'de': 'Deutsch',
    'es': 'Español',
  };

  static const _themeKey = 'theme_mode';
  static const _languageKey = 'language';
  static const _uiSizeKey = 'ui_size';

  ThemeMode _themeMode = ThemeMode.system;
  String? _language;
  UiSize _uiSize = UiSize.standard;

  ThemeMode get themeMode => _themeMode;

  /// The chosen language code, or null to follow the phone.
  String? get language => _language;

  /// What [MaterialApp.locale] should be (null follows the phone).
  Locale? get locale => _language == null ? null : Locale(_language!);
  UiSize get uiSize => _uiSize;

  /// Called just before the theme, language or size changes, while the old
  /// look is still on screen (`AppearanceCrossfade` takes its picture).
  VoidCallback? willChange;

  Future<void> load() async {
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == _prefs.deviceStringSync(_themeKey),
      orElse: () => ThemeMode.system,
    );
    final language = _prefs.deviceStringSync(_languageKey);
    _language = supportedLanguages.contains(language) ? language : null;
    _uiSize = UiSize.parse(_prefs.deviceStringSync(_uiSizeKey));
    _tellLaunchScreen();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    willChange?.call();
    _themeMode = mode;
    notifyListeners();
    _tellLaunchScreen();
    await _prefs.setDeviceString(_themeKey, mode.name);
  }

  /// The phone's launch screen follows the system's light or dark, not the
  /// app's: Android 12+ is told the app's choice, so a start in a theme
  /// other than the phone's never flashes the other colour.
  void _tellLaunchScreen() => unawaited(
    _launch.invokeMethod<void>('nightMode', _themeMode.name).catchError((
      Object _,
    ) {
      // Tests, iOS, older Android: nothing to tell.
    }),
  );

  static const _launch = MethodChannel('later.app/startup');

  /// [code] null follows the phone's language.
  Future<void> setLanguage(String? code) async {
    final next = supportedLanguages.contains(code) ? code : null;
    if (next == _language) return;
    willChange?.call();
    _language = next;
    notifyListeners();
    await _prefs.setDeviceString(_languageKey, next);
  }

  Future<void> setUiSize(UiSize size) async {
    if (size == _uiSize) return;
    willChange?.call();
    _uiSize = size;
    notifyListeners();
    await _prefs.setDeviceString(_uiSizeKey, size.name);
  }

  /// The language the app shows: the chosen one, else the phone's if
  /// supported, else English.
  static String resolve(String? chosen, Locale device) {
    if (chosen != null) return chosen;
    return supportedLanguages.contains(device.languageCode)
        ? device.languageCode
        : 'en';
  }
}
