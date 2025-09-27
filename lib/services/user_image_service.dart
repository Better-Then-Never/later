import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserImageService extends ChangeNotifier {
  final Map<String, ImageProvider> _cache = {};
  final Map<String, bool> _loading = {};

  final ImageProvider placeholder = const AssetImage(
    'assets/images/icons/navbar/icon-profile.png',
  );

  ImageProvider getProfileImage(String userId) {
    if (_cache.containsKey(userId)) {
      return _cache[userId]!;
    }

    if (!(_loading[userId] ?? false)) {
      _loading[userId] = true;
      _loadProfileImage(userId);
    }

    return placeholder;
  }

  Future<void> _loadProfileImage(String userId) async {
    try {
      final ref = FirebaseStorage.instance.ref(
        'userdata/$userId/assets/images/profile_image',
      );
      final url = await ref.getDownloadURL();

      _cache[userId] = NetworkImage(url);
    } catch (e) {
      _cache[userId] = placeholder;
    } finally {
      _loading[userId] = false;
      notifyListeners();
    }
  }
}
