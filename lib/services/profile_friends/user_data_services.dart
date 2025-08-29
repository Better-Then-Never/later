import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:later/services/cache_firebase/cache_services.dart';

class UserDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static Future<Map<String, String>> getUserNameAndUsername(String userId) async {
    // Check cache first
    if (CacheService.hasUserData(userId)) {
      return CacheService.getCachedUserData(userId)!;
    }
    
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      final result = {
        'name': (data?['name'] ?? '').toString(),
        'username': (data?['username'] ?? '').toString(),
      };
      
      // Cache the result
      CacheService.setCachedUserData(userId, result);
      return result;
    } catch (e) {
      final fallback = {'name': 'Unknown User', 'username': 'unknown'};
      CacheService.setCachedUserData(userId, fallback);
      return fallback;
    }
  }
  
  static Future<DocumentSnapshot> getUserDocument(String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }
  
  static Future<List<DocumentSnapshot>> getUserDocuments(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    
    return await Future.wait(
      userIds.map((userId) => _firestore.collection('users').doc(userId).get()),
    );
  }
  
  static Future<List<String>> getUserFriends(String userId) async {
    try {
      final doc = await getUserDocument(userId);
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return List<String>.from(data['friends'] ?? []);
    } catch (e) {
      return [];
    }
  }
}