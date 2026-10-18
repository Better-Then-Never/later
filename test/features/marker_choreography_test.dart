// How capsules come onto the map and leave it (M-03, M-04): Flutter draws
// them while they move, the map gets them all once they have landed (adding
// markers holds up the main thread, so nothing may move meanwhile).
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:later/features/map/map_clusters.dart';
import 'package:later/features/map/marker_choreography.dart';

late ui.Image _image;

/// A place [dx], [dy] screen dp from the middle (one dp per 1e-5 degree).
LatLng _at(double dx, double dy) => LatLng(-dy * 1e-5, dx * 1e-5);

Offset? _screen(LatLng p) {
  final o = Offset(p.longitude * 1e5, -p.latitude * 1e5);
  return o.distance > 500 ? null : o;
}

ShownMarker _pin(String id, double dx, double dy) => ShownMarker(
  Marker(markerId: MarkerId(id), position: _at(dx, dy)),
  look: MarkerLook(_image, const Size.square(48), const Offset(0.5, 1)),
);

ShownMarker _bubble(String id, double dx, double dy, {double span = 30}) {
  final at = _at(dx, dy);
  return ShownMarker(
    Marker(markerId: MarkerId(id), position: at),
    look: MarkerLook(_image, const Size.square(44), const Offset(0.5, 0.5)),
    bounds: GeoBounds(
      south: at.latitude - span * 1e-5,
      west: at.longitude - span * 1e-5,
      north: at.latitude + span * 1e-5,
      east: at.longitude + span * 1e-5,
    ),
  );
}

void _update(MarkerChoreography c, List<ShownMarker> target) =>
    c.update(target, screen: _screen, centre: Offset.zero);

Set<String> _onMap(MarkerChoreography c) => {
  for (final id in c.onMap.keys) id.value,
};

