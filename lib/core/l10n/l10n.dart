import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_localizations.dart';

export '../../l10n/gen/app_localizations.dart';

extension L10nX on BuildContext {
  /// The messages of the current language (English, Russian, Polish, German,
  /// Spanish). Every user-visible string goes through here.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
