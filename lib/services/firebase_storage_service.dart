import 'package:firebase_storage/firebase_storage.dart';
import 'package:later/services/cache_service.dart';

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String?> getProfileImageUrl(String userId) async {
    // Check cache first
    if (CacheService.hasImageUrl(userId)) {
      return CacheService.getCachedImageUrl(userId);
    }

    // Try optimized version first, then original
    final optimizedPath = 'userdata/$userId/assets/images/profile_image_small';
    final originalPath = 'userdata/$userId/assets/images/profile_image';

    try {
      final ref = _storage.ref().child(optimizedPath);
      final url = await ref.getDownloadURL();
      CacheService.setCachedImageUrl(userId, url);
      return url;
    } catch (e) {
      try {
        final ref = _storage.ref().child(originalPath);
        final url = await ref.getDownloadURL();
        CacheService.setCachedImageUrl(userId, url);
        return url;
      } catch (e) {
        CacheService.setCachedImageUrl(userId, null);
        return null;
      }
    }
  }

  static Future<String?> getOriginalProfileImageUrl(String userId) async {
    // Check cache first for original image
    final originalCacheKey = '${userId}_original';
    if (CacheService.hasImageUrl(originalCacheKey)) {
      return CacheService.getCachedImageUrl(originalCacheKey);
    }

    final originalPath = 'userdata/$userId/assets/images/profile_image';

    try {
      final ref = _storage.ref().child(originalPath);
      final url = await ref.getDownloadURL();
      // Cache the original image URL with a different key
      CacheService.setCachedImageUrl(originalCacheKey, url);
      return url;
    } catch (e) {
      // Fallback to optimized version
      final fallbackUrl = await getProfileImageUrl(userId);
      CacheService.setCachedImageUrl(originalCacheKey, fallbackUrl);
      return fallbackUrl;
    }
  }

  static Future<String?> getBackgroundImageUrl(String userId) async {
    // Check cache first for background image
    final bgCacheKey = '${userId}_bg';
    if (CacheService.hasImageUrl(bgCacheKey)) {
      return CacheService.getCachedImageUrl(bgCacheKey);
    }

    final path = 'userdata/$userId/assets/images/background_image';

    try {
      final ref = _storage.ref().child(path);
      final url = await ref.getDownloadURL().timeout(Duration(seconds: 10));
      CacheService.setCachedImageUrl(bgCacheKey, url);
      return url;
    } catch (e) {
      CacheService.setCachedImageUrl(bgCacheKey, null);
      return null;
    }
  }

  static Future<String?> getImageUrl(
    String userId, {
    bool useOptimized = true,
  }) async {
    return getProfileImageUrl(userId);
  }
}
