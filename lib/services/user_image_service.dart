import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserImageService extends ChangeNotifier {
  final Map<String, ImageProvider> _profileCache = {};
  final Map<String, ImageProvider> _backgroundCache = {};

  final Map<String, bool> _profileLoading = {};
  final Map<String, bool> _backgroundLoading = {};

  final ImageProvider profilePlaceholder = const AssetImage(
    'assets/images/icons/navbar/icon-profile.png',
  );

  final ImageProvider backgroundPlaceholder = const AssetImage(
    'assets/images/icons/navbar/icon-profile.png',
  );

  ImageProvider getProfileImage(String userId) {
    if (_profileCache.containsKey(userId)) {
      return _profileCache[userId]!;
    }

    if (!(_profileLoading[userId] ?? false)) {
      _profileLoading[userId] = true;
      _loadProfileImage(userId);
    }

    return profilePlaceholder;
  }

  Future<void> _loadProfileImage(String userId) async {
    try {
      final ref = FirebaseStorage.instance.ref(
        'userdata/$userId/assets/images/profile_image',
      );
      final url = await ref.getDownloadURL();

      _profileCache[userId] = NetworkImage(url);
    } catch (e) {
      _profileCache[userId] = profilePlaceholder;
    } finally {
      _profileLoading[userId] = false;
      notifyListeners();
    }
  }

  ImageProvider getBackgroundImage(String userId) {
    if (_backgroundCache.containsKey(userId)) {
      return _backgroundCache[userId]!;
    }

    if (!(_backgroundLoading[userId] ?? false)) {
      _backgroundLoading[userId] = true;
      _loadBackgroundImage(userId);
    }

    return backgroundPlaceholder;
  }

  Future<void> _loadBackgroundImage(String userId) async {
    try {
      final ref = FirebaseStorage.instance.ref(
        'userdata/$userId/assets/images/background_image',
      );
      final url = await ref.getDownloadURL();

      _backgroundCache[userId] = NetworkImage(url);
    } catch (e) {
      _backgroundCache[userId] = backgroundPlaceholder;
    } finally {
      _backgroundLoading[userId] = false;
      notifyListeners();
    }
  }
}
