import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/appearance/appearance_controller.dart';
import 'package:later/app/appearance/appearance_crossfade.dart';
import 'package:later/core/theme/app_motion.dart';
import 'package:later/core/theme/app_theme.dart';
import 'package:later/data/services/preferences_store.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppearanceController appearance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesStore();
    await prefs.init();
    appearance = AppearanceController(prefs);
    await appearance.load();
  });

  /// The app's shape: the crossfade inside MaterialApp's builder, the theme
  /// following the controller.
  Widget app({bool reduceMotion = false}) =>
      ChangeNotifierProvider<AppearanceController>.value(
        value: appearance,
        child: Consumer<AppearanceController>(
          builder: (context, appearance, _) => MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: appearance.themeMode,
            themeAnimationDuration: Duration.zero,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: reduceMotion),
              child: AppearanceCrossfade(child: child!),
            ),
            home: const Scaffold(body: Center(child: Text('Later'))),
          ),
        ),
      );

  Finder still() => find.descendant(
    of: find.byType(AppearanceCrossfade),
    matching: find.byType(RawImage),
  );

  testWidgets('a theme switch fades a still of the old look', (tester) async {
    await tester.pumpWidget(app());
    unawaited(appearance.setThemeMode(ThemeMode.dark));
    await tester.pump();
    expect(still(), findsOneWidget);
    // The new theme is already underneath.
    expect(
      Theme.of(tester.element(find.text('Later'))).brightness,
      Brightness.dark,
    );
    await tester.pump(AppMotion.slow ~/ 2);
    expect(still(), findsOneWidget);
    await tester.pump(AppMotion.slow);
    expect(still(), findsNothing);
  });

  testWidgets('with reduced motion the switch is instant', (tester) async {
    await tester.pumpWidget(app(reduceMotion: true));
    unawaited(appearance.setThemeMode(ThemeMode.dark));
    await tester.pump();
    expect(still(), findsNothing);
  });

  testWidgets('language and size changes fade too', (tester) async {
    await tester.pumpWidget(app());
    unawaited(appearance.setUiSize(UiSize.large));
    await tester.pump();
    expect(still(), findsOneWidget);
    await tester.pump(AppMotion.slow * 2);
    unawaited(appearance.setLanguage('ru'));
    await tester.pump();
    expect(still(), findsOneWidget);
    await tester.pump(AppMotion.slow * 2);
  });
}
