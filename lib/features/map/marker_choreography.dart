import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/geo_position.dart';
import 'map_clusters.dart';

/// How a marker looks, to draw it in Flutter exactly as the map draws it:
/// its picture, its size in dp and its anchor (as [Marker.anchor]).
class MarkerLook {
  const MarkerLook(this.image, this.size, this.anchor);

  final ui.Image image;
  final Size size;
  final Offset anchor;
}

/// One marker the map page wants on the map, with what the choreography
/// needs to animate it: its [look] (none: it simply appears) and, for a
/// bubble, where its capsules are.
class ShownMarker {
  const ShownMarker(this.marker, {this.look, this.bounds});

  final Marker marker;
  final MarkerLook? look;
  final GeoBounds? bounds;

  MarkerId get id => marker.markerId;
  LatLng get at => marker.position;
}

enum SpriteMotion {
  /// Grows in place, with a little overshoot.
  pop,

  /// Flies out of the bubble it was in to its own spot, growing.
  fly,

  /// Shrinks and fades in place.
  leave,

  /// Flies into the bubble it joins, fading.
  merge,
}

/// A marker drawn by Flutter while it comes or goes (MarkerChoreography).
class MarkerSprite {
  MarkerSprite({
    required this.id,
    required this.look,
    required this.from,
    required this.to,
    required this.visibleFrom,
    required this.start,
    required this.duration,
    required this.motion,
    this.group,
  });

  final MarkerId id;
  final MarkerLook look;
  final LatLng from;
  final LatLng to;

  /// Drawn from [visibleFrom] (a leaving one at once, over the map's marker
  /// that is gone), moving from [start] for [duration] (ms on the clock).
  final int visibleFrom;
  final int start;
  final int duration;
  final SpriteMotion motion;

  /// The group it lands with (coming ones), handed to the map together.
  final int? group;

  int get end => start + duration;

  /// The same, already landed at [ms] (it stands where it lands).
  MarkerSprite landedBy(int ms) => MarkerSprite(
    id: id,
    look: look,
    from: from,
    to: to,
    visibleFrom: math.min(visibleFrom, ms - duration),
    start: math.min(start, ms - duration),
    duration: duration,
    motion: motion,
    group: group,
  );

  MarkerSprite inGroup(int group) => MarkerSprite(
    id: id,
    look: look,
    from: from,
    to: to,
    visibleFrom: visibleFrom,
    start: start,
    duration: duration,
    motion: motion,
    group: group,
  );
  bool get leaving =>
      motion == SpriteMotion.leave || motion == SpriteMotion.merge;

  static const _overshoot = Cubic(0.34, 1.56, 0.64, 1);

  /// Where it is, how big (1 = as on the map) and how opaque at [ms]; null
  /// when not drawn.
  ({LatLng at, double scale, double opacity})? at(int ms) {
    if (ms < visibleFrom) return null;
    final t = duration <= 0 ? 1.0 : ((ms - start) / duration).clamp(0.0, 1.0);
    switch (motion) {
      case SpriteMotion.pop:
        if (ms < start) return null;
        return (
          at: to,
          scale: _overshoot.transform(t),
          opacity: (t * 3).clamp(0.0, 1.0),
        );
      case SpriteMotion.fly:
        if (ms < start) return null;
        final k = Curves.easeOutCubic.transform(t);
        return (
          at: _lerp(from, to, k),
          scale: 0.45 + 0.55 * k,
          opacity: (t * 4).clamp(0.0, 1.0),
        );
      case SpriteMotion.leave:
        if (t >= 1) return null;
        final k = Curves.easeIn.transform(t);
        return (at: from, scale: 1 - 0.6 * k, opacity: 1 - k);
      case SpriteMotion.merge:
        if (t >= 1) return null;
        final k = Curves.easeInOutCubic.transform(t);
        return (
          at: _lerp(from, to, k),
          scale: 1 - 0.45 * k,
          opacity: t < 0.6 ? 1 : 1 - (t - 0.6) / 0.4,
        );
    }
  }

  static LatLng _lerp(LatLng a, LatLng b, double t) => LatLng(
    a.latitude + (b.latitude - a.latitude) * t,
    a.longitude + (b.longitude - a.longitude) * t,
  );
}

/// How capsules come onto the map and leave it (M-03, M-04): on the first
/// open they pop in group by group, in rings from the middle of the screen;
/// zooming in, each bubble's capsules fly out of it, one group after
/// another; zooming out, they fly into their new bubble, which pops in.
///
/// Native markers cannot be animated (a changed marker gets its bitmap
/// again and blinks), so Flutter draws the moving ones ([sprites]) over the
/// still map. The coming markers, and those off screen, are added to the map
/// together once every group has landed ([advance]), under the still
/// sprites, which go once the map has drawn them ([handedOver]): adding
/// markers holds up Android's main thread, where Flutter's frames come from,
/// so nothing may move meanwhile. A going one leaves the map at once, its
/// sprite drawn over it. When the map moves everything simply lands
/// ([finish]): the map reports its camera late, so sprites would trail it.
class MarkerChoreography {
  /// On the map now; coming (on the map when the act lands) and off screen
  /// meanwhile (with them).
  final Map<MarkerId, ShownMarker> onMap = {};
  final Map<MarkerId, ShownMarker> _coming = {};
  final Map<MarkerId, ShownMarker> _later = {};
  final List<MarkerSprite> sprites = [];

