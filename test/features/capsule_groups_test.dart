// The MapLibre map's capsules grouped level by level in Dart, so a bubble
// knows what it splits into (docs/map/DECISION.md, mission 2).
import 'package:flutter_test/flutter_test.dart';
import 'package:later/features/map/engine/capsule_groups.dart';

GroupPoint _p(String id, double lat, double lng) =>
    GroupPoint(id, lat, lng, 'red');

void main() {
  // At zoom 15 one dp is about 2.9 m in Warsaw; 0.0001° of latitude 11 m.
  final near = [
    _p('a', 52.2300, 21.0100),
    _p('b', 52.2301, 21.0101),
    _p('c', 52.2302, 21.0099),
  ];
  final far = _p('z', 52.3000, 21.2000);

  test('close capsules are one bubble, apart at the last level', () {
    final groups = CapsuleGroups.build([...near, far]);
    final at15 = groups.at(15);
    expect(at15, hasLength(2));
    final bubble = at15.firstWhere((n) => n.isBubble);
    expect(bubble.count, 3);
    expect(bubble.color, isNull);
    expect(groups.at(CapsuleGroups.maxLevel + 1), hasLength(4));
    expect(
      groups.at(CapsuleGroups.maxLevel + 1).every((n) => !n.isBubble),
      isTrue,
    );
  });

  test('a bubble sits at its capsules\' middle and covers their area', () {
    final groups = CapsuleGroups.build(near);
    final bubble = groups.at(14).single;
    expect(bubble.latitude, closeTo(52.2301, 1e-6));
    expect(bubble.longitude, closeTo(21.0100, 1e-6));
    expect(bubble.south, 52.2300);
    expect(bubble.north, 52.2302);
    expect(bubble.west, 21.0099);
    expect(bubble.east, 21.0101);
  });

  test('a capsule alone is the same node at every level', () {
    final groups = CapsuleGroups.build([...near, far]);
    final pins = [
      for (var l = CapsuleGroups.minLevel; l <= CapsuleGroups.maxLevel + 1; l++)
        groups.at(l).firstWhere((n) => n.id == 'z'),
    ];
    expect(pins.every((n) => identical(n, pins.first)), isTrue);
  });

  test('every pin knows the bubble that holds it further out', () {
    final groups = CapsuleGroups.build([...near, far]);
    const last = CapsuleGroups.maxLevel + 1;
    final bubble = groups.at(15).firstWhere((n) => n.isBubble);
    for (final pin in groups.at(last)) {
      final holder = groups.ancestor(pin, last, 15);
      expect(holder.id, pin.id == 'z' ? 'z' : bubble.id);
    }
  });

  test('the same capsules in another order: the same groups', () {
    final a = CapsuleGroups.build([...near, far]);
    final b = CapsuleGroups.build([far, ...near.reversed]);
    for (var l = CapsuleGroups.minLevel; l <= CapsuleGroups.maxLevel; l++) {
      expect(
        {for (final n in b.at(l)) n.id},
        {for (final n in a.at(l)) n.id},
        reason: 'level $l',
      );
    }
  });

  test('the level shown changes half way between whole zooms', () {
    expect(CapsuleGroups.levelFor(12.49), 12);
    expect(CapsuleGroups.levelFor(12.5), 13);
    expect(CapsuleGroups.levelFor(13.2), 13);
    expect(CapsuleGroups.levelFor(3), CapsuleGroups.minLevel);
    expect(CapsuleGroups.levelFor(21), CapsuleGroups.maxLevel + 1);
  });

  test('where a bubble splits; capsules on one spot never do', () {
    final groups = CapsuleGroups.build(near);
    final bubble = groups.at(14).single;
    final splits = groups.splitsAt(bubble, 14)!;
    expect(splits, greaterThan(14));
    expect(groups.at(splits).length, greaterThan(1));
    final stacked = CapsuleGroups.build([
      _p('s1', 52.23, 21.01),
      _p('s2', 52.23, 21.01),
    ]);
    final pair = stacked.at(CapsuleGroups.maxLevel).single;
    expect(
      stacked.splitsAt(pair, CapsuleGroups.maxLevel),
      CapsuleGroups.maxLevel + 1,
    );
  });

  test('2,000 capsules group in well under a frame budget per level', () {
    final points = [
      for (var i = 0; i < 2000; i++)
        _p(
          'c$i',
          52.1 + (i * 7919 % 2000) / 8000,
          20.8 + (i * 104729 % 2000) / 4000,
        ),
    ];
    final watch = Stopwatch()..start();
    final groups = CapsuleGroups.build(points);
    expect(groups.at(CapsuleGroups.maxLevel + 1), hasLength(2000));
    expect(watch.elapsedMilliseconds, lessThan(500));
  });
}
