import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:snow_fall_animation/snow_fall_animation.dart';

import '../core/l10n/l10n.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/themed_asset_bundle.dart';
import '../features/settings/settings_store.dart';
import 'appearance/appearance_controller.dart';
import 'appearance/ui_scale_view.dart';
import 'router/app_routes.dart';
import 'session/auth_gate.dart';

/// Snow falls from December 31st through the end of February.
bool isSnowSeason(DateTime now) =>
    (now.month == 12 && now.day >= 31) || now.month == 1 || now.month == 2;

/// System bars over the app: transparent, icons dark on light pages and light
/// on dark ones. Screens over photos set their own region.
SystemUiOverlayStyle systemBarsFor(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
    statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: brightness,
    systemNavigationBarIconBrightness: dark
        ? Brightness.light
        : Brightness.dark,
  );
}

class LaterApp extends StatelessWidget {
  const LaterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final snow = isSnowSeason(DateTime.now());
    final appearance = context.watch<AppearanceController>();
    return MaterialApp(
      navigatorKey: AppRoutes.navigatorKey,
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: appearance.themeMode,
      // Switching theme crossfades every colour (AppPalette.lerp).
      themeAnimationDuration: AppMotion.slow,
      themeAnimationCurve: AppMotion.standardCurve,
      locale: appearance.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) {
        final locale = Localizations.localeOf(context);
        AppL10n.update(locale);
        // Pushes are written by the server in the language the app shows.
        context.read<SettingsStore>().syncLanguage(locale.languageCode);
        final brightness = Theme.of(context).brightness;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemBarsFor(brightness),
          child: ThemedAssets(
            dark: brightness == Brightness.dark,
            child: UiScaleView(
              scale: appearance.uiSize.scale,
              // Seasonal snowfall drawn over every screen (part of the design).
              child: Stack(
                children: [
                  child ?? const SizedBox(),
                  if (snow)
                    const IgnorePointer(
                      child: SnowFallAnimation(
                        config: SnowfallConfig(
                          numberOfSnowflakes: 15,
                          speed: 0.5,
                          useEmoji: true,
                          customEmojis: ['❄️', '❅', '❆'],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      home: const AuthGate(),
    );
  }
}
