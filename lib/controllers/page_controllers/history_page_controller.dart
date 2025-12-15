import 'package:flutter/material.dart';
import 'package:later/data/models/time_capsule.dart';

enum SortMode { none, relevance, distance }

enum SortOrder { none, oldest, newest, closest, farthest }

enum FilterMode { none, color, visibility }

class HistoryPageController extends ChangeNotifier {
  List<Map<String, dynamic>> _allCapsules = [];
  String _searchQuery = '';
  bool isLoading = true;

  final Set<String> _selectedIds = {};
  bool get isSelectionMode => _selectedIds.isNotEmpty;
  int get selectedCount => _selectedIds.length;

  SortMode sortMode = SortMode.none;
  SortOrder sortOrder = SortOrder.none;

  FilterMode filterMode = FilterMode.none;
  CapsuleColor? colorFilter;
  CapsulePrivacy? privacyFilter;

  bool isSelected(String id) => _selectedIds.contains(id);
  List<String> get selectedIds => _selectedIds.toList();
  String get searchQuery => _searchQuery;

  set capsules(List<Map<String, dynamic>> capsules) {
    _allCapsules = capsules;
    isLoading = false;
    notifyListeners();
  }

  void toggleSelection(String id) {
    _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id);
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  void setSort(SortMode mode, SortOrder order) {
    sortMode = mode;
    sortOrder = order;
    notifyListeners();
  }

  void setColorFilter(CapsuleColor color) {
    filterMode = FilterMode.color;
    colorFilter = color;
    notifyListeners();
  }

  void setPrivacyFilter(CapsulePrivacy privacy) {
    filterMode = FilterMode.visibility;
    privacyFilter = privacy;
    notifyListeners();
  }

  void resetSortAndFilter() {
    sortMode = SortMode.none;
    sortOrder = SortOrder.none;
    filterMode = FilterMode.none;
    colorFilter = null;
    privacyFilter = null;
    notifyListeners();
  }

  String get activeSortLabel {
    if (sortMode == SortMode.none || sortOrder == SortOrder.none) {
      return 'Sort By';
    }

    switch (sortMode) {
      case SortMode.relevance:
        return sortOrder == SortOrder.oldest ? 'From Oldest' : 'From Newest';
      case SortMode.distance:
        return sortOrder == SortOrder.closest
            ? 'From Closest'
            : 'From Farthest';
      default:
        return 'Sort By';
    }
  }

  String get activeFilterLabel {
    final parts = <String>[];
    if (colorFilter != null) parts.add(colorFilter!.label);
    if (privacyFilter != null) parts.add(privacyFilter!.label);
    if (parts.isEmpty) return 'Filter By';
    return parts.join(' · ');
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  List<Map<String, dynamic>> get filteredCapsules {
    List<Map<String, dynamic>> result = [..._allCapsules];

    // SEARCH
    if (_searchQuery.isNotEmpty) {
      result = result.where((c) {
        final title = (c['title'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery);
      }).toList();
    }

    // COLOR FILTER
    if (colorFilter != null) {
      result = result.where((c) => c['color'] == colorFilter!.name).toList();
    }

    // VISIBILITY FILTER
    if (privacyFilter != null) {
      result = result
          .where((c) => c['privacy'] == privacyFilter!.name)
          .toList();
    }

    // SORTING
    if (sortMode == SortMode.relevance) {
      if (sortOrder == SortOrder.oldest) {
        result.sort((a, b) => a['createdAt'].compareTo(b['createdAt']));
      } else if (sortOrder == SortOrder.newest) {
        result.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
      }
    }

    if (sortMode == SortMode.distance) {
      if (sortOrder == SortOrder.closest) {
        // result.sort((a, b) => a['distance'].compareTo(b['distance']));
      } else if (sortOrder == SortOrder.farthest) {
        // result.sort((a, b) => b['distance'].compareTo(a['distance']));
      }
    }

    return result;
  }
}
