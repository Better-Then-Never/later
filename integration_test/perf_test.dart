// Frame timings of the key flows, for docs/feel/PERFORMANCE.md.
//
// Run in profile mode on the phone, against the local Firebase emulators
// seeded with tool/seed_heavy.js (docs/feel/RIG.md):
//
//   tool/dev/perf.sh <label> [runs]
//
// which runs
//
//   flutter drive --profile --no-dds --driver=test_driver/perf_driver.dart \
//     --target=integration_test/perf_test.dart \
//     --dart-define=USE_FIREBASE_EMULATOR=true \
//     --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1
//
// Each flow is recorded with traceAction; the driver writes
// build/<flow>.timeline_summary.json (build and raster times per frame) and
// turns the PerfMarks after each `later.tap` into durations
// (build/perf_numbers.json). --dart-define=PERF_FLOWS=a,b runs only those
// flows (startup always runs). Labels come from the app's own translations,
// so the phone's language does not matter. The account comes from
// TEST_ACCOUNT_EMAIL / TEST_ACCOUNT_PASSWORD (--dart-define), defaulting to
// the seeded emulator account.
import 'dart:developer' show Timeline;
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:integration_test/integration_test.dart';
import 'package:later/app/appearance/appearance_controller.dart';
import 'package:later/app/bootstrap.dart';
import 'package:later/app/shell/navbar_widget.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/features/achievements/streak_pill.dart';
import 'package:later/features/capsules/creation/capsule_creation_page.dart';
import 'package:later/features/history/own_capsules_store.dart';
import 'package:later/features/map/map_focus.dart';
import 'package:later/features/map/map_stats.dart';
import 'package:later/features/map/widgets/capsule_preview_card.dart';
import 'package:later/features/map/widgets/map_compass.dart';
import 'package:later/features/messages/widgets/chat_list_item.dart';
import 'package:later/features/messages/widgets/message_bubble.dart';
import 'package:later/features/notifications/widgets/notifications_list.dart';
import 'package:provider/provider.dart';

const _email = String.fromEnvironment(
  'TEST_ACCOUNT_EMAIL',
  defaultValue: 'alice@later.test',
);
const _password = String.fromEnvironment(
  'TEST_ACCOUNT_PASSWORD',
  defaultValue: 'emulator-only-123',
);
const _only = String.fromEnvironment('PERF_FLOWS');

/// The app's language for the run ('' keeps it; e.g. en, ru).
const _language = String.fromEnvironment('PERF_LANG');

