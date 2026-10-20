import 'dart:math' as math;

/// One capsule to group: where it is and its pin's colour.
class GroupPoint {
  const GroupPoint(this.id, this.latitude, this.longitude, this.color);

  final String id;
  final double latitude;
  final double longitude;
  final String color;
}

/// A pin (one capsule) or a bubble (several close together) at a level of
/// [CapsuleGroups]. Positions are Web Mercator world units (0 to 1 across
/// the world), the space the map draws in.
class GroupNode {
  GroupNode._({
    required this.id,
    required this.x,
    required this.y,
    required this.count,
    required this.color,
    required this.leafId,
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  });

  /// One capsule's pin, as every level holds it when it stands alone.
  factory GroupNode.pin(GroupPoint p) => GroupNode._leaf(p);

  factory GroupNode._leaf(GroupPoint p) => GroupNode._(
    id: p.id,
    x: worldX(p.longitude),
    y: worldY(p.latitude),
    count: 1,
    color: p.color,
    leafId: p.id,
    west: p.longitude,
    south: p.latitude,
    east: p.longitude,
    north: p.latitude,
  );

  factory GroupNode._group(int level, List<GroupNode> members) {
    var count = 0;
    var x = 0.0, y = 0.0;
    var west = 180.0, south = 90.0, east = -180.0, north = -90.0;
    for (final m in members) {
      count += m.count;
      x += m.x * m.count;
      y += m.y * m.count;
      west = math.min(west, m.west);
      south = math.min(south, m.south);
      east = math.max(east, m.east);
      north = math.max(north, m.north);
    }
    final seed = members.first;
    return GroupNode._(
      id: 'g$level:${seed.leafId}',
      x: x / count,
      y: y / count,
      count: count,
      color: null,
      leafId: seed.leafId,
      west: west,
      south: south,
      east: east,
      north: north,
    );
  }

  /// A capsule's id for a pin; for a bubble the level it formed at and its
  /// first capsule, so the same group keeps its id when the data changes a
  /// little.
  final String id;
  final double x;
  final double y;
  final int count;

  /// A pin's colour; null for a bubble.
  final String? color;

  /// The capsule a bubble grew from (a pin's own id).
  final String leafId;

  /// The area its capsules cover, in degrees (a bubble tap fits it).
  final double west;
  final double south;
  final double east;
  final double north;

  bool get isBubble => count > 1;
  double get longitude => longitudeOf(x);
  double get latitude => latitudeOf(y);

  static double worldX(double longitude) => (longitude + 180) / 360;

  static double worldY(double latitude) {
    final s = math.sin(latitude * math.pi / 180).clamp(-0.9999, 0.9999);
    return 0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi);
  }

  static double longitudeOf(double x) => x * 360 - 180;

  static double latitudeOf(double y) {
    final n = math.pi * (1 - 2 * y);
    return math.atan((math.exp(n) - math.exp(-n)) / 2) * 180 / math.pi;
  }
}

/// The capsules grouped level by level, the way MapLibre's own clustering
/// does it (supercluster: each capsule or bubble, in a fixed order, takes the
/// ungrouped ones within [radiusDp] of it at that level), but here, so each
/// bubble knows which pins and bubbles it came from: what the split and
/// merge animation moves (docs/map/DECISION.md, mission 2).
///
/// Level L is shown from zoom L − 0.5 up to L + 0.5 ([levelFor]): the shown
/// set changes half way between MapLibre's tile levels, never together with
/// them (new tiles with new symbols would crossfade: the "ghosts").
class CapsuleGroups {
  CapsuleGroups._(this._levels, this._up);

  /// Below it the map shows the heat only (markers fade in from zoom 11).
  static const minLevel = 10;

  /// From the next level on every capsule is its own pin.
  static const maxLevel = 17;

  /// How close (dp) capsules are grouped at their level.
  static const radiusDp = 60.0;

  /// The world's width in dp at zoom 0 (MapLibre's tiles are 512 dp).
  static const worldDp = 512.0;

  static final empty = CapsuleGroups.build(const []);

