class CacheService {
  static final Map<String, String?> _imageUrlCache = {};
  static final Map<String, Map<String, String>> _userDataCache = {};
  
  // Image URL caching
  static String? getCachedImageUrl(String userId) {
    return _imageUrlCache[userId];
  }
  
  static void setCachedImageUrl(String userId, String? url) {
    _imageUrlCache[userId] = url;
  }
  
  static bool hasImageUrl(String userId) {
    return _imageUrlCache.containsKey(userId);
  }
  
  // User data caching
  static Map<String, String>? getCachedUserData(String userId) {
    return _userDataCache[userId];
  }
  
  static void setCachedUserData(String userId, Map<String, String> data) {
    _userDataCache[userId] = data;
  }
  
  static bool hasUserData(String userId) {
    return _userDataCache.containsKey(userId);
  }
  
  static void clearCache() {
    _imageUrlCache.clear();
    _userDataCache.clear();
  }
  
  static void clearUserCache(String userId) {
    _imageUrlCache.remove(userId);
    _userDataCache.remove(userId);
  }
}