import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/shared/widgets/popup/popup_notification_service.dart';

void main() {
  testWidgets('a toast shows from the root navigator\'s own context', (
    tester,
  ) async {
    // What a card does after it closed itself: only the navigator is left.
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(),
      ),
    );
    PopupNotificationService.showSuccess(
      context: navigatorKey.currentContext!,
      message: 'Sent to Anna',
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Sent to Anna'), findsOneWidget);
    PopupNotificationService.hide();
    await tester.pump();
  });
}