  /// What changed at [level] from [before] to [after]: the pieces that are
  /// new (they grow in) and those gone (they shrink away where they stood).
  /// A bubble that grew from the same capsule is the same bubble (its id
  /// also names the level it formed at, which a capsule joining can move):
  /// only its number changes, in place.
  static ({Set<String> added, Map<String, GroupNode> gone}) changes(
    CapsuleGroups before,
    CapsuleGroups after,
    int level,
  ) {
    final old = {for (final n in before.at(level)) n.id: n};
    final next = {for (final n in after.at(level)) n.id: n};
    final added = {
      for (final id in next.keys)
        if (!old.containsKey(id)) id,
    };
    final gone = {
      for (final MapEntry(key: id, value: n) in old.entries)
        if (!next.containsKey(id)) id: n,
    };
    final goneBubbles = {
      for (final n in gone.values)
        if (n.isBubble) n.leafId: n.id,
    };
    for (final id in [...added]) {
      final n = next[id]!;
      final was = n.isBubble ? goneBubbles.remove(n.leafId) : null;
      if (was == null) continue;
      added.remove(id);
      gone.remove(was);
    }
    return (added: added, gone: gone);
  }

  final Map<int, List<GroupNode>> _levels;

  /// For each level L: the node at L that holds each node of L + 1.
  final Map<int, Map<String, GroupNode>> _up;

  /// The level shown at [zoom].
  static int levelFor(double zoom) =>
      (zoom + 0.5).floor().clamp(minLevel, maxLevel + 1);

  /// What the map shows at [level].
  List<GroupNode> at(int level) =>
      _levels[level.clamp(minLevel, maxLevel + 1)]!;

  /// The node at [level] that holds [node], which is shown at [from]
  /// (a finer level); [node] itself when it stays on its own.
  GroupNode ancestor(GroupNode node, int from, int level) {
    var n = node;
    for (var l = from - 1; l >= level; l--) {
      n = _up[l]?[n.id] ?? n;
    }
    return n;
  }

  /// The first level above [level] at which [node] (shown at [level]) is no
  /// longer one piece; null when it never splits (its capsules stand on the
  /// same spot).
  int? splitsAt(GroupNode node, int level) {
    for (var l = level + 1; l <= maxLevel + 1; l++) {
      final holders = {
        for (final n in at(l))
          if (ancestor(n, l, level).id == node.id) n.id,
      };
      if (holders.length > 1) return l;
    }
    return null;
  }

  static CapsuleGroups build(Iterable<GroupPoint> points) {
    // A fixed order (by id), so a new capsule regroups only its neighbours.
    final sorted = [...points]..sort((a, b) => a.id.compareTo(b.id));
    var current = [for (final p in sorted) GroupNode._leaf(p)];
    final levels = <int, List<GroupNode>>{maxLevel + 1: current};
    final up = <int, Map<String, GroupNode>>{};
    for (var level = maxLevel; level >= minLevel; level--) {
      final r = radiusDp / (worldDp * math.pow(2, level));
      final cells = <(int, int), List<int>>{};
      for (var i = 0; i < current.length; i++) {
        final n = current[i];
        (cells[((n.x / r).floor(), (n.y / r).floor())] ??= []).add(i);
      }
      final taken = List<bool>.filled(current.length, false);
      final next = <GroupNode>[];
      final holder = <String, GroupNode>{};
      for (var i = 0; i < current.length; i++) {
        if (taken[i]) continue;
        taken[i] = true;
        final seed = current[i];
        final members = [seed];
        final cx = (seed.x / r).floor(), cy = (seed.y / r).floor();
        for (var dx = -1; dx <= 1; dx++) {
          for (var dy = -1; dy <= 1; dy++) {
            for (final j in cells[(cx + dx, cy + dy)] ?? const <int>[]) {
              if (taken[j]) continue;
              final o = current[j];
              final ex = o.x - seed.x, ey = o.y - seed.y;
              if (ex * ex + ey * ey > r * r) continue;
              taken[j] = true;
              members.add(o);
            }
          }
        }
        final node = members.length == 1
            ? seed
            : GroupNode._group(level, members);
        next.add(node);
        for (final m in members) {
          holder[m.id] = node;
        }
      }
      levels[level] = next;
      up[level] = holder;
      current = next;
    }
    return CapsuleGroups._(levels, up);
  }
}
