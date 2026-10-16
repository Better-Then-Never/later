// Frame timings of the key flows, for docs/ux/PERFORMANCE.md.
//
// Run in profile mode on a device or emulator, against the local Firebase
// emulators (seeded with tools/emulator/seed.js):
//
//   flutter drive --profile --driver=test_driver/perf_driver.dart \
//     --target=integration_test/perf_test.dart \
//     --dart-define=USE_FIREBASE_EMULATOR=true
//
// Each flow is recorded with traceAction; the driver writes
// build/<flow>.timeline_summary.json (build and raster times per frame).
// The account comes from TEST_ACCOUNT_EMAIL / TEST_ACCOUNT_PASSWORD
// (--dart-define), defaulting to the seeded emulator account.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:later/app/bootstrap.dart';
import 'package:later/app/shell/navbar_widget.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:later/features/messages/widgets/chat_list_item.dart';

const _email = String.fromEnvironment(
  'TEST_ACCOUNT_EMAIL',
  defaultValue: 'alice@later.test',
);
const _password = String.fromEnvironment(
  'TEST_ACCOUNT_PASSWORD',
  defaultValue: 'emulator-only-123',
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  /// Real time passes with frames pumped (pumpAndSettle never settles on
  /// screens with endless animations such as the loading logo).
  Future<void> wait(WidgetTester tester, Duration duration) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Finder icon(String asset) => find.image(AssetImage(asset));

  Future<void> tapAndWait(
    WidgetTester tester,
    Finder finder, [
    Duration duration = const Duration(milliseconds: 1200),
  ]) async {
    await tester.tap(finder.first, warnIfMissed: false);
    await wait(tester, duration);
  }

  Future<void> back(WidgetTester tester) async {
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pop();
    await wait(tester, const Duration(milliseconds: 900));
  }

  testWidgets('key flows', (tester) async {
    final launch = Stopwatch()..start();
    // bootstrap() installs the app's error handler; keep the test's, so a
    // failure fails the run instead of only being logged.
    final testErrorHandler = FlutterError.onError;
    await binding.traceAction(() async {
      await bootstrap();
      FlutterError.onError = testErrorHandler;
      final navbar = find.byType(NavbarWidget);
      final signedOut = find.text('Get Started');
      final login = find.text('Log In Now');
      final end = DateTime.now().add(const Duration(seconds: 40));
      while (navbar.evaluate().isEmpty) {
        if (DateTime.now().isAfter(end)) {
          final texts = find
              .byType(Text)
              .evaluate()
              .map((e) => (e.widget as Text).data)
              .whereType<String>()
              .take(20)
              .join(' | ');
          throw TestFailure('no home screen; showing: $texts');
        }
        if (signedOut.evaluate().isNotEmpty || login.evaluate().isNotEmpty) {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _email,
            password: _password,
          );
        }
        await tester.pump(const Duration(milliseconds: 50));
      }
      launch.stop();
      await wait(tester, const Duration(seconds: 3));
    }, reportKey: 'startup');
    binding.reportData ??= {};
    binding.reportData!['startup_ms_to_home'] = launch.elapsedMilliseconds;

    await binding.traceAction(() async {
      for (final asset in [
        AppIcons.navbarHistory,
        AppIcons.navbarMessages,
        AppIcons.navbarProfile,
        AppIcons.navbarMap,
        AppIcons.navbarProfile,
        AppIcons.navbarHistory,
      ]) {
        await tapAndWait(tester, icon(asset));
      }
    }, reportKey: 'tab_switches');

    // History is open: scroll My capsules to the end and back.
    await binding.traceAction(() async {
      final list = find.byType(Scrollable).first;
      for (var i = 0; i < 3; i++) {
        await tester.fling(list, const Offset(0, -900), 2500);
        await wait(tester, const Duration(milliseconds: 900));
      }
      for (var i = 0; i < 3; i++) {
        await tester.fling(list, const Offset(0, 900), 2500);
        await wait(tester, const Duration(milliseconds: 900));
      }
    }, reportKey: 'history_scroll');

    await tapAndWait(tester, icon(AppIcons.navbarProfile));
    await binding.traceAction(() async {
      await tapAndWait(tester, icon(AppIcons.settings));
      await back(tester);
    }, reportKey: 'settings_open_close');

    await binding.traceAction(() async {
      await tapAndWait(tester, find.text('Add friends'));
      await back(tester);
    }, reportKey: 'add_friends_transition');

    await binding.traceAction(() async {
      await tapAndWait(tester, icon(AppIcons.notifications));
      for (final tab in ['Replies', 'Comments', 'All']) {
        await tapAndWait(
          tester,
          find.text(tab),
          const Duration(milliseconds: 700),
        );
      }
      await back(tester);
    }, reportKey: 'notifications_tabs');

    await tapAndWait(tester, icon(AppIcons.navbarMessages));
    await binding.traceAction(() async {
      final chatRow = find.byType(ChatListItem);
      if (chatRow.evaluate().isNotEmpty) {
        await tapAndWait(tester, chatRow, const Duration(milliseconds: 1800));
        await back(tester);
      }
    }, reportKey: 'open_chat');

    await tapAndWait(
      tester,
      icon(AppIcons.navbarMap),
      const Duration(seconds: 3),
    );
    await binding.traceAction(() async {
      final center = tester.getCenter(find.byType(Scaffold).first);
      for (var i = 0; i < 4; i++) {
        await tester.dragFrom(center, const Offset(-250, 120));
        await wait(tester, const Duration(milliseconds: 700));
        await tester.dragFrom(center, const Offset(250, -120));
        await wait(tester, const Duration(milliseconds: 700));
      }
    }, reportKey: 'map_pan');

    await binding.traceAction(() async {
      await tapAndWait(
        tester,
        icon(AppIcons.navbarAdd),
        const Duration(seconds: 3),
      );
      await back(tester);
    }, reportKey: 'camera_open_close');
  });
}
