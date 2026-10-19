import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../../core/theme/app_motion.dart';
import 'capsule_groups.dart';

/// How a pin or bubble moves while the shown level changes. Nothing is ever
/// see-through: pieces grow and shrink, and come and go hidden under a
/// bubble (the bubbles are drawn over the pins, bigger bubbles over smaller
/// ones). A fade, squeezed into the tenth of a second of a fast zoom, read
/// as a flash (docs/map/FLASH_FIX.md).
enum FlightKind {
  /// A bubble opening (zooming in): it eases up a little, then shrinks away
  /// in place while its capsules leave it. Its number stays: a changing
  /// number is a new picture each time, and MapLibre rebuilt every tile's
  /// icons for it, holding the map for a few frames (FLASH_FIX.md).
  open,

  /// A pin or smaller bubble leaving the bubble it was in for its own spot,
  /// from under it, on a short arc, growing, with a small settle.
  fly,

  /// A pin or bubble flying into the bubble it joins (zooming out),
  /// shrinking; gone as it arrives, under the bubble.
  merge,

  /// The bubble they join, growing over them, with its number.
  form,

  /// A capsule caught mid-flight by the next change: on to its spot, whole.
  glide,
}

/// Where a flight is at a moment: world position, size (1 = as on the map),
/// opacity and, for a bubble, the number it shows.
class FlightFrame {
  const FlightFrame(this.x, this.y, this.scale, this.opacity, this.count);

  final double x;
  final double y;
  final double scale;
  final double opacity;
  final int count;
}

/// One pin or bubble drawn by the moving layer for a while.
class Flight {
  const Flight({
    required this.node,
    required this.kind,
    required this.fromX,
    required this.fromY,
    required this.toX,
    required this.toY,
    required this.start,
    required this.duration,
  });

  final GroupNode node;
  final FlightKind kind;
  final double fromX;
  final double fromY;
  final double toX;
  final double toY;

  /// Milliseconds on the transition's clock.
  final int start;
  final int duration;

  int get end => start + duration;

  /// A pin's landing: it overshoots its size a little and settles (the
  /// curve of the Google map's pop, M-03, made gentler).
  static const settle = Cubic(0.34, 1.3, 0.64, 1);

  /// A bubble forming: the pop of M-03.
  static const pop = Cubic(0.34, 1.56, 0.64, 1);

  /// How high the arc of a flying capsule rises, as a share of its way.
  static const arc = 0.18;

  /// Null when not drawn at [ms] (not started, or merged and gone).
  FlightFrame? at(int ms) {
    final t = duration <= 0 ? 1.0 : ((ms - start) / duration).clamp(0.0, 1.0);
    switch (kind) {
      case FlightKind.open:
        if (ms >= end) return null;
        final scale = t < 0.2
            ? 1 + 0.06 * AppMotion.enter.transform(t / 0.2)
            : 1.06 - 0.81 * AppMotion.exit.transform((t - 0.2) / 0.8);
        return FlightFrame(fromX, fromY, scale, 1, node.count);
      case FlightKind.fly:
        if (ms < start) return null;
        final k = AppMotion.enter.transform(t);
        final dx = toX - fromX, dy = toY - fromY;
        final lift = arc * math.sqrt(dx * dx + dy * dy) * math.sin(math.pi * k);
        return FlightFrame(
          fromX + dx * k,
          fromY + dy * k - lift,
          0.5 + 0.5 * settle.transform(t),
          1,
          node.count,
        );
      case FlightKind.merge:
        if (ms < start) return FlightFrame(fromX, fromY, 1, 1, node.count);
        if (ms >= end) return null;
        final k = AppMotion.standardCurve.transform(t);
        return FlightFrame(
          fromX + (toX - fromX) * k,
          fromY + (toY - fromY) * k,
          1 - 0.55 * k,
          1,
          node.count,
        );
      case FlightKind.glide:
        final k = AppMotion.enter.transform(t);
        return FlightFrame(
          fromX + (toX - fromX) * k,
          fromY + (toY - fromY) * k,
          1,
          1,
          node.count,
        );
      case FlightKind.form:
        if (ms < start) return null;
        return FlightFrame(
          toX,
          toY,
          0.4 + 0.6 * pop.transform(t),
          1,
          node.count,
        );
    }
  }
}

