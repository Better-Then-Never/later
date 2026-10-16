import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_localizations.dart';

export '../../l10n/gen/app_localizations.dart';

extension L10nX on BuildContext {
  /// The messages of the current language (English, Russian, Polish, German,
  /// Spanish). Every user-visible string goes through here.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Messages for code without a BuildContext (failure messages, labels made in
/// controllers and repositories). `LaterApp` keeps it on the app's language;
/// widgets use `context.l10n`.
abstract final class AppL10n {
  static AppLocalizations _current = lookupAppLocalizations(const Locale('en'));

  static AppLocalizations get current => _current;

  static void update(Locale locale) {
    if (_current.localeName == locale.languageCode) return;
    try {
      _current = lookupAppLocalizations(locale);
    } on FlutterError {
      _current = lookupAppLocalizations(const Locale('en'));
    }
  }
}
