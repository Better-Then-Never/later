import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/features/history/on_this_day.dart';
import 'package:later/features/history/widgets/on_this_day_strip.dart';

import '../helpers/test_app.dart';

Capsule _c(
  String id, {
  DateTime? createdAt,
  DateTime? capturedAt,
  DateTime? openAt,
  bool pending = false,
}) => Capsule(
  id: id,
  ownerId: 'me',
  title: id,
  privacy: CapsulePrivacy.private,
  color: CapsuleColor.red,
  createdAt: createdAt,
  capturedAt: capturedAt,
  openAt: openAt,
  isScheduled: openAt != null,
  pending: pending,
);

void main() {
  final now = DateTime(2026, 10, 17, 9);

  test('capsules from this date in earlier years, the latest year first', () {
    final found = OnThisDay.from([
      _c('two years', createdAt: DateTime(2024, 10, 17, 20)),
      _c('today', createdAt: DateTime(2026, 10, 17, 8)),
      _c('other day', createdAt: DateTime(2025, 10, 16)),
      _c('last year', createdAt: DateTime(2025, 10, 17, 7)),
      // The moment of the photo wins over the upload (offline capsules).
      _c(
        'taken then',
        createdAt: DateTime(2025, 10, 18),
        capturedAt: DateTime(2023, 10, 17, 22),
      ),
      _c(
        'still locked',
        createdAt: DateTime(2025, 10, 17),
        openAt: DateTime(2027),
      ),
      _c('waiting', createdAt: DateTime(2025, 10, 17), pending: true),
    ], now);
    expect(found.map((c) => c.id), ['last year', 'two years', 'taken then']);
    expect(found.map((c) => OnThisDay.yearsAgo(c, now)), [1, 2, 3]);
  });

  test('"years ago" reads right in every language', () {
    addTearDown(() => AppL10n.update(const Locale('en')));
    String say(String lang, int n) {
      AppL10n.update(Locale(lang));
      return AppL10n.current.historyYearsAgo(n);
    }

    expect(say('en', 1), '1 year ago');
    expect(say('en', 3), '3 years ago');
    expect(say('ru', 1), '1 год назад');
    expect(say('ru', 3), '3 года назад');
    expect(say('ru', 5), '5 лет назад');
    expect(say('pl', 1), 'Rok temu');
    expect(say('pl', 5), '5 lat temu');
    expect(say('de', 2), 'Vor 2 Jahren');
    expect(say('es', 1), 'Hace 1 año');
  });

  for (final scale in [1.0, 1.3, 2.0]) {
    for (final language in ['ru', 'de']) {
      testWidgets('the strip fits its text at $scale in $language', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final now = DateTime(2026, 10, 17, 9);
        await tester.pumpWidget(
          testApp(
            locale: Locale(language),
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(360, 800),
                textScaler: TextScaler.linear(scale),
              ),
              child: Scaffold(
                body: OnThisDayStrip(
                  capsules: [
                    _c('Lake picnic', createdAt: DateTime(2025, 10, 17)),
                    _c('First snow', createdAt: DateTime(2024, 10, 17)),
                  ],
                  now: now,
                  onTap: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
