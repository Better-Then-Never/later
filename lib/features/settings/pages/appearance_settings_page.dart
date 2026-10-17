import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/appearance/appearance_controller.dart';
import '../../../core/l10n/l10n.dart';
import '../../../shared/widgets/options/options_section.dart';
import '../widgets/settings_scaffold.dart';

/// Theme and interface size of this phone. Changes apply at once: the theme
/// crossfades, the size rescales the whole app.
class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  static String themeName(AppLocalizations l10n, ThemeMode mode) =>
      switch (mode) {
        ThemeMode.system => l10n.settingsThemeSystem,
        ThemeMode.light => l10n.settingsThemeLight,
        ThemeMode.dark => l10n.settingsThemeDark,
      };

  static String sizeName(AppLocalizations l10n, UiSize size) => switch (size) {
    UiSize.small => l10n.settingsSizeSmall,
    UiSize.standard => l10n.settingsSizeStandard,
    UiSize.large => l10n.settingsSizeLarge,
  };

  @override
  Widget build(BuildContext context) {
    final appearance = context.watch<AppearanceController>();
    final l10n = context.l10n;
    const modes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
    return SettingsScaffold(
      title: l10n.settingsAppearance,
      description: l10n.settingsAppearanceDescription,
      children: [
        OptionsSection(
          title: l10n.settingsSectionTheme,
          children: [
            for (final mode in modes)
              SettingsChoiceRow(
                title: themeName(l10n, mode),
                selected: appearance.themeMode == mode,
                withDivider: mode != modes.last,
                onTap: () => appearance.setThemeMode(mode),
              ),
          ],
        ),
        OptionsSection(
          title: l10n.settingsSectionSize,
          footer: l10n.settingsSizeFooter,
          children: [
            for (final size in UiSize.values)
              SettingsChoiceRow(
                title: sizeName(l10n, size),
                selected: appearance.uiSize == size,
                withDivider: size != UiSize.values.last,
                onTap: () => appearance.setUiSize(size),
              ),
          ],
        ),
      ],
    );
  }
}

/// The app's language, or the phone's. Pushes follow it (the choice is saved
/// to the account by `SettingsStore.syncLanguage`).
class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  /// What the language row shows: the chosen language in its own name.
  static String currentName(BuildContext context) {
    final code = AppearanceController.resolve(
      context.read<AppearanceController>().language,
      WidgetsBinding.instance.platformDispatcher.locale,
    );
    return AppearanceController.languageNames[code] ?? code;
  }

  @override
  Widget build(BuildContext context) {
    final appearance = context.watch<AppearanceController>();
    final l10n = context.l10n;
    final phone = AppearanceController.resolve(
      null,
      WidgetsBinding.instance.platformDispatcher.locale,
    );
    const codes = AppearanceController.supportedLanguages;
    return SettingsScaffold(
      title: l10n.settingsLanguage,
      description: l10n.settingsLanguageDescription,
      children: [
        OptionsSection(
          footer: l10n.settingsLanguageFooter,
          children: [
            SettingsChoiceRow(
              title: l10n.settingsLanguageSystem,
              subtitle: l10n.settingsLanguageSystemHint(
                AppearanceController.languageNames[phone] ?? phone,
              ),
              selected: appearance.language == null,
              onTap: () => appearance.setLanguage(null),
            ),
            for (final code in codes)
              SettingsChoiceRow(
                title: AppearanceController.languageNames[code]!,
                selected: appearance.language == code,
                withDivider: code != codes.last,
                onTap: () => appearance.setLanguage(code),
              ),
          ],
        ),
      ],
    );
  }
}