  /// The act under way (all its coming sprites carry it) and when it lands.
  int _act = 0;
  int _actEnd = 0;

  /// Milliseconds on the choreography clock (advanced by its overlay).
  int ms = 0;

  /// Something moves, or waits to land.
  bool get active =>
      sprites.isNotEmpty || _coming.isNotEmpty || _later.isNotEmpty;

  /// Between groups, at most; fewer groups wait longer for each other up to
  /// this, many share [_maxSpread].
  static const _gap = 100;
  static const _maxSpread = 600;
  static const popMs = 360;
  static const flyMs = 380;
  static const leaveMs = 170;
  static const mergeMs = 300;

  /// Rings of this width (dp) from the middle form the groups that pop in
  /// place.
  static const ringDp = 90.0;

  /// The map should show [target]. [screen] says where a place is on
  /// screen (null when off it) and [centre] is the middle of the screen;
  /// those in [still] (the selected pin) and those off screen come and go
  /// at once, and so does everything when not [animate] (reduced motion).
  void update(
    Iterable<ShownMarker> target, {
    required Offset? Function(LatLng) screen,
    required Offset centre,
    Set<MarkerId> still = const {},
    bool animate = true,
  }) {
    final wanted = {for (final t in target) t.id: t};
    final gone = [
      for (final s in onMap.values)
        if (!wanted.containsKey(s.id)) s,
    ];
    for (final s in gone) {
      onMap.remove(s.id);
      sprites.removeWhere((p) => p.id == s.id);
    }
    _coming.removeWhere((id, _) => !wanted.containsKey(id));
    _later.removeWhere((id, _) => !wanted.containsKey(id));
    sprites.removeWhere((p) => !p.leaving && !wanted.containsKey(p.id));
    final added = <ShownMarker>[];
    for (final t in wanted.values) {
      if (onMap.containsKey(t.id)) {
        onMap[t.id] = t;
      } else if (_coming.containsKey(t.id)) {
        _coming[t.id] = t;
      } else if (_later.containsKey(t.id)) {
        _later[t.id] = t;
      } else {
        added.add(t);
      }
    }

    final moving = <ShownMarker>[];
    final unseen = <ShownMarker>[];
    for (final a in added) {
      if (!animate || still.contains(a.id) || a.look == null) {
        onMap[a.id] = a;
      } else if (screen(a.at) == null) {
        unseen.add(a);
      } else {
        moving.add(a);
      }
    }
    // Off screen they need no show, but they wait for the act so the map is
    // not busy adding them while capsules move.
    final acting = moving.isNotEmpty || _coming.isNotEmpty;
    for (final u in unseen) {
      (acting ? _later : onMap)[u.id] = u;
    }
    final leaving = [
      for (final g in gone)
        if (animate && g.look != null && screen(g.at) != null) g,
    ];
    if (moving.isEmpty && leaving.isEmpty) return;

    // Who came out of which bubble (zooming in), who goes into which
    // (zooming out): the nearest bubble whose capsules' area holds them.
    ShownMarker? holder(LatLng at, Iterable<ShownMarker> bubbles) {
      ShownMarker? best;
      var bestD = double.infinity;
      for (final b in bubbles) {
        final bounds = b.bounds;
        if (bounds == null || !bounds.contains(_geo(at))) continue;
        final d = _distance(b.at, at);
        if (d < bestD) {
          best = b;
          bestD = d;
        }
      }
      return best;
    }

    final splitting = <MarkerId, List<ShownMarker>>{};
    final popping = <ShownMarker>[];
    final joining = <MarkerId, List<ShownMarker>>{};
    final newBubbles = [
      for (final m in moving)
        if (m.bounds != null) m,
    ];
    final joined = <MarkerId>{};
    for (final g in leaving) {
      final into = holder(g.at, newBubbles);
      if (into != null && into.id != g.id) {
        (joining[into.id] ??= []).add(g);
        joined.add(g.id);
      }
    }
    final byId = {for (final m in moving) m.id: m};
    final parents = [
      for (final g in leaving)
        if (g.bounds != null && !joined.contains(g.id)) g,
    ];
    for (final m in moving) {
      if (joining.containsKey(m.id)) continue;
      final from = holder(m.at, parents);
      if (from != null) {
        (splitting[from.id] ??= []).add(m);
      } else {
        popping.add(m);
      }
    }
    // Neither joining a bubble nor opening into pins: they just go.
    final leftAlone = [
      for (final g in leaving)
        if (!joined.contains(g.id) && !splitting.containsKey(g.id)) g,
    ];
    final goneById = {for (final g in leaving) g.id: g};

    // The groups, nearest the middle first.
    final groups = <({Offset where, void Function(int start) play})>[];
    for (final MapEntry(key: bubbleId, value: children) in splitting.entries) {
      final bubble = goneById[bubbleId]!;
      groups.add((
        where: screen(bubble.at)!,
        play: (start) {
          sprites.add(_sprite(bubble, SpriteMotion.leave, start, leaveMs));
          for (final c in children) {
            _coming[c.id] = c;
            _addTo(_sprite(c, SpriteMotion.fly, start, flyMs, from: bubble.at));
          }
        },
      ));
    }
    for (final MapEntry(key: bubbleId, value: members) in joining.entries) {
      final bubble = byId[bubbleId]!;
      groups.add((
        where: screen(bubble.at)!,
        play: (start) {
          for (final m in members) {
            sprites.add(
              _sprite(m, SpriteMotion.merge, start, mergeMs, to: bubble.at),
            );
          }
          _coming[bubble.id] = bubble;
          _addTo(
            _sprite(
              bubble,
              SpriteMotion.pop,
              start + (mergeMs * 0.7).round(),
              popMs,
            ),
          );
        },
      ));
    }
    final rings = <int, List<ShownMarker>>{};
    for (final p in popping) {
      final d = (screen(p.at)! - centre).distance;
      (rings[(d / ringDp).floor()] ??= []).add(p);
    }
    for (final MapEntry(key: ring, value: members) in rings.entries) {
      groups.add((
        where: centre + Offset(0, ring * ringDp),
        play: (start) {
          for (final p in members) {
            _coming[p.id] = p;
            _addTo(_sprite(p, SpriteMotion.pop, start, popMs));
          }
        },
      ));
    }
    for (final g in leftAlone) {
      sprites.add(_sprite(g, SpriteMotion.leave, ms, leaveMs));
    }

    groups.sort(
      (a, b) =>
          (a.where - centre).distance.compareTo((b.where - centre).distance),
    );
    final gap = groups.length <= 1
        ? 0
        : math.min(_gap, _maxSpread ~/ (groups.length - 1));
    for (var i = 0; i < groups.length; i++) {
      groups[i].play(ms + i * gap);
    }
  }