/// The motion from one shown level to another: what flies, and which nodes
/// of the new level wait in the moving layer instead of the still one.
class GroupTransition {
  const GroupTransition({
    required this.from,
    required this.to,
    required this.flights,
    required this.moving,
  });

  static const none = GroupTransition(from: 0, to: 0, flights: [], moving: {});

  final int from;
  final int to;
  final List<Flight> flights;

  /// Ids of the new level's nodes drawn by a flight until [end].
  final Set<String> moving;

  int get end => flights.fold(0, (e, f) => math.max(e, f.end));
  bool get isEmpty => flights.isEmpty;

  /// What the moving layer draws at [ms] (a landed capsule stays where it
  /// landed until the whole transition ends).
  Iterable<(Flight, FlightFrame)> frames(int ms) sync* {
    for (final f in flights) {
      final frame = f.at(ms);
      if (frame != null) yield (f, frame);
    }
  }

  /// Where [id] is drawn at [ms] (to start a new transition from there).
  (double, double)? positionOf(String id, int ms) {
    for (final f in flights) {
      if (f.node.id != id) continue;
      final frame = f.at(ms);
      if (frame != null) return (frame.x, frame.y);
    }
    return null;
  }
}

/// Plans the bubbles' split and merge (mission 2, §2.1): zooming in, each
/// bubble that splits opens while its capsules fly out of it to their own
/// spots; zooming out, the capsules fly into the bubble they join, which
/// grows in under them. Groups nearest the middle of the screen first, a few
/// tens of milliseconds apart. Only what is on screen moves (everything on
/// it: a phone screen holds far fewer than [limit] pieces). The faster the
/// zoom changes, the shorter the motion ([pace]); it is never skipped, so a
/// fast zoom out still gathers the capsules into their bubbles.
abstract final class GroupMotion {
  /// A safety bound on the moving pieces (each is one feature of the frame).
  static const limit = 400;

  /// How much of the full motion a change gets when the zoom moves at
  /// [zoomSpeed] levels a second: all of it up to 2, then less, down to a
  /// third (a flick: about 100 ms instead of 300).
  static double pace(double zoomSpeed) =>
      zoomSpeed <= 2 ? 1.0 : (2 / zoomSpeed).clamp(0.35, 1.0);

  /// A capsule caught mid-flight by the next change finishes its way in
  /// this long.
  static final catchUp = AppMotion.standard.inMilliseconds;

  /// Between groups, and between the capsules of one group.
  static const groupGap = 25;
  static const memberGap = 10;
  static const maxSpread = 120;