/// Where tool/seed_heavy.js put most capsules (its SEED_CENTER default).
const _seedLatitude = 52.2297;
const _seedLongitude = 21.0122;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  // An event per widget build, layout and paint in the timeline, to name
  // the cause of a slow frame (tool/dev/slow_frames.dart). Slows frames.
  if (const bool.fromEnvironment('PERF_DETAIL')) {
    debugProfileBuildsEnabled = true;
    debugProfileLayoutsEnabled = true;
    debugProfilePaintsEnabled = true;
  }

  /// Real time passes with frames pumped (pumpAndSettle never settles on
  /// screens with endless animations such as the loading logo).
  Future<void> wait(WidgetTester tester, Duration duration) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  /// Pumps frames until [finder] finds something; returns the milliseconds
  /// that took, or null after [timeout].
  Future<int?> waitFor(
    WidgetTester tester,
    Finder finder, [
    Duration timeout = const Duration(seconds: 10),
  ]) async {
    final watch = Stopwatch()..start();
    while (finder.evaluate().isEmpty) {
      if (watch.elapsed > timeout) return null;
      await tester.pump(const Duration(milliseconds: 4));
    }
    return watch.elapsedMilliseconds;
  }

  Finder icon(String asset) => find.image(AssetImage(asset));

  /// A control by its screen reader label, without building the semantics
  /// tree.
  Finder labelled(String label) => find.byWidgetPredicate(
    (w) => w is Semantics && w.properties.label == label,
  );
  AppLocalizations l10n() => AppL10n.current;

  Future<void> tap(WidgetTester tester, Finder finder) async {
    Timeline.instantSync('later.tap');
    await tester.tap(finder.first, warnIfMissed: false);
  }

  Future<void> tapAndWait(
    WidgetTester tester,
    Finder finder, [
    Duration duration = const Duration(milliseconds: 1200),
  ]) async {
    await tap(tester, finder);
    await wait(tester, duration);
  }

  NavigatorState rootNavigator(WidgetTester tester) =>
      tester.state<NavigatorState>(find.byType(Navigator).first);

  Future<void> back(WidgetTester tester) async {
    rootNavigator(tester).pop();
    await wait(tester, const Duration(milliseconds: 900));
  }

  /// Closes every page, sheet and dialog over the tabs.
  Future<void> home(WidgetTester tester) async {
    rootNavigator(tester).popUntil((route) => route.isFirst);
    await wait(tester, const Duration(milliseconds: 900));
  }

  Future<void> tab(WidgetTester tester, String asset) async {
    await home(tester);
    await tester.tap(icon(asset).first, warnIfMissed: false);
    await wait(tester, const Duration(milliseconds: 1500));
  }

  /// Two fingers moving from [from] to [to] pixels apart around [center].
  Future<void> pinch(
    WidgetTester tester,
    Offset center,
    double from,
    double to,
  ) async {
    final a = await tester.startGesture(center - Offset(from / 2, 0));
    final b = await tester.startGesture(center + Offset(from / 2, 0));
    const steps = 24;
    for (var i = 1; i <= steps; i++) {
      final d = from + (to - from) * i / steps;
      await a.moveTo(center - Offset(d / 2, 0));
      await b.moveTo(center + Offset(d / 2, 0));
      await tester.pump(const Duration(milliseconds: 12));
    }
    await a.up();
    await b.up();
    await wait(tester, const Duration(milliseconds: 900));
  }

  /// Two fingers turning the map by [degrees] (clockwise) around [center].
  Future<void> twist(WidgetTester tester, Offset center, double degrees) async {
    const radius = 150.0;
    Offset at(double angle) => center + Offset.fromDirection(angle, radius);
    final a = await tester.startGesture(at(0));
    final b = await tester.startGesture(at(math.pi));
    const steps = 24;
    for (var i = 1; i <= steps; i++) {
      final turn = degrees * math.pi / 180 * i / steps;
      await a.moveTo(at(turn));
      await b.moveTo(at(math.pi + turn));
      await tester.pump(const Duration(milliseconds: 12));
    }
    await a.up();
    await b.up();
    await wait(tester, const Duration(milliseconds: 900));
  }

  final measured = <String, List<int>>{};
  void record(String key, int? ms) {
    if (ms != null) measured.putIfAbsent(key, () => []).add(ms);
  }

  // Semantics off: the accessibility tree is built only for people using a
  // screen reader, and testWidgets would otherwise build it on every frame.
  testWidgets('key flows', semanticsEnabled: false, (tester) async {
    /// Runs [body] as the traced flow [name] when it was asked for, after
    /// [setup] (not traced).
    Future<void> flow(
      String name,
      Future<void> Function() body, {
      Future<void> Function()? setup,
    }) async {
      if (_only.isNotEmpty && !_only.split(',').contains(name)) return;
      if (setup != null) await setup();
      // Wall-clock time of the flow: a frozen app draws no frames (so no
      // janky ones either), but its flow takes far longer than its waits.
      final watch = Stopwatch()..start();
      await binding.traceAction(body, reportKey: name);
      record('${name}_wall_ms', watch.elapsedMilliseconds);
    }

    final launch = Stopwatch()..start();
    // bootstrap() installs the app's error handler; keep the test's, so a
    // failure fails the run instead of only being logged.
    final testErrorHandler = FlutterError.onError;
    await binding.traceAction(() async {
      await bootstrap();
      FlutterError.onError = testErrorHandler;
      // After a re-seed the account on the phone no longer exists: drop the
      // stale session now instead of being signed out mid-flow.
      try {
        await FirebaseAuth.instance.currentUser?.reload();
      } on FirebaseAuthException {
        await FirebaseAuth.instance.signOut();
      }
      final navbar = find.byType(NavbarWidget);
      final end = DateTime.now().add(const Duration(seconds: 40));
      var signingIn = false;
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
        if (!signingIn && FirebaseAuth.instance.currentUser == null) {
          signingIn = true;
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _email,
            password: _password,
          );
        }
        // The optional permission steps of a fresh install.
        final notNow = find.text(l10n().authPermissionNotNow);
        if (notNow.evaluate().isNotEmpty) {
          await tester.tap(notNow.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 500));
        }
        await tester.pump(const Duration(milliseconds: 50));
      }
      launch.stop();
      await wait(tester, const Duration(seconds: 3));
    }, reportKey: 'startup');
    binding.reportData ??= {};
    binding.reportData!['startup_ms_to_home'] = launch.elapsedMilliseconds;
    if (_language.isNotEmpty) {
      await tester
          .element(find.byType(NavbarWidget))
          .read<AppearanceController>()
          .setLanguage(_language);
      await wait(tester, const Duration(seconds: 2));
    }

    await flow('tab_switches', () async {
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
    });

    // My capsules (about a hundred): to the end, past it, and back.
    await flow(
      'history_scroll',
      setup: () => tab(tester, AppIcons.navbarHistory),
      () async {
        final list = find.byType(Scrollable).first;
        for (var i = 0; i < 6; i++) {
          await tester.fling(list, const Offset(0, -900), 3000);
          await wait(tester, const Duration(milliseconds: 700));
        }
        for (var i = 0; i < 6; i++) {
          await tester.fling(list, const Offset(0, 900), 3000);
          await wait(tester, const Duration(milliseconds: 700));
        }
      },
    );

    await flow(
      'settings_open_close',
      setup: () => tab(tester, AppIcons.navbarProfile),
      () async {
        await tapAndWait(tester, icon(AppIcons.settings));
        await back(tester);
      },
    );

    await flow(
      'theme_switch',
      setup: () async {
        await tab(tester, AppIcons.navbarProfile);
        await tapAndWait(tester, icon(AppIcons.settings));
        await tapAndWait(tester, find.text(l10n().settingsAppearance));
      },
      () async {
        for (final mode in [
          l10n().settingsThemeDark,
          l10n().settingsThemeLight,
          l10n().settingsThemeSystem,
        ]) {
          await tapAndWait(
            tester,
            find.text(mode),
            const Duration(milliseconds: 1500),
          );
        }
      },
    );

    await flow(
      'add_friends_transition',
      setup: () => tab(tester, AppIcons.navbarProfile),
      () async {
        await tapAndWait(tester, find.text(l10n().profileAddFriends));
        await back(tester);
      },
    );

    await flow(
      'notifications_tabs',
      setup: () => tab(tester, AppIcons.navbarProfile),
      () async {
        await tapAndWait(tester, icon(AppIcons.notifications));
        for (final label in [
          l10n().notificationsTabReplies,
          l10n().notificationsTabComments,
          l10n().notificationsTabAll,
        ]) {
          await tapAndWait(
            tester,
            find.text(label),
            const Duration(milliseconds: 700),
          );
        }
        await back(tester);
      },
    );

    // The 600-message chat is the newest, so it is the first row.
    await flow(
      'chat_open',
      setup: () => tab(tester, AppIcons.navbarMessages),
      () async {
        for (var i = 0; i < 3; i++) {
          final watch = Stopwatch()..start();
          await tap(tester, find.byType(ChatListItem));
          await waitFor(tester, find.byType(MessageBubble));
          record('chat_open_test_ms', watch.elapsedMilliseconds);
          await wait(tester, const Duration(milliseconds: 1500));
          await back(tester);
        }
      },
    );

    await flow(
      'chat_scroll',
      setup: () async {
        await tab(tester, AppIcons.navbarMessages);
        await tapAndWait(tester, find.byType(ChatListItem));
      },
      () async {
        final list = find.byType(Scrollable).last;
        // The list is reversed: dragging down goes back in time.
        for (var i = 0; i < 8; i++) {
          await tester.fling(list, const Offset(0, 900), 3000);
          await wait(tester, const Duration(milliseconds: 700));
        }
        for (var i = 0; i < 8; i++) {
          await tester.fling(list, const Offset(0, -900), 3000);
          await wait(tester, const Duration(milliseconds: 700));
        }
      },
    );

    await flow(
      'chat_options_sheet',
      setup: () async {
        await tab(tester, AppIcons.navbarMessages);
        await tapAndWait(tester, find.byType(ChatListItem));
      },
      () async {
        for (var i = 0; i < 2; i++) {
          await tapAndWait(tester, labelled(l10n().messagesChatOptions));
          await back(tester);
        }
      },
    );

    // Part B screens (FEATURES_B.md): the profile (B3), the notifications
    // with days and the team's news (B6), the passport (B7).
    await flow(
      'profile_scroll',
      setup: () => tab(tester, AppIcons.navbarProfile),
      () async {
        final page = find.byType(Scrollable).first;
        for (final dy in [-900.0, -900.0, 900.0, 900.0]) {
          await tester.fling(page, Offset(0, dy), 3000);
          await wait(tester, const Duration(milliseconds: 700));
        }
      },
    );

    await flow(
      'notifications_scroll',
      setup: () async {
        await tab(tester, AppIcons.navbarProfile);
        await tapAndWait(tester, icon(AppIcons.notifications));
      },
      () async {
        final list = find
            .descendant(
              of: find.byType(NotificationsList).first,
              matching: find.byType(Scrollable),
            )
            .first;
        for (var i = 0; i < 4; i++) {
          await tester.fling(list, const Offset(0, -900), 3000);
          await wait(tester, const Duration(milliseconds: 700));
        }
        for (var i = 0; i < 4; i++) {
          await tester.fling(list, const Offset(0, 900), 3000);
          await wait(tester, const Duration(milliseconds: 700));
        }
      },
    );

    await flow(
      'passport_open_scroll',
      setup: () => tab(tester, AppIcons.navbarProfile),
      () async {
        await tapAndWait(tester, find.text(l10n().worldTitle));
        final grid = find.byType(CustomScrollView).last;
        for (final dy in [-900.0, -900.0, 900.0, 900.0]) {
          await tester.fling(grid, Offset(0, dy), 3000);
          await wait(tester, const Duration(milliseconds: 700));
        }
        await back(tester);
      },
    );

    // The map's own sheets (B5, B7): the filter and the streak card.
    await flow(
      'map_filter_sheet',
      setup: () => tab(tester, AppIcons.navbarMap),
      () async {
        for (var i = 0; i < 2; i++) {
          await tapAndWait(tester, icon(AppIcons.historyFilter));
          await back(tester);
        }
      },
    );

    await flow(
      'streak_card',
      setup: () => tab(tester, AppIcons.navbarMap),
      () async {
        for (var i = 0; i < 2; i++) {
          await tapAndWait(tester, find.byType(StreakPill));
          await back(tester);
        }
      },
    );

    // The map: fly to one of the account's opened capsules where the seed
    // put most of them, open its dialog and photo, then zoom out across the
    // marker threshold (heatmap) and back, panning at both levels.
    final mapFlows = [
      'map_focus',
      'capsule_dialog',
      'photo_viewer',
      'map_zoom_out',
      'map_pan_heatmap',
      'map_zoom_in',
      'map_pan_markers',
      'map_compass',
      'map_pinch_sweep',
      'map_pinch_wave',
      'map_tap_zoom',
      'map_flash_slow',
      'map_flash_normal',
      'map_flash_fast',
      'map_flash_select',
    ];
    if (_only.isEmpty || mapFlows.any(_only.split(',').contains)) {
      await tab(tester, AppIcons.navbarMap);
      await wait(tester, const Duration(seconds: 2));
      final context = tester.element(find.byType(NavbarWidget));
      final now = DateTime.now();
      final own = context.read<OwnCapsulesStore>().capsules.where(
        (c) =>
            c.isOpen(now) &&
            c.location != null &&
            (c.location!.latitude - _seedLatitude).abs() < 0.3 &&
            (c.location!.longitude - _seedLongitude).abs() < 0.5,
      );
      final capsule = own.isEmpty ? null : own.first;
      final center = tester.getCenter(find.byType(Scaffold).first);

      /// The capsule's card, focused first when map_focus did not run.
      Future<void> card() async {
        if (find.text(l10n().mapCapsuleOpen).evaluate().isNotEmpty) return;
        if (capsule != null) context.read<MapFocus>().focus(capsule);
        await wait(tester, const Duration(seconds: 3));
      }

      await flow('map_focus', () async {
        if (capsule != null) context.read<MapFocus>().focus(capsule);
        await wait(tester, const Duration(seconds: 3));
      });
      await flow('capsule_dialog', setup: card, () async {
        await tapAndWait(tester, find.text(l10n().mapCapsuleOpen));
        await back(tester);
      });
      await flow(
        'photo_viewer',
        setup: () async {
          await card();
          await tapAndWait(tester, find.text(l10n().mapCapsuleOpen));
        },
        () async {
          await tapAndWait(
            tester,
            find.descendant(
              of: find.byType(CapsulePreviewCard),
              matching: find.byType(GestureDetector),
            ),
          );
          await back(tester);
        },
      );
      await home(tester);
      await flow('map_zoom_out', () async {
        for (var i = 0; i < 4; i++) {
          await pinch(tester, center, 600, 150);
        }
      });
      await flow('map_pan_heatmap', () async {
        for (var i = 0; i < 3; i++) {
          await tester.dragFrom(center, const Offset(-250, 120));
          await wait(tester, const Duration(milliseconds: 700));
          await tester.dragFrom(center, const Offset(250, -120));
          await wait(tester, const Duration(milliseconds: 700));
        }
      });
      await flow('map_zoom_in', () async {
        for (var i = 0; i < 2; i++) {
          await pinch(tester, center, 150, 600);
        }
      });
      await flow('map_pan_markers', () async {
        for (var i = 0; i < 3; i++) {
          await tester.dragFrom(center, const Offset(-250, 120));
          await wait(tester, const Duration(milliseconds: 700));
          await tester.dragFrom(center, const Offset(250, -120));
          await wait(tester, const Duration(milliseconds: 700));
        }
      });
      // Two fingers turn the map, the compass shows; a tap on it turns the
      // map back to north. Recorded: the map's bearing after each, in degrees.
      /// The gesture as real touches: tool/dev/map_gesture.sh reads this line
      /// and plays it on the phone with tool/dev/touch/Pinch.java (Android's
      /// own injection, as a hand's touches arrive); the test only waits.
      /// Synthetic test events reached Google Maps but not every native map
      /// (MapLibre missed some), so both maps get the same real fingers.
      /// [distances] are dp; the line is in screen pixels.
      /// Real touches: tool/dev/map_gesture.sh hands [args] as they are to
      /// the injector (tool/dev/touch/Pinch.java), which takes [ms].
      Future<void> playFingers(String args, int ms) async {
        // ignore: avoid_print
        print('MAPFINGERS $args');
        // A test drops the device's own touches unless told to pass them on.
        binding.shouldPropagateDevicePointerEvents = true;
        await wait(tester, Duration(milliseconds: ms + 1500));
        binding.shouldPropagateDevicePointerEvents = false;
      }

      Future<void> realFingers(List<List<double>> gestures, int msPer) async {
        final ratio = tester.view.devicePixelRatio;
        final c = center * ratio;
        final parts = <String>[];
        var total = 0;
        for (final g in gestures) {
          if (parts.isNotEmpty) parts.add('/ 350');
          parts.add(g.map((d) => (d * ratio).round()).join(' '));
          total += (g.length - 1) * msPer + 350;
        }
        await playFingers(
          '${c.dx.round()} ${c.dy.round()} $msPer ${parts.join(' ')}',
          total,
        );
      }

      /// The same view for every run: the seed's city at [zoom].
      Future<void> start(double zoom) async {
        await MapStats.instance.moveCamera?.call(
          const LatLng(_seedLatitude, _seedLongitude),
          zoom,
        );
        await wait(tester, const Duration(seconds: 3));
        MapStats.instance.reset();
        // For tool/dev/map_gesture.sh, which starts recording the screen.
        // ignore: avoid_print
        print('MAPFLOW_START');
        await wait(tester, const Duration(milliseconds: 1500));
      }

      void stats(String name) {
        // ignore: avoid_print
        print('MAPFLOW_END');
        MapStats.instance.total.toJson().forEach(
          (key, value) => record('${name}_$key', value),
        );
      }

      // The owner's session (docs/map/PERFORMANCE.md): from the city out to
      // the country, in to the street, out again and back, each pinch 1.9
      // zoom levels in 0.6 s, a short pause between pinches.
      await flow('map_pinch_sweep', setup: () => start(13), () async {
        await realFingers([
          for (final (pinches, inward) in const [
            (4, false),
            (6, true),
            (6, false),
            (4, true),
          ])
            for (var i = 0; i < pinches; i++)
              inward ? const [140.0, 520.0] : const [520.0, 140.0],
        ], 600);
        stats('map_pinch_sweep');
      });

      // "Pinching up and down": fingers stay down and go in and out across
      // the heat / bubble band (zoom 10.8 to 12.7), then across bubble splits
      // (12.7 to 14.6), four times each.
      await flow('map_pinch_wave', setup: () => start(11.7), () async {
        const wave = [260.0, 140.0, 520.0, 140.0, 520.0, 140.0, 520.0];
        await realFingers([
          [...wave, 140, 520, 260],
          [140, 520],
          [...wave, 140, 520, 260],
        ], 700);
        stats('map_pinch_wave');
      });

      // A double tap, a two-finger tap and the zoom buttons each move the
      // map one level, animated: the camera passes through many zooms, none
      // more than a quarter of a level from the one before (an Android
      // animator scale of 0 makes MapLibre's tap zooms jump; PERFORMANCE.md).
      // A warm-up pair first, printed but not judged: in some runs the first
      // gestures soon after the map opened stalled (docs/map/DIAGNOSIS.md).
      await flow('map_tap_zoom', setup: () => start(13), () async {
        final c = center * tester.view.devicePixelRatio;
        final (x, y) = (c.dx.round(), c.dy.round());
        Finder button(String label) => find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == label,
        );
        Future<void> step(
          String name,
          int change,
          Future<void> Function() act, {
          bool judged = true,
        }) async {
          final stats = MapStats.instance;
          final before = stats.lastZoom ?? 13;
          stats
            ..zooms.clear()
            ..recordZooms = true;
          await act();
          await wait(tester, const Duration(milliseconds: 800));
          stats.recordZooms = false;
          final zooms = [before, for (final (_, z) in stats.zooms) z];
          final trace = [
            for (var i = 1; i < stats.zooms.length; i++)
              '${(stats.zooms[i].$1 - stats.zooms[i - 1].$1) ~/ 1000}ms:'
                  '${(stats.zooms[i].$2 - stats.zooms[i - 1].$2).toStringAsFixed(3)}',
          ];
          // ignore: avoid_print
          print('MAPTAPZOOM $name ${trace.join(' ')}');
          if (!judged) return;
          var largest = 0.0;
          for (var i = 1; i < zooms.length; i++) {
            largest = math.max(largest, (zooms[i] - zooms[i - 1]).abs());
          }
          final values = {for (final z in zooms) z.toStringAsFixed(3)}.length;
          final moved = zooms.last - before;
          record('map_tap_zoom_${name}_values', values);
          record(
            'map_tap_zoom_${name}_largest_step_milli',
            (largest * 1000).round(),
          );
          record('map_tap_zoom_${name}_change_milli', (moved * 1000).round());
          expect(values, greaterThanOrEqualTo(6), reason: '$name: zooms');
          expect(largest, lessThanOrEqualTo(0.25), reason: '$name: a jump');
          expect(moved, closeTo(change, 0.1), reason: '$name: one level');
        }

        Future<void> doubleTap() => playFingers('tap $x $y 2 120', 300);
        Future<void> twoFingerTap() => playFingers('$x $y 80 400 400', 100);
        await step('warm_up_double_tap', 1, doubleTap, judged: false);
        await step('warm_up_two_finger_tap', -1, twoFingerTap, judged: false);
        await step('double_tap', 1, doubleTap);
        await step('two_finger_tap', -1, twoFingerTap);
        await step('zoom_in_button', 1, () async {
          await tester.tap(button(AppL10n.current.mapZoomIn));
        });
        await step('zoom_out_button', -1, () async {
          await tester.tap(button(AppL10n.current.mapZoomOut));
        });
        stats('map_tap_zoom');
      });

      // Flashing bubbles (docs/map/FLASH_FIX.md): over the dense middle of the
      // seed, from the heat (zoom 11) in to the pins (15) and back, two levels
      // a pinch, at three speeds (1.5 s, 0.6 s and 0.18 s: a flick), about
      // 20 s each.
      // With MAP_FLASH the probe counts what the map drew wrong.
      for (final (name, ms, cycles) in [
        ('map_flash_slow', 1500, 3),
        ('map_flash_normal', 600, 5),
        ('map_flash_fast', 180, 8),
      ]) {
        await flow(name, setup: () => start(11), () async {
          await realFingers([
            for (var i = 0; i < cycles; i++) ...[
              [150.0, 600.0],
              [150.0, 600.0],
              [600.0, 150.0],
              [600.0, 150.0],
            ],
          ], ms);
          stats(name);
        });
      }

      // The selected pin (FLASH_FIX.md §selection): select, close by tapping
      // the map, select another, close and select it again quickly, tap it
      // twice; real taps where the map shows them.
      await flow('map_flash_select', setup: () => start(12.8), () async {
        final hooks = MapStats.instance;
        final first = await hooks.pinOnScreen?.call(0);
        final other = await hooks.pinOnScreen?.call(1);
        final empty = await hooks.emptyOnScreen?.call();
        if (first == null || other == null || empty == null) {
          fail('no pins or no empty spot on screen');
        }
        // One command, so the gaps are exact (each tap, then the wait).
        final steps = [
          (first, 1200),
          (empty, 1000),
          (other, 600),
          (empty, 150),
          (other, 1000),
          (empty, 1000),
          (first, 250),
          (first, 1000),
          (empty, 1000),
        ];
        await playFingers(
          'taps ${[for (final (at, ms) in steps) '${at.dx.round()} ${at.dy.round()} $ms'].join(' ')}',
          steps.fold(0, (sum, s) => sum + s.$2 + 50),
        );
        stats('map_flash_select');
      });

      await flow('map_compass', () async {
        double bearing() =>
            tester.widget<MapCompass>(find.byType(MapCompass)).bearing.value;
        await twist(tester, center, 70);
        record('map_compass_bearing_turned', bearing().round());
        await tester.tap(find.byType(MapCompass), warnIfMissed: false);
        await wait(tester, const Duration(seconds: 2));
        record('map_compass_bearing_after_tap', bearing().round());
      });
    }

    await flow(
      'camera_open_close',
      setup: () => tab(tester, AppIcons.navbarMap),
      () async {
        await tapAndWait(
          tester,
          icon(AppIcons.navbarAdd),
          const Duration(seconds: 3),
        );
        await back(tester);
      },
    );

    // A real two-finger pinch on the preview, then the zoom the stops show;
    // and the flash cycle, step by step (by its screen-reader labels).
    await flow(
      'camera_pinch',
      setup: () async {
        await tab(tester, AppIcons.navbarMap);
        await tapAndWait(
          tester,
          icon(AppIcons.navbarAdd),
          const Duration(seconds: 3),
        );
      },
      () async {
        double shownZoom() {
          final label = find
              .byWidgetPredicate(
                (w) => w is Text && (w.data?.endsWith('×') ?? false),
              )
              .evaluate()
              .map((e) => (e.widget as Text).data!)
              .firstOrNull;
          return double.tryParse(label?.replaceAll('×', '') ?? '') ?? 0;
        }

        final center = tester.getCenter(find.byType(Scaffold).first);
        await pinch(tester, center - const Offset(0, 120), 150, 600);
        await wait(tester, const Duration(milliseconds: 600));
        record('camera_pinch_zoom_x100', (shownZoom() * 100).round());

        final flashLabels = {
          l10n().capsulesCameraFlashOff: 0,
          l10n().capsulesCameraFlashAuto: 1,
          l10n().capsulesCameraFlashOn: 2,
          l10n().capsulesCameraFlashTorch: 3,
        };
        Finder flash() => find.byWidgetPredicate(
          (w) => w is Semantics && flashLabels.containsKey(w.properties.label),
        );
        // -1: the flash button is not on screen (the camera did not start, or
        // the app was sent to the background), so the run goes on without it.
        int state() => flash().evaluate().isEmpty
            ? -1
            : flashLabels[(tester.widget<Semantics>(
                flash().first,
              )).properties.label]!;
        // 0 off, 1 auto, 2 on, 3 torch: recorded as one number per step.
        for (var i = 0; i < 5; i++) {
          record('camera_flash_step_$i', state());
          if (state() < 0) break;
          await tester.tap(flash().first, warnIfMissed: false);
          await wait(tester, const Duration(milliseconds: 600));
        }
        record('camera_flash_step_5', state());
      },
    );
    await home(tester);

    await flow(
      'camera_capture',
      setup: () async {
        await tab(tester, AppIcons.navbarMap);
        await tapAndWait(
          tester,
          icon(AppIcons.navbarAdd),
          const Duration(seconds: 3),
        );
      },
      () async {
        final watch = Stopwatch()..start();
        // With loops on, the shutter says it also records a loop (B4).
        await tap(tester, labelled(l10n().capsulesCameraTakePhotoOrLoop));
        await waitFor(tester, find.byType(CapsuleCreationPage));
        record('camera_tap_to_creation_test_ms', watch.elapsedMilliseconds);
        await wait(tester, const Duration(seconds: 2));
      },
    );

    // Saving the capsule just taken (to the local emulators): the button
    // draws in, turns into a check, and the page closes.
    if (find.byType(CapsuleCreationPage).evaluate().isNotEmpty) {
      await flow('creation_save', () async {
        final watch = Stopwatch()..start();
        await tap(tester, labelled(l10n().capsulesCreationSubmit));
        await waitFor(
          tester,
          find.byType(CapsuleCreationPage).hitTestable(),
          const Duration(milliseconds: 1),
        );
        final end = DateTime.now().add(const Duration(seconds: 15));
        while (find.byType(CapsuleCreationPage).evaluate().isNotEmpty &&
            DateTime.now().isBefore(end)) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        record('creation_save_to_closed_ms', watch.elapsedMilliseconds);
        await wait(tester, const Duration(seconds: 1));
      });
    }
    await home(tester);

    measured.forEach((key, values) => binding.reportData![key] = values);
    // The language is saved on the phone: back to following the phone, so
    // the next run starts as usual.
    if (_language.isNotEmpty) {
      await tester
          .element(find.byType(NavbarWidget))
          .read<AppearanceController>()
          .setLanguage(null);
      await wait(tester, const Duration(seconds: 1));
    }
  });
}