  /// [s] comes in this act: drawn, and the act lands once it has.
  void _addTo(MarkerSprite s) {
    sprites.add(s.inGroup(_act));
    _actEnd = math.max(_actEnd, s.end);
  }

  MarkerSprite _sprite(
    ShownMarker m,
    SpriteMotion motion,
    int start,
    int duration, {
    LatLng? from,
    LatLng? to,
  }) {
    final leaving =
        motion == SpriteMotion.leave || motion == SpriteMotion.merge;
    return MarkerSprite(
      id: m.id,
      look: m.look!,
      from: from ?? m.at,
      to: to ?? m.at,
      // A going marker is gone from the map at once: its sprite covers it
      // from now; a coming one shows when its motion starts.
      visibleFrom: leaving ? ms : start,
      start: start,
      duration: duration,
      motion: motion,
    );
  }

  /// Advances the clock to [now]. Once every coming capsule has landed,
  /// they and those off screen are on the map (their sprites stay still
  /// until [handedOver]); returns that act, or null.
  int? advance(int now) {
    ms = now;
    sprites.removeWhere((s) => s.leaving && now >= s.end);
    if (now < _actEnd || (_coming.isEmpty && _later.isEmpty)) return null;
    onMap
      ..addAll(_coming)
      ..addAll(_later);
    _coming.clear();
    _later.clear();
    return _act++;
  }

  /// The map has drawn [act]'s markers: their sprites go.
  void handedOver(int act) =>
      sprites.removeWhere((s) => s.group == act && !s.leaving);

  /// Everything onto the map at once (a finger touches the map): the coming
  /// ones stand where they land until the map has drawn them ([handedOver]
  /// with the returned act), the going ones are gone. Dropping them all at
  /// once left the map blank for a few frames while it drew the new markers.
  int finish() {
    onMap
      ..addAll(_coming)
      ..addAll(_later);
    _coming.clear();
    _later.clear();
    sprites
      ..removeWhere((s) => s.leaving)
      ..replaceRange(0, sprites.length, [
        for (final s in sprites) s.landedBy(ms),
      ]);
    _actEnd = 0;
    return _act++;
  }

  static GeoPosition _geo(LatLng p) => GeoPosition(p.latitude, p.longitude);

  static double _distance(LatLng a, LatLng b) {
    final dx = a.longitude - b.longitude;
    final dy = a.latitude - b.latitude;
    return dx * dx + dy * dy;
  }
}
