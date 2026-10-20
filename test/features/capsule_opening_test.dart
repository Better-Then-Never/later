import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/services/preferences_store.dart';
import 'package:later/features/capsules/opening/capsule_openings.dart';
import 'package:later/features/capsules/opening/capsule_wrap.dart';
import 'package:later/features/capsules/social/capsule_detail_dialog.dart';
import 'package:later/features/capsules/social/capsule_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/capsule_host.dart';
import '../helpers/test_app.dart';

void main() {
  final now = DateTime.now();
  final since = now.subtract(const Duration(days: 30));

  // Olga's capsule, left 400 days ago, open since yesterday.
  final dated = Capsule(
    id: 'dated',
    ownerId: 'olga',
    title: 'Night swim',
    privacy: CapsulePrivacy.public,
    color: CapsuleColor.blue,
    createdAt: now.subtract(const Duration(days: 400)),
    openAt: now.subtract(const Duration(days: 1)),
  );

  group('CapsuleOpenings', () {
    test(
      "someone else's capsule arrives wrapped once it can be opened",
      () async {
        final openings = await testOpenings(since: since);
        expect(openings.isWrapped(dated, 'me', now), isTrue);
        final locked = dated.copyWithOpenAt(now.add(const Duration(days: 3)));
        expect(
          openings.isWrapped(locked, 'me', now),
          isFalse,
          reason: 'locked',
        );
        final anytime = Capsule(
          id: 'any',
          ownerId: 'olga',
          title: 'Lunch',
          privacy: CapsulePrivacy.public,
          color: CapsuleColor.red,
          createdAt: now.subtract(const Duration(days: 2)),
        );
        expect(openings.isWrapped(anytime, 'me', now), isTrue);
        expect(
          openings.isWrapped(anytime, null, now),
          isFalse,
          reason: 'signed out',
        );
      },
    );

    test(
      'capsules that could be opened before the phone first asked are seen',
      () async {
        final openings = await testOpenings(
          since: now.subtract(const Duration(hours: 1)),
        );
        expect(openings.isWrapped(dated, 'me', now), isFalse);
      },
    );

    test('a fresh phone takes now as its start', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = PreferencesStore();
      await prefs.init();
      final openings = CapsuleOpenings(prefs, clock: () => now);
      expect(openings.isWrapped(dated, 'me', now), isFalse);
      expect(
        await prefs.string('me', 'unwrapped_since'),
        now.toIso8601String(),
      );
    });

    test(
      'your own capsule is wrapped only when it waited for a date',
      () async {
        final openings = await testOpenings(since: since);
        final mine = Capsule(
          id: 'mine',
          ownerId: 'me',
          title: 'Today',
          privacy: CapsulePrivacy.private,
          color: CapsuleColor.green,
          createdAt: now.subtract(const Duration(days: 1)),
        );
        expect(openings.isWrapped(mine, 'me', now), isFalse);
        final myDated = Capsule(
          id: 'mine2',
          ownerId: 'me',
          title: 'A year on',
          privacy: CapsulePrivacy.private,
          color: CapsuleColor.green,
          createdAt: now.subtract(const Duration(days: 365)),
          openAt: now.subtract(const Duration(hours: 2)),
        );
        expect(openings.isWrapped(myDated, 'me', now), isTrue);
      },
    );

    test('once opened, it opens at once, also after a restart', () async {
      final openings = await testOpenings(since: since);
      await openings.markOpened('me', dated.id);
      expect(openings.isWrapped(dated, 'me', now), isFalse);
      final prefs = PreferencesStore();
      await prefs.init();
      expect(CapsuleOpenings(prefs).isWrapped(dated, 'me', now), isFalse);
    });
  });

  group('the wrapped first open', () {
    late FakeSocialRepository social;
    late CapsuleOpenings openings;

    setUp(() async {
      social = FakeSocialRepository();
      openings = await testOpenings(since: since);
    });

    Future<void> openSheet(WidgetTester tester, {bool reduce = false}) async {
      await tester.pumpWidget(
        capsuleHost(
          social: social,
          openings: openings,
          people: const [
            UserProfile(uid: 'olga', name: 'Olga Berg', username: 'olga'),
          ],
          child: MediaQuery(
            data: MediaQueryData.fromView(
              tester.view,
            ).copyWith(disableAnimations: reduce),
            child: testApp(
              home: Builder(
                builder: (context) => TextButton(
                  onPressed: () => CapsuleDetailDialog.show(context, dated),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Future<void> hold(WidgetTester tester, Duration duration) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(CapsuleWrap)),
      );
      for (
        var t = Duration.zero;
        t < duration;
        t += const Duration(milliseconds: 50)
      ) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pump();
    }

    testWidgets('it arrives wrapped with its tag and how long it waited', (
      tester,
    ) async {
      await openSheet(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(CapsuleWrap), findsOneWidget);
      expect(find.text('Hold to open'), findsOneWidget);
      expect(find.text('Waited 400 days'), findsOneWidget);
      expect(find.textContaining('From Olga Berg'), findsOneWidget);
    });

    testWidgets('let go early: it winds back and stays wrapped', (
      tester,
    ) async {
      await openSheet(tester);
      await hold(tester, const Duration(milliseconds: 400));
      expect(find.text('Hold a little longer'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(CapsuleWrap), findsOneWidget);
      expect(openings.isWrapped(dated, 'me', DateTime.now()), isTrue);
    });

    testWidgets('held for a second, it tears open and is remembered', (
      tester,
    ) async {
      await openSheet(tester);
      await hold(tester, const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();
      expect(find.byType(CapsuleWrap), findsNothing);
      expect(find.byType(CapsuleSheet), findsOneWidget);
      expect(openings.isWrapped(dated, 'me', DateTime.now()), isFalse);

      // The second open is instant.
      Navigator.of(tester.element(find.byType(CapsuleSheet))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(CapsuleWrap), findsNothing);
    });

    testWidgets('a screen reader opens it with a double tap', (tester) async {
      final semantics = tester.ensureSemantics();
      await openSheet(tester, reduce: true);
      tester.semantics.tap(find.semantics.byLabel(RegExp('^Open the capsule')));
      await tester.pumpAndSettle();
      expect(find.byType(CapsuleWrap), findsNothing);
      semantics.dispose();
    });
  });
}

extension on Capsule {
  Capsule copyWithOpenAt(DateTime openAt) => Capsule(
    id: id,
    ownerId: ownerId,
    title: title,
    privacy: privacy,
    color: color,
    createdAt: createdAt,
    openAt: openAt,
  );
}
