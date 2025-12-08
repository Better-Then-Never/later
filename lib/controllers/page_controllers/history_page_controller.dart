import 'package:flutter/material.dart';

class HistoryPageController extends ChangeNotifier {
  List<Map<String, dynamic>> _allCapsules = [];
  String _searchQuery = '';
  bool isLoading = true;

  set capsules(List<Map<String, dynamic>> capsules) {
    _allCapsules = capsules;
    isLoading = false;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  String get searchQuery => _searchQuery;

  List<Map<String, dynamic>> get filteredCapsules {
    if (_searchQuery.isEmpty) return _allCapsules;
    return _allCapsules.where((c) {
      final title = (c['title'] ?? '').toString().toLowerCase();
      return title.contains(_searchQuery);
    }).toList();
  }
}
