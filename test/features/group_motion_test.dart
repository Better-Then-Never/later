// The split and merge of the MapLibre map's bubbles, planned in Dart and
// drawn by the map's moving layer (mission 2, §2.1).
import 'package:flutter_test/flutter_test.dart';
import 'package:later/features/map/engine/capsule_groups.dart';
import 'package:later/features/map/engine/group_motion.dart';

GroupPoint _p(String id, double lat, double lng) =>
    GroupPoint(id, lat, lng, 'red');

const _pins = CapsuleGroups.maxLevel + 1;

void main() {
  final three = CapsuleGroups.build([
    _p('a', 52.2300, 21.0100),
    _p('b', 52.2301, 21.0102),
    _p('c', 52.2302, 21.0099),
  ]);
  final bubble = three.at(15).single;
  final centre = (bubble.x, bubble.y);

  GroupTransition plan(
    CapsuleGroups groups,
    int from,
    int to, {
    int now = 0,
    bool Function(GroupNode)? onScreen,
    GroupTransition? previous,
  }) => GroupMotion.plan(
    groups,
    from: from,
    to: to,
    now: now,
    onScreen: onScreen ?? (_) => true,
    centre: centre,
    previous: previous,
  );

  test('zooming in, the bubble opens and its capsules fly out', () {
    final t = plan(three, 15, _pins);
    final flying = t.flights.where((f) => f.kind == FlightKind.fly).toList();
    expect(flying.map((f) => f.node.id).toSet(), {'a', 'b', 'c'});
    expect(t.flights.where((f) => f.kind == FlightKind.open), hasLength(1));
    expect(t.moving, {'a', 'b', 'c'});
    for (final f in flying) {
      // They leave from under the bubble (drawn over them), small ...
      final first = f.at(f.start)!;
      expect(first.x, bubble.x);
      expect(first.y, bubble.y);
      expect(first.scale, 0.5);
      // ... and stand whole on their own spot until the change ends.
      final last = f.at(t.end)!;
      expect(last.x, f.node.x);
      expect(last.y, f.node.y);
      expect(last.scale, closeTo(1, 1e-9));
      expect(last.opacity, 1);
    }
    final open = t.flights.firstWhere((f) => f.kind == FlightKind.open);
    expect(open.at(open.end), isNull, reason: 'gone once open');
  });

  test('zooming out, the capsules fly into the bubble that forms', () {
    final t = plan(three, _pins, 15);
    final merging = t.flights.where((f) => f.kind == FlightKind.merge);
    expect(merging.map((f) => f.node.id).toSet(), {'a', 'b', 'c'});
    final form = t.flights.singleWhere((f) => f.kind == FlightKind.form);
    expect(form.node.id, bubble.id);
    expect(t.moving, {bubble.id});
    for (final f in merging) {
      expect(f.at(f.end), isNull, reason: 'gone as it arrives');
      final half = f.at(f.start + f.duration ~/ 2)!;
      expect(half.scale, lessThan(1));
    }
    // The bubble grows in while they arrive, and counts them.
    expect(form.start, lessThan(merging.last.end));
    expect(form.at(form.start - 1), isNull);
    expect(form.at(t.end)!.count, 3);
    expect(form.at(t.end)!.scale, closeTo(1, 1e-9));
  });

  test('nothing is ever see-through, at any speed, either way', () {
    for (final speed in [0.0, 3.0, 8.0, 20.0]) {
      for (final (from, to) in [(15, _pins), (_pins, 15)]) {
        final t = plan(three, from, to);
        final again = GroupMotion.plan(
          three,
          from: from,
          to: to,
          now: 0,
          onScreen: (_) => true,
          centre: centre,
          zoomSpeed: speed,
        );
        for (final transition in [t, again]) {
          for (var ms = 0; ms <= transition.end; ms += 4) {
            for (final (_, frame) in transition.frames(ms)) {
              expect(frame.opacity, 1, reason: 'speed $speed at $ms ms');
            }
          }
        }
      }
    }
  });

  test('the bubble shrinks away instead of vanishing', () {
    final t = plan(three, 15, _pins);
    final open = t.flights.firstWhere((f) => f.kind == FlightKind.open);
    final late = open.at(open.end - 1)!;
    expect(late.scale, lessThan(0.35));
    var last = double.infinity;
    for (var ms = open.start + open.duration ~/ 5; ms < open.end; ms += 2) {
      final s = open.at(ms)!.scale;
      expect(s, lessThanOrEqualTo(last + 1e-9));
      last = s;
    }
  });

  test('a faster zoom moves for less time, and never skips', () {
    expect(GroupMotion.pace(0), 1);
    expect(GroupMotion.pace(2), 1);
    expect(GroupMotion.pace(4), closeTo(0.5, 1e-9));
    expect(GroupMotion.pace(50), 0.35);
    for (final (from, to) in [(15, _pins), (_pins, 15)]) {
      final slow = plan(three, from, to);
      final fast = GroupMotion.plan(
        three,
        from: from,
        to: to,
        now: 0,
        onScreen: (_) => true,
        centre: centre,
        zoomSpeed: 10,
      );
      expect(fast.flights.length, slow.flights.length, reason: 'not skipped');
      expect(fast.end, lessThanOrEqualTo(slow.end * 0.4));
      // A flick still takes the eye along: about a tenth of a second.
      expect(fast.end, greaterThanOrEqualTo(80));
    }
  });

  test('a moving bubble keeps its number (a new number is a new picture)', () {
    for (final (from, to) in [(15, _pins), (_pins, 15)]) {
      final t = plan(three, from, to);
      for (var ms = 0; ms <= t.end; ms += 5) {
        for (final (flight, frame) in t.frames(ms)) {
          expect(frame.count, flight.node.count);
        }
      }
    }
  });

  test('a split off the screen just happens', () {
    final t = plan(three, 15, _pins, onScreen: (_) => false);
    expect(t.flights, isEmpty);
    expect(t.moving, isEmpty);
  });

  test('nothing moves when the level stays', () {
    expect(plan(three, 15, 15).isEmpty, isTrue);
  });

  test('the groups nearest the middle go first, at most the limit fly', () {
    // 40 pairs of capsules in a row going east: 120 flights wanted.
    final groups = CapsuleGroups.build([
      for (var i = 0; i < 40; i++) ...[
        _p('p$i', 52.23, 21.0 + i * 0.01),
        _p('q$i', 52.2301, 21.0001 + i * 0.01),
      ],
    ]);
    final t = GroupMotion.plan(
      groups,
      from: 15,
      to: _pins,
      now: 0,
      onScreen: (_) => true,
      centre: (GroupNode.worldX(21.0), GroupNode.worldY(52.23)),
    );
    expect(t.flights.length, lessThanOrEqualTo(GroupMotion.limit));
    final opens = t.flights.where((f) => f.kind == FlightKind.open).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    expect(opens.first.node.leafId, 'p0', reason: 'nearest the middle');
    for (var i = 1; i < opens.length; i++) {
      expect(opens[i].node.x, greaterThan(opens[i - 1].node.x));
    }
    expect(opens.last.start, lessThanOrEqualTo(GroupMotion.maxSpread));
  });

  test('turned around mid-way, the capsules go back from where they are', () {
    final out = plan(three, 15, _pins);
    final fly = out.flights.firstWhere((f) => f.kind == FlightKind.fly);
    final now = fly.start + fly.duration ~/ 2;
    final drawn = fly.at(now)!;
    final back = plan(three, _pins, 15, now: now, previous: out);
    final merge = back.flights.firstWhere(
      (f) => f.kind == FlightKind.merge && f.node.id == fly.node.id,
    );
    expect(merge.fromX, drawn.x);
    expect(merge.fromY, drawn.y);
  });

  test('caught mid-flight by a change that keeps it, it glides on whole', () {
    // A pair 5 m apart and a third capsule 60 m away: one bubble at 15, the
    // pair and the third apart at 16, three pins at the last level.
    final groups = CapsuleGroups.build([
      _p('a', 52.23000, 21.01000),
      _p('b', 52.23004, 21.01002),
      _p('c', 52.23055, 21.01000),
    ]);
    expect(groups.at(15), hasLength(1));
    expect(groups.at(16), hasLength(2));
    final first = GroupMotion.plan(
      groups,
      from: 15,
      to: 16,
      now: 0,
      onScreen: (_) => true,
      centre: centre,
    );
    final c = first.flights.firstWhere((f) => f.node.id == 'c');
    final now = c.start + c.duration ~/ 3;
    final drawn = c.at(now)!;
    final second = GroupMotion.plan(
      groups,
      from: 16,
      to: _pins,
      now: now,
      onScreen: (_) => true,
      centre: centre,
      previous: first,
    );
    final glide = second.flights.singleWhere((f) => f.node.id == 'c');
    expect(glide.kind, FlightKind.glide);
    expect(glide.at(now)!.x, drawn.x);
    expect(glide.at(now)!.scale, 1);
    expect(glide.at(now)!.opacity, 1);
    expect(glide.at(glide.end)!.x, glide.node.x);
    expect(second.moving, contains('c'));
    // The pair splits from where its bubble is drawn now.
    final pair = first.flights.firstWhere(
      (f) => f.kind == FlightKind.fly && f.node.isBubble,
    );
    final pairAt = pair.at(now)!;
    final a = second.flights.firstWhere((f) => f.node.id == 'a');
    expect(a.kind, FlightKind.fly);
    expect(a.fromX, pairAt.x);
    expect(a.fromY, pairAt.y);
  });
}