/// Runs the clock until nothing moves, handing every group over at once.
void _settle(MarkerChoreography c) {
  for (var ms = c.ms; c.active && ms < c.ms + 5000; ms += 16) {
    if (c.advance(ms) case final act?) c.handedOver(act);
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _image = await createTestImage(width: 4, height: 4);
  });

  test('first open: they pop in, ring by ring from the middle', () {
    final c = MarkerChoreography();
    _update(c, [
      _pin('near', 10, 0),
      _pin('mid', 0, 200),
      _pin('far', 300, 0),
      _pin('away', 900, 0),
    ]);
    expect(_onMap(c), isEmpty, reason: 'off screen waits too, unseen');
    final pops = {
      for (final s in c.sprites)
        if (s.motion == SpriteMotion.pop) s.id.value: s,
    };
    expect(pops.keys, unorderedEquals(['near', 'mid', 'far']));
    expect(pops['near']!.start, lessThan(pops['mid']!.start));
    expect(pops['mid']!.start, lessThan(pops['far']!.start));
    expect(pops['near']!.at(pops['near']!.start)!.scale, 0);

    // Nothing reaches the map while the others still move.
    expect(c.advance(pops['near']!.end), isNull);
    expect(_onMap(c), isEmpty);
    // All together once the last has landed; the sprites stay, still, until
    // the map has drawn them.
    final act = c.advance(pops['far']!.end);
    expect(act, isNotNull);
    expect(_onMap(c), {'near', 'mid', 'far', 'away'});
    expect(c.sprites.where((s) => s.id.value == 'near'), isNotEmpty);
    final still = c.sprites.first.at(c.ms + 1000)!;
    expect(still.scale, 1);
    expect(still.opacity, 1);
    c.handedOver(act!);
    expect(c.active, isFalse);
  });

  test('zooming in: a bubble\'s capsules fly out of it', () {
    final c = MarkerChoreography();
    _update(c, [_bubble('b', 0, 0)]);
    _settle(c);
    _update(c, [_pin('x', -20, 10), _pin('y', 20, -10)]);
    expect(_onMap(c), isEmpty, reason: 'the bubble left, the pins fly');
    final leave = c.sprites.singleWhere((s) => s.id.value == 'b');
    expect(leave.motion, SpriteMotion.leave);
    expect(leave.at(c.ms), isNotNull, reason: 'covers its gone marker');
    final fly = c.sprites.singleWhere((s) => s.id.value == 'x');
    expect(fly.motion, SpriteMotion.fly);
    expect(fly.from, _at(0, 0));
    expect(fly.to, _at(-20, 10));
    expect(fly.at(fly.start)!.at, _at(0, 0));
    _settle(c);
    expect(_onMap(c), {'x', 'y'});
  });

  test('zooming out: pins fly into their new bubble, which pops in', () {
    final c = MarkerChoreography();
    _update(c, [_pin('x', -20, 10), _pin('y', 20, -10)]);
    _settle(c);
    _update(c, [_bubble('b', 0, 0)]);
    final merges = c.sprites.where((s) => s.motion == SpriteMotion.merge);
    expect(merges.map((s) => s.id.value), unorderedEquals(['x', 'y']));
    expect(merges.first.to, _at(0, 0));
    final pop = c.sprites.singleWhere((s) => s.id.value == 'b');
    expect(pop.motion, SpriteMotion.pop);
    expect(pop.start, greaterThan(merges.first.start));
    _settle(c);
    expect(_onMap(c), {'b'});
  });

  test(
    'a touch lands everything at once, still drawn until the map has it',
    () {
      final c = MarkerChoreography();
      _update(c, [_pin('a', 0, 0), _pin('b', 100, 100)]);
      expect(c.active, isTrue);
      final act = c.finish();
      expect(_onMap(c), {'a', 'b'});
      // Each stands where it lands, whole: the map needs a few frames to draw
      // the markers just added, and dropping the sprites left it blank.
      expect(c.sprites, hasLength(2));
      for (final s in c.sprites) {
        final pose = s.at(c.ms)!;
        expect(pose.at, s.to);
        expect(pose.scale, 1);
        expect(pose.opacity, 1);
      }
      c.handedOver(act);
      expect(c.active, isFalse);
    },
  );

  test('reduced motion and the selected pin come at once', () {
    final c = MarkerChoreography();
    c.update(
      [_pin('a', 0, 0)],
      screen: _screen,
      centre: Offset.zero,
      animate: false,
    );
    expect(_onMap(c), {'a'});
    expect(c.active, isFalse);
    c.update(
      [_pin('a', 0, 0), _pin('selected', 10, 10)],
      screen: _screen,
      centre: Offset.zero,
      still: {const MarkerId('selected')},
    );
    expect(_onMap(c), {'a', 'selected'});
  });

  test('zooming in only opens bubbles, zooming out only gathers them', () {
    // Zooming in: the old bubble's place lies inside a new bubble's area, yet
    // it opens into the new ones rather than flying into one of them.
    final c = MarkerChoreography();
    _update(c, [_bubble('big', 0, 0, span: 60)]);
    _settle(c);
    c.update(
      [_bubble('a', 5, 5), _bubble('b', -40, -40)],
      zoomingIn: true,
      zoomingOut: false,
      screen: _screen,
      centre: Offset.zero,
    );
    expect(c.sprites.where((s) => s.motion == SpriteMotion.merge), isEmpty);
    expect(
      c.sprites
          .where((s) => s.motion == SpriteMotion.fly)
          .map((s) => s.id.value),
      unorderedEquals(['a', 'b']),
    );
    // Panning: nothing opens or gathers; newcomers simply come in.
    final p = MarkerChoreography();
    _update(p, [_bubble('big', 0, 0, span: 60)]);
    _settle(p);
    p.update(
      [_bubble('a', 5, 5)],
      zoomingIn: false,
      zoomingOut: false,
      screen: _screen,
      centre: Offset.zero,
    );
    expect(
      p.sprites.map((s) => s.motion),
      unorderedEquals([SpriteMotion.leave, SpriteMotion.pop]),
    );
  });

  test('under a finger: swapped at once, the old ones kept until the new '
      'ones are drawn', () {
    final c = MarkerChoreography();
    _update(c, [_bubble('b', 0, 0)]);
    _settle(c);
    c.update(
      [_pin('x', -20, 10), _pin('y', 20, -10)],
      screen: _screen,
      centre: Offset.zero,
      animate: false,
      linger: true,
    );
    expect(c.active, isFalse, reason: 'nothing flies under a finger');
    // A few at a time, nearest the middle first.
    expect(_onMap(c), isEmpty);
    expect(c.trickling, isTrue);
    c.trickle(1);
    expect(_onMap(c), {'x'});
    c.trickle(12);
    expect(c.trickling, isFalse);
    expect(_onMap(c), {'x', 'y'});
    expect(c.lingering, isTrue);
    expect(
      c.markers.map((m) => m.markerId.value),
      unorderedEquals(['b', 'x', 'y']),
      reason: 'the bubble stays until the map has drawn its pins',
    );
    // Back to the bubble before it left: it simply stays.
    c.update(
      [_bubble('b', 0, 0)],
      screen: _screen,
      centre: Offset.zero,
      animate: false,
      linger: true,
    );
    expect(_onMap(c), {'b'});
    c.dropLingering();
    expect(c.markers.map((m) => m.markerId.value), ['b']);
  });

  test('a capsule gone before it landed never reaches the map', () {
    final c = MarkerChoreography();
    _update(c, [_pin('a', 0, 0), _pin('b', 50, 0)]);
    _update(c, [_pin('a', 0, 0)]);
    expect(c.sprites.where((s) => s.id.value == 'b'), isEmpty);
    _settle(c);
    expect(_onMap(c), {'a'});
  });
}
