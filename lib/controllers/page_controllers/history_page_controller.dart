import 'package:flutter/material.dart';

class HistoryPageController extends ChangeNotifier {
  List<Map<String, dynamic>> _allCapsules = [];
  String _searchQuery = '';
  bool isLoading = true;

  final Set<String> _selectedIds = {};
  bool get isSelectionMode => _selectedIds.isNotEmpty;
  int get selectedCount => _selectedIds.length;

  bool isSelected(String id) => _selectedIds.contains(id);
  List<String> get selectedIds => _selectedIds.toList();
  String get searchQuery => _searchQuery;
  
  set capsules(List<Map<String, dynamic>> capsules) {
    _allCapsules = capsules;
    isLoading = false;
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  List<Map<String, dynamic>> get filteredCapsules {
    if (_searchQuery.isEmpty) return _allCapsules;
    return _allCapsules.where((c) {
      final title = (c['title'] ?? '').toString().toLowerCase();
      return title.contains(_searchQuery);
    }).toList();
  }
}
