import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/l10n/l10n.dart';
import '../../data/models/capsule.dart';
import '../../data/models/geo_position.dart';
import 'capsule_labels.dart';

enum HistorySort {
  /// Repository order: newest first.
  none,
  oldest,
  newest,
  closest,
  farthest;

  /// Menu and button label in the app's language ([AppL10n.current] when
  /// [l10n] is null); null for [none].
  String? label([AppLocalizations? l10n]) {
    final strings = l10n ?? AppL10n.current;
    return switch (this) {
      HistorySort.none => null,
      HistorySort.oldest => strings.historySortOldest,
      HistorySort.newest => strings.historySortNewest,
      HistorySort.closest => strings.historySortClosest,
      HistorySort.farthest => strings.historySortFarthest,
    };
  }
}

/// Search, sort, filter and selection state of the History page. The list
/// itself lives in OwnCapsulesStore; [apply] derives what is shown.
class HistoryController extends ChangeNotifier {
  String _query = '';
  HistorySort _sort = HistorySort.none;
  CapsuleColor? _colorFilter;
  CapsulePrivacy? _privacyFilter;
  bool _favoritesOnly = false;
  final Set<String> _selected = {};

  String get searchQuery => _query;
  HistorySort get sort => _sort;
  CapsuleColor? get colorFilter => _colorFilter;
  CapsulePrivacy? get privacyFilter => _privacyFilter;
  bool get favoritesOnly => _favoritesOnly;

  bool get isSelectionMode => _selected.isNotEmpty;

  /// A search or filter narrows the list (sorting does not).
  bool get isNarrowed =>
      _query.trim().isNotEmpty ||
      _colorFilter != null ||
      _privacyFilter != null ||
      _favoritesOnly;
  int get selectedCount => _selected.length;
  Set<String> get selectedIds => Set.unmodifiable(_selected);
  bool isSelected(String id) => _selected.contains(id);

  /// Text of the sort button: the chosen sort or "Sort By". Widgets pass
  /// `context.l10n`; without it [AppL10n.current] is used.
  String activeSortLabel([AppLocalizations? l10n]) {
    final strings = l10n ?? AppL10n.current;
    return _sort.label(strings) ?? strings.historySortBy;
  }

  /// Text of the filter button: the active filters or "Filter By".
  String activeFilterLabel([AppLocalizations? l10n]) {
    final strings = l10n ?? AppL10n.current;
    final parts = [
      ?_colorFilter?.localizedLabel(strings),
      ?_privacyFilter?.localizedLabel(strings),
      if (_favoritesOnly) strings.historyFilterFavorite,
    ];
    return parts.isEmpty ? strings.historyFilterBy : parts.join(' · ');
  }

  void updateSearchQuery(String query) {
    final next = query.trim().toLowerCase();
    if (next == _query) return;
    _query = next;
    notifyListeners();
  }

  void setSort(HistorySort sort) {
    _sort = sort;
    notifyListeners();
  }

  void setColorFilter(CapsuleColor color) {
    _colorFilter = color;
    notifyListeners();
  }

  void setPrivacyFilter(CapsulePrivacy privacy) {
    _privacyFilter = privacy;
    notifyListeners();
  }

  void setFavoritesOnly(bool value) {
    _favoritesOnly = value;
    notifyListeners();
  }

  void resetSort() => setSort(HistorySort.none);

  void resetFilters() {
    _colorFilter = null;
    _privacyFilter = null;
    _favoritesOnly = false;
    notifyListeners();
  }

  void resetAll() {
    _sort = HistorySort.none;
    resetFilters();
  }

  void toggleSelection(String id) {
    if (!_selected.remove(id)) _selected.add(id);
    notifyListeners();
  }

  void clearSelection() {
    if (_selected.isEmpty) return;
    _selected.clear();
    notifyListeners();
  }

  /// Drops selected ids that are no longer in the list (deleted elsewhere).
  void retainSelection(Iterable<String> existingIds) {
    final before = _selected.length;
    _selected.retainAll(existingIds.toSet());
    if (_selected.length != before) notifyListeners();
  }

  /// The capsules to show, given the live list, the favourite ids and the
  /// user's position (needed for the distance sort only).
  List<Capsule> apply(
    List<Capsule> capsules, {
    Set<String> favorites = const {},
    GeoPosition? from,
  }) {
    final result = capsules.where((c) {
      if (_query.isNotEmpty && !c.title.toLowerCase().contains(_query)) {
        return false;
      }
      if (_colorFilter != null && c.color != _colorFilter) return false;
      if (_privacyFilter != null && c.privacy != _privacyFilter) return false;
      if (_favoritesOnly && !favorites.contains(c.id)) return false;
      return true;
    }).toList();

    switch (_sort) {
      case HistorySort.none:
        break;
      case HistorySort.oldest:
        result.sort((a, b) => _createdCompare(a, b));
      case HistorySort.newest:
        result.sort((a, b) => _createdCompare(b, a));
      case HistorySort.closest:
      case HistorySort.farthest:
        if (from != null) {
          final closest = _sort == HistorySort.closest;
          result.sort((a, b) {
            final da = distanceMeters(from, a.location);
            final db = distanceMeters(from, b.location);
            // Capsules without a location always go last.
            if (da == null || db == null) {
              return da == null ? (db == null ? 0 : 1) : -1;
            }
            return closest ? da.compareTo(db) : db.compareTo(da);
          });
        }
    }
    return result;
  }

  /// A pending server timestamp (null) means "just created": newest.
  static int _createdCompare(Capsule a, Capsule b) {
    final ta = a.createdAt, tb = b.createdAt;
    if (ta == null || tb == null) {
      return ta == null ? (tb == null ? 0 : 1) : -1;
    }
    return ta.compareTo(tb);
  }

  static double? distanceMeters(GeoPosition? from, GeoPosition? to) {
    if (from == null || to == null) return null;
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }
}
