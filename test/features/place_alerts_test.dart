import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/models/app_notification.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/geo_position.dart';
import 'package:later/data/models/user_settings.dart';
import 'package:later/data/services/preferences_store.dart';
import 'package:later/data/services/push_messaging_service.dart';
import 'package:later/features/map/map_pin_store.dart';
import 'package:later/features/notifications/notification_router.dart';
import 'package:later/features/places/place_alerts.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 11, 2, 12);
const _here = GeoPosition(52.2497, 21.0122);

/// [metres] north of [_here].
GeoPosition _north(double metres) =>
    GeoPosition(_here.latitude + metres / 111320, _here.longitude);

Capsule _pin(
  String id, {
  double metres = 50,
  DateTime? openAt,
  OpenWhere where = OpenWhere.anywhere,
}) => Capsule(
  id: id,
  ownerId: 'bob',
  title: '',
  privacy: CapsulePrivacy.friends,
  color: CapsuleColor.red,
  location: _north(metres),
  openAt: openAt,
  openWhere: where,
);

void main() {
  group('capsules near you (F4)', () {
    List<String> near(
      List<Capsule> pins, {
      Set<String> unlocked = const {},
      Set<String> wrapped = const {},
      List<String> announced = const [],
    }) => [
      for (final (c, _) in PlaceAlerts.nearby(
        capsules: pins,
        at: _here,
        now: _now,
        unlocked: unlocked,
        wrapped: (c) => wrapped.contains(c.id),
        announced: announced,
      ))
        c.id,
    ];

    test('a place capsule waiting for you within 200 m, nearest first', () {
      final pins = [
        _pin('far', metres: 260, where: OpenWhere.here),
        _pin('near', metres: 40, where: OpenWhere.here),
        _pin('mid', metres: 150, where: OpenWhere.here),
      ];
      expect(near(pins), ['near', 'mid']);
    });

    test('not one you opened there, not one whose date has not come', () {
      final pins = [
        _pin('opened', where: OpenWhere.here),
        _pin(
          'later',
          where: OpenWhere.here,
          openAt: _now.add(const Duration(days: 1)),
        ),
      ];
      expect(near(pins, unlocked: {'opened'}), isEmpty);
    });

    test('a capsule that opened by date counts while it is still wrapped', () {
      final pins = [
        _pin('wrapped', openAt: _now.subtract(const Duration(days: 1))),
        _pin('seen', openAt: _now.subtract(const Duration(days: 1))),
        _pin('anytime'),
      ];
      expect(near(pins, wrapped: {'wrapped'}), ['wrapped']);
    });

    test('announced once', () {
      final memory = PlaceAlertsMemory();
      PlaceAlerts.announced(memory, 'near');
      expect(
        near([_pin('near', where: OpenWhere.here)], announced: memory.nearby),
        isEmpty,
      );
      for (var i = 0; i < PlaceAlerts.keepAnnounced + 5; i++) {
        PlaceAlerts.announced(memory, 'c$i');
      }
      expect(memory.nearby.length, PlaceAlerts.keepAnnounced);
      expect(memory.nearby.last, 'c${PlaceAlerts.keepAnnounced + 4}');
    });
  });

  group('welcome to a new country (F3)', () {
    test('home first; abroad after two hours; once a month', () {
      final m = PlaceAlertsMemory();
      expect(PlaceAlerts.welcome(m, 'PL', _now), isNull);
      expect(m.home, 'PL');
      // Arrives in Austria: the stay starts.
      var t = _now.add(const Duration(days: 3));
      expect(PlaceAlerts.welcome(m, 'AT', t), isNull);
      t = t.add(const Duration(hours: 1, minutes: 30));
      expect(PlaceAlerts.welcome(m, 'AT', t), isNull, reason: 'too soon');
      t = t.add(const Duration(minutes: 31));
      expect(PlaceAlerts.welcome(m, 'AT', t), 'AT');
      t = t.add(const Duration(hours: 1));
      expect(PlaceAlerts.welcome(m, 'AT', t), isNull, reason: 'once');
      // Home and back a week later: not again within a month.
      t = t.add(const Duration(days: 2));
      PlaceAlerts.welcome(m, 'PL', t);
      t = t.add(const Duration(days: 5));
      PlaceAlerts.welcome(m, 'AT', t);
      t = t.add(const Duration(hours: 3));
      expect(PlaceAlerts.welcome(m, 'AT', t), isNull);
      // Unknown country: nothing changes.
      expect(PlaceAlerts.welcome(m, null, t), isNull);
      expect(m.country, 'AT');
    });

    test('held back (quiet hours): not used up, welcomed at a later check', () {
      final m = PlaceAlertsMemory()..home = 'PL';
      var t = _now;
      PlaceAlerts.welcome(m, 'AT', t);
      t = t.add(const Duration(hours: 3));
      expect(PlaceAlerts.welcome(m, 'AT', t, allowed: false), isNull);
      expect(m.welcomed, isEmpty);
      t = t.add(const Duration(hours: 8));
      expect(PlaceAlerts.welcome(m, 'AT', t), 'AT');
    });

    test('a month in one country makes it home', () {
      final m = PlaceAlertsMemory()..home = 'PL';
      var t = _now;
      PlaceAlerts.welcome(m, 'DE', t);
      t = t.add(const Duration(days: 31));
      PlaceAlerts.welcome(m, 'DE', t);
      expect(m.home, 'DE');
    });

    test('remembered on the phone per account', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = PreferencesStore();
      final m = PlaceAlertsMemory(
        home: 'PL',
        country: 'AT',
        countrySince: _now,
        welcomed: {'AT': _now},
        nearby: ['c1'],
      );
      await m.save(prefs, 'me');
      final back = await PlaceAlertsMemory.read(prefs, 'me');
      expect(back.home, 'PL');
      expect(back.country, 'AT');
      expect(back.countrySince, _now);
      expect(back.welcomed['AT'], _now);
      expect(back.nearby, ['c1']);
      expect((await PlaceAlertsMemory.read(prefs, 'other')).home, isNull);
    });
  });

  test('quiet hours, also across midnight', () {
    const night = QuietHours(enabled: true, start: 22 * 60, end: 7 * 60);
    expect(PlaceAlerts.quiet(night, DateTime(2026, 1, 1, 23)), isTrue);
    expect(PlaceAlerts.quiet(night, DateTime(2026, 1, 1, 6, 59)), isTrue);
    expect(PlaceAlerts.quiet(night, DateTime(2026, 1, 1, 12)), isFalse);
    const lunch = QuietHours(enabled: true, start: 12 * 60, end: 13 * 60);
    expect(PlaceAlerts.quiet(lunch, DateTime(2026, 1, 1, 12, 30)), isTrue);
    expect(PlaceAlerts.quiet(lunch, DateTime(2026, 1, 1, 13)), isFalse);
    expect(
      PlaceAlerts.quiet(const QuietHours(), DateTime(2026, 1, 1, 23)),
      isFalse,
    );
  });

  test('the map keeps whether a pin opens only at its spot', () {
    final back = MapPinStore.decode(
      MapPinStore.encode(
        StoredMap(
          pins: [
            StoredPin(_pin('here', where: OpenWhere.here), PinSource.friends),
            StoredPin(_pin('any'), PinSource.friends),
          ],
        ),
      ),
      uid: 'me',
    );
    expect([for (final p in back.pins) p.capsule.opensHere], [true, false]);
  });

  test(
    'a tap: near a capsule shows it on the map; a new country, the camera',
    () {
      final nearby = NotificationRouter.destinationFor(
        NotificationTap.fromData({'type': 'capsuleNearby', 'capsuleId': 'c1'}),
        friends: const {},
      );
      expect(
        nearby,
        isA<CapsuleDestination>()
            .having((d) => d.capsuleId, 'capsuleId', 'c1')
            .having((d) => d.open, 'open', isFalse),
      );
      expect(
        NotificationRouter.destinationFor(
          NotificationTap.fromData({'type': 'newCountry'}),
          friends: const {},
        ),
        isA<NewCapsuleDestination>(),
      );
      expect(
        NotificationType.parse('capsuleNearby'),
        NotificationType.capsuleNearby,
      );
    },
  );
}
