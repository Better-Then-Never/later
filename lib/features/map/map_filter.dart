import '../../data/models/capsule.dart';

/// Whose capsules the map shows.
enum MapOwner { mine, friends, others }

/// Open capsules, and those that open later.
enum MapOpenState { open, locked }

/// What the map shows (B5): by whose, open or not, by pin colour. Empty
/// colours mean every colour. Kept per account on this phone.
class MapFilter {
  const MapFilter({
    this.owners = const {MapOwner.mine, MapOwner.friends, MapOwner.others},
    this.states = const {MapOpenState.open, MapOpenState.locked},
    this.colors = const {},
  });

  final Set<MapOwner> owners;
  final Set<MapOpenState> states;
  final Set<CapsuleColor> colors;

  static const all = MapFilter();

  /// Nothing is left out.
  bool get isDefault =>
      owners.length == MapOwner.values.length &&
      states.length == MapOpenState.values.length &&
      colors.isEmpty;

  /// How many kinds of choice narrow the map (for the button's badge).
  int get activeCount =>
      (owners.length == MapOwner.values.length ? 0 : 1) +
      (states.length == MapOpenState.values.length ? 0 : 1) +
      (colors.isEmpty ? 0 : 1);

  MapOwner ownerOf(Capsule c, String? uid) =>
      c.ownerId == uid || (uid != null && c.coAuthors.contains(uid))
      ? MapOwner.mine
      : c.privacy == CapsulePrivacy.friends
      ? MapOwner.friends
      : MapOwner.others;

  bool accepts(
    Capsule c, {
    required String? uid,
    required Set<String> friendIds,
    required DateTime now,
  }) {
    var owner = ownerOf(c, uid);
    // A friend's public capsule counts as a friend's.
    if (owner == MapOwner.others && friendIds.contains(c.ownerId)) {
      owner = MapOwner.friends;
    }
    if (!owners.contains(owner)) return false;
    final state = c.isOpen(now) ? MapOpenState.open : MapOpenState.locked;
    if (!states.contains(state)) return false;
    return colors.isEmpty || colors.contains(c.color);
  }

  MapFilter copyWith({
    Set<MapOwner>? owners,
    Set<MapOpenState>? states,
    Set<CapsuleColor>? colors,
  }) => MapFilter(
    owners: owners ?? this.owners,
    states: states ?? this.states,
    colors: colors ?? this.colors,
  );

  /// "mine,friends|open|red,blue" for the preferences.
  String encode() => [
    owners.map((o) => o.name).join(','),
    states.map((s) => s.name).join(','),
    colors.map((c) => c.name).join(','),
  ].join('|');

  static MapFilter decode(String? value) {
    if (value == null || value.isEmpty) return all;
    final parts = value.split('|');
    if (parts.length != 3) return all;
    Set<T> names<T extends Enum>(String part, List<T> values) => {
      for (final name in part.split(','))
        for (final v in values)
          if (v.name == name) v,
    };
    final owners = names(parts[0], MapOwner.values);
    final states = names(parts[1], MapOpenState.values);
    return MapFilter(
      // Never an empty map by accident.
      owners: owners.isEmpty ? all.owners : owners,
      states: states.isEmpty ? all.states : states,
      colors: names(parts[2], CapsuleColor.values),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MapFilter && encode() == other.encode();

  @override
  int get hashCode => encode().hashCode;
}
