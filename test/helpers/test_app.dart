import 'package:flutter/material.dart';
import 'package:later/core/l10n/l10n.dart';

/// A MaterialApp for widget tests with the app's localizations (English
/// unless [locale] says otherwise). Pass [theme] to test the app themes;
/// without it the palette falls back to the light values.
MaterialApp testApp({
  required Widget home,
  Locale locale = const Locale('en'),
  ThemeData? theme,
}) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  theme: theme,
  home: home,
);