  static GroupTransition plan(
    CapsuleGroups groups, {
    required int from,
    required int to,
    required int now,
    required bool Function(GroupNode node) onScreen,
    required (double, double) centre,
    double zoomSpeed = 0,
    GroupTransition? previous,
  }) {
    if (from == to) return GroupTransition.none;
    final k = pace(zoomSpeed);
    int ms(Duration d) => (d.inMilliseconds * k).round();
    // A change while another runs starts from what is drawn now.
    (double, double)? drawnAt(String id) => previous?.positionOf(id, now);
    final zoomingIn = to > from;
    final fine = zoomingIn ? to : from;
    final coarse = zoomingIn ? from : to;
    // Each coarse node with the fine nodes it splits into (or gathers).
    final families = <String, (GroupNode, List<GroupNode>)>{};
    for (final n in groups.at(fine)) {
      final holder = groups.ancestor(n, fine, coarse);
      if (holder.id == n.id) continue;
      if (!onScreen(holder) && !onScreen(n)) continue;
      (families[holder.id] ??= (holder, <GroupNode>[])).$2.add(n);
    }
    double away(GroupNode n) {
      final dx = n.x - centre.$1, dy = n.y - centre.$2;
      return dx * dx + dy * dy;
    }

    final ordered = families.values.toList()
      ..sort((a, b) => away(a.$1).compareTo(away(b.$1)));
    final kept = <(GroupNode, List<GroupNode>)>[];
    var count = 0;
    for (final family in ordered) {
      final size = family.$2.length + 1;
      if (count + size > limit) break;
      kept.add(family);
      count += size;
    }

    final gap = kept.length <= 1
        ? 0
        : (math.min(groupGap, maxSpread ~/ (kept.length - 1)) * k).round();
    final memberStep = (memberGap * k).round();
    final flights = <Flight>[];
    final moving = <String>{};
    (double, double) at(GroupNode n) => drawnAt(n.id) ?? (n.x, n.y);
    for (var g = 0; g < kept.length; g++) {
      final (holder, members) = kept[g];
      final start = now + g * gap;
      // Around the holder, clockwise from north: a fan, not a burst.
      members.sort((a, b) {
        double angle(GroupNode n) => math.atan2(n.x - holder.x, holder.y - n.y);
        return angle(a).compareTo(angle(b));
      });
      if (zoomingIn) {
        final (hx, hy) = at(holder);
        for (var i = 0; i < members.length; i++) {
          final m = members[i];
          final s = start + i * memberStep;
          flights.add(
            Flight(
              node: m,
              kind: FlightKind.fly,
              fromX: hx,
              fromY: hy,
              toX: m.x,
              toY: m.y,
              start: s,
              duration: ms(AppMotion.slow),
            ),
          );
          moving.add(m.id);
        }
        flights.add(
          Flight(
            node: holder,
            kind: FlightKind.open,
            fromX: hx,
            fromY: hy,
            toX: hx,
            toY: hy,
            start: start,
            duration: ms(AppMotion.standard),
          ),
        );
      } else {
        final merge = ms(AppMotion.emphasized);
        for (var i = 0; i < members.length; i++) {
          final m = members[i];
          final (mx, my) = at(m);
          final s = start + i * memberStep;
          flights.add(
            Flight(
              node: m,
              kind: FlightKind.merge,
              fromX: mx,
              fromY: my,
              toX: holder.x,
              toY: holder.y,
              start: s,
              duration: merge,
            ),
          );
        }
        flights.add(
          Flight(
            node: holder,
            kind: FlightKind.form,
            fromX: holder.x,
            fromY: holder.y,
            toX: holder.x,
            toY: holder.y,
            start: start + (merge * 0.55).round(),
            duration: ms(AppMotion.emphasized),
          ),
        );
        moving.add(holder.id);
      }
    }
    if (previous != null) {
      final planned = {for (final f in flights) f.node.id};
      final shown = {for (final n in groups.at(to)) n.id: n};
      for (final f in previous.flights) {
        if (planned.contains(f.node.id)) continue;
        final leaving = f.kind == FlightKind.open || f.kind == FlightKind.merge;
        if (leaving) {
          // Going anyway: it finishes its own motion.
          if (f.end > now && !shown.containsKey(f.node.id)) flights.add(f);
          continue;
        }
        // Still on the map but caught mid-flight: on to its own spot.
        final node = shown[f.node.id];
        final drawn = f.at(now);
        if (node == null || drawn == null) continue;
        if (drawn.x == node.x && drawn.y == node.y) continue;
        flights.add(
          Flight(
            node: node,
            kind: FlightKind.glide,
            fromX: drawn.x,
            fromY: drawn.y,
            toX: node.x,
            toY: node.y,
            start: now,
            duration: (catchUp * k).round(),
          ),
        );
        planned.add(node.id);
        moving.add(node.id);
      }
    }
    return GroupTransition(
      from: from,
      to: to,
      flights: flights,
      moving: moving,
    );
  }
}
