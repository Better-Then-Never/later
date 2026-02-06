class CacheService {
  static final Map<String, String?> _imageUrlCache = {};

  static String? getCachedImageUrl(String userId) {
    return _imageUrlCache[userId];
  }

  static void setCachedImageUrl(String userId, String? url) {
    _imageUrlCache[userId] = url;
  }

  static bool hasImageUrl(String userId) {
    return _imageUrlCache.containsKey(userId);
  }
}
