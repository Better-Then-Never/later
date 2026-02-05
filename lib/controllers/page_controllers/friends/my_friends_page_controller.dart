import 'dart:async';
import 'package:flutter/material.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/services/user_friends_service.dart';

class MyFriendsPageController extends ChangeNotifier {
  final UserFriendsService _friendsService;
  final UserDataService _userService;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  final List<Map<String, dynamic>> _friendsData = [];
  List<Map<String, dynamic>> get allFriendsData =>
      List.unmodifiable(_friendsData);

  Timer? _debounce;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  MyFriendsPageController({
    required UserFriendsService friendsService,
    required UserDataService userService,
  }) : _friendsService = friendsService,
       _userService = userService {
    _friendsService.addListener(_onServiceUpdate);
    _initialFetch = _preloadFriendsData();
  }

  late final Future<void> _initialFetch;
  Future<void> get initialFetch => _initialFetch;

  void _onServiceUpdate() {
    _preloadFriendsData();
  }

  void updateSearchQuery(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      notifyListeners();
    });
  }

  Set<String> get friendUids => _friendsService.friends;

  List<Map<String, dynamic>> get filteredFriends {
    if (_searchQuery.isEmpty) return List.unmodifiable(_friendsData);

    final query = _searchQuery.toLowerCase();
    return _friendsData.where((friend) {
      final name = (friend['name'] ?? '').toLowerCase();
      final username = (friend['username'] ?? '').toLowerCase();
      return name.contains(query) || username.contains(query);
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get groupedFilteredFriends {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    final seen = <String>{};
    for (var friend in filteredFriends) {
      if (seen.contains(friend['uid'])) continue;
      seen.add(friend['uid']);

      final letter = friend['name'][0].toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(friend);
    }
    final sorted = Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return sorted;
  }

Future<void> _preloadFriendsData() async {
  _isLoading = true;
  notifyListeners();

  final updatedFriends = <Map<String, dynamic>>[];

  for (var uid in _friendsService.friends) {
    final existing = _friendsData.firstWhere(
      (f) => f['uid'] == uid,
      orElse: () => {},
    );
    if (existing.isNotEmpty) {
      updatedFriends.add(existing);
      continue;
    }

    final data = await _userService.getUserData(uid);
    updatedFriends.add({
      'uid': uid,
      'name': data['name'] ?? '',
      'username': data['username'] ?? '',
    });
  }

  _friendsData
    ..clear()
    ..addAll(updatedFriends);

  _isLoading = false;
  notifyListeners();
}


  @override
  void dispose() {
    _debounce?.cancel();
    _friendsService.removeListener(_onServiceUpdate);
    super.dispose();
  }
}
