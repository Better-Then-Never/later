import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;

class AssetImageService {
  final Map<String, String?> _imageUrlCache = {};

  String _profileImagePath(String uid) =>
      "userdata/$uid/assets/images/profile_image";
  String _profileImageSmallPath(String uid) =>
      "userdata/$uid/assets/images/profile_image_small";
  String _backgroundImagePath(String uid) =>
      "userdata/$uid/assets/images/background_image";

  Future<Uint8List?> getProfileImage(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('profile_image');
    if (cached != null) return base64Decode(cached);

    try {
      final data = await FirebaseStorage.instance
          .ref()
          .child(_profileImagePath(uid))
          .getData();
      if (data != null) {
        await prefs.setString('profile_image', base64Encode(data));
      }
      return data;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveProfileImage(String uid, Uint8List imageBytes) async {
    final storageRef = FirebaseStorage.instance.ref();
    await storageRef.child(_profileImagePath(uid)).putData(imageBytes);

    final smallImage = await _resizeImage(imageBytes, maxSize: 128);
    await storageRef.child(_profileImageSmallPath(uid)).putData(smallImage);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image', base64Encode(imageBytes));
  }

  Future<void> deleteProfileImage(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_image');

    final storageRef = FirebaseStorage.instance.ref();
    await storageRef.child(_profileImagePath(uid)).delete();
    await storageRef.child(_profileImageSmallPath(uid)).delete();
  }

  Future<Uint8List?> getBackgroundImage(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('background_image');
    if (cached != null) return base64Decode(cached);

    try {
      final data = await FirebaseStorage.instance
          .ref()
          .child(_backgroundImagePath(uid))
          .getData();
      if (data != null) {
        await prefs.setString('background_image', base64Encode(data));
      }
      return data;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveBackgroundImage(String uid, Uint8List imageBytes) async {
    await FirebaseStorage.instance
        .ref()
        .child(_backgroundImagePath(uid))
        .putData(imageBytes);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('background_image', base64Encode(imageBytes));
  }

  Future<void> deleteBackgroundImage(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('background_image');

    await FirebaseStorage.instance
        .ref()
        .child(_backgroundImagePath(uid))
        .delete();
  }

  Future<String?> getProfileImageUrl(String userId) async {
    if (_imageUrlCache.containsKey(userId)) {
      return _imageUrlCache[userId];
    }

    final optimizedPath = 'userdata/$userId/assets/images/profile_image_small';
    final originalPath = 'userdata/$userId/assets/images/profile_image';

    try {
      final ref = FirebaseStorage.instance.ref().child(optimizedPath);
      final url = await ref.getDownloadURL();
      _imageUrlCache[userId] = url;
      return url;
    } catch (_) {
      try {
        final ref = FirebaseStorage.instance.ref().child(originalPath);
        final url = await ref.getDownloadURL();
        _imageUrlCache[userId] = url;
        return url;
      } catch (_) {
        _imageUrlCache[userId] = null;
        return null;
      }
    }
  }

  Future<void> clearLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_image');
    await prefs.remove('background_image');
  }

  Future<Uint8List> _resizeImage(
    Uint8List imageBytes, {
    int maxSize = 128,
  }) async {
    final original = img.decodeImage(imageBytes);
    if (original == null) return imageBytes;
    final resized = img.copyResize(original, width: maxSize, height: maxSize);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
  }
}
