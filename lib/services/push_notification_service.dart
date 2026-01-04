import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isInitialized = false;

  // Store notifications for display in app
  final List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;

  Future<void> initialize() async {
    if (_isInitialized) {
      print('Already initialized');
      return;
    }

    try {
      print('Starting initialization...');

      // Initialize local notifications FIRST
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final bool? initialized = await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      print('Local notifications initialized: $initialized');

      if (initialized != true && initialized != null) {
        print('Failed to initialize local notifications');
        return;
      }

      // Create notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      print('Notification channel created');

      // Request permission for iOS and Firebase
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
      } else {
        print('User declined or has not accepted permission');
      }

      // Get FCM token and save to Firestore
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');
      
      if (token != null) {
        await _saveFcmToken(token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_saveFcmToken);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Handle terminated state messages
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }

      _isInitialized = true;
      print('Push notification service initialized successfully');
    } catch (e) {
      print('Error initializing push notifications: $e');
      rethrow;
    }
  }

  Future<void> _saveFcmToken(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('No user logged in, cannot save FCM token');
        return;
      }

      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      
      print('FCM token saved to Firestore for user: $userId');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message received: ${message.notification?.title}');
    
    // Add to local storage
    _addNotification(message);

    // Show local notification
    _showLocalNotification(message);
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('Background message opened: ${message.notification?.title}');
    _addNotification(message);
  }

  void _addNotification(RemoteMessage message) {
    _notifications.insert(0, {
      'id': null, 
      'type': message.data['type'] ?? 'notification',
      'userName': message.data['userName'] ?? 'System',
      'userAvatar': message.data['userAvatar'], 
      'message': message.notification?.body ?? '',
      'thumbnailImage': message.data['thumbnailImage'],
      'timestamp': DateTime.now(),
      'isRead': false,
      'title': message.notification?.title ?? 'Notification',
      'userId': message.data['userId'], 
      'capsuleId': message.data['capsuleId'], 
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (!_isInitialized) {
      print('Notifications not initialized');
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      platformDetails,
      payload: message.data.toString(),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // TODO: Navigate to specific screen based on notification type
  }

  Future<void> markAsRead(int index) async {
    if (index >= _notifications.length) return;

    try {
      // Create a mutable copy of the notification
      final notification = Map<String, dynamic>.from(_notifications[index]);
      notification['isRead'] = true;
      _notifications[index] = notification;

      // Update in Firestore to persist
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      final notificationId = notification['id'];
      if (notificationId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});
        
        print('Notification marked as read in Firestore');
      }
    } catch (e) {
      print('Error updating notification read status: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Update local state
      for (int i = 0; i < _notifications.length; i++) {
        final notification = Map<String, dynamic>.from(_notifications[i]);
        notification['isRead'] = true;
        _notifications[i] = notification;
      }

      // Update in Firestore
      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print('All notifications marked as read');
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  void clearAll() {
    _notifications.clear();
  }

  Future<void> deleteNotification(int index) async {
    if (index >= _notifications.length) return;

    try {
      final notification = _notifications[index];
      final notificationId = notification['id'];

      // Remove from local list
      _notifications.removeAt(index);

      // Delete from Firestore
      if (notificationId != null) {
        final userId = _auth.currentUser?.uid;
        if (userId != null) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .doc(notificationId)
              .delete();
          
          print('Notification deleted from Firestore');
        }
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Load notifications from Firestore
  Future<void> loadNotificationsFromFirestore() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      _notifications.clear();
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        _notifications.add({
          'id': doc.id, // Store the document ID for updates
          'type': data['type'] ?? 'notification',
          'userName': data['fromUserName'] ?? 'System',
          'userAvatar': data['fromUserAvatar'] ?? 'assets/images/default_avatar.png',
          'message': data['message'] ?? '',
          'thumbnailImage': data['thumbnailImage'],
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'isRead': data['isRead'] ?? false,
          'title': _getNotificationTitle(data['type']),
          'userId': data['fromUserId'],
          'capsuleId': data['capsuleId'],
        });
      }

      print('Loaded ${_notifications.length} notifications from Firestore');
    } catch (e) {
      print('Error loading notifications from Firestore: $e');
    }
  }

  // Get unread notification count
  int get unreadCount {
    return _notifications.where((n) => n['isRead'] == false).length;
  }

  String _getNotificationTitle(String? type) {
    switch (type) {
      case 'follow':
        return 'New Follower';
      case 'capsule':
        return 'New Capsule';
      case 'like':
        return 'New Like';
      case 'comment':
        return 'New Comment';
      case 'reply':
        return 'New Reply';
      default:
        return 'Notification';
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}