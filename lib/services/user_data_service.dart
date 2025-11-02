import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:later/services/user_image_service.dart';

class UserDataService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserImageService _userImageService;

  UserDataService(this._userImageService);

  final Map<String, Map<String, String>> _userCache = {};

  String? _currentUid;
  bool _isFetched = false;

  String get name => _userCache[_currentUid]?['name'] ?? 'Loading...';
  String get username => _userCache[_currentUid]?['username'] ?? 'Loading...';
  String get email => _userCache[_currentUid]?['email'] ?? 'Loading...';
  String get currentLoggedInUid => _currentUid ?? 'No User';
  bool get isFetched => _isFetched;

  Future<void> getCurrentUserProfile(String uid) async {
    _currentUid = uid;
    if (_isFetched) return;
    await getUserData(uid);
    _isFetched = true;
    notifyListeners();
  }

  Future<Map<String, String>> getUserData(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid]!;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data() ?? {};

      final result = {
        'id': uid,
        'name': (data['name'] ?? 'Unknown').toString(),
        'username': (data['username'] ?? 'unknown').toString(),
        'email': (data['email'] ?? 'unknown@example.com').toString(),
      };

      _userCache[uid] = result;

      // _userImageService.preloadProfileImageForUser(uid);

      return result;
    } catch (e) {
      final fallback = {
        'id': uid,
        'name': 'Unknown',
        'username': 'unknown',
        'email': 'unknown@example.com',
      };
      _userCache[uid] = fallback;

      // _userImageService.preloadBackgroundImageForUser(uid);

      return fallback;
    }
  }

  Future<List<String>> getUserFriends(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      return List<String>.from(data['friends'] ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateName(String uid, String newName) async {
    if (newName.trim().isEmpty) return false;
    try {
      await _firestore.collection('users').doc(uid).update({
        'name': newName.trim(),
      });
      _userCache[uid]?['name'] = newName.trim();
      if (uid == _currentUid) notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUsername(String uid, String newUsername) async {
    if (newUsername.trim().isEmpty) return false;
    try {
      await _firestore.collection('users').doc(uid).update({
        'username': newUsername.trim(),
      });
      _userCache[uid]?['username'] = newUsername.trim();
      if (uid == _currentUid) notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  void onLogout() {
    _userCache.clear();
    _currentUid = null;
    _isFetched = false;
    notifyListeners();
  }
}
