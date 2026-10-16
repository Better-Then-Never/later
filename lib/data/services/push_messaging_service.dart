import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/logging/app_logger.dart';
import '../models/app_notification.dart';
import '../../core/theme/app_colors.dart';

/// Must be top-level and annotated so it survives tree shaking; registered in
/// bootstrap before runApp. The OS shows `notification` payloads itself while
/// the app is in the background, so nothing else is needed here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// What a tapped notification points to.
class NotificationTap {
  const NotificationTap({required this.type, this.userId, this.capsuleId});

  /// Reads the `data` map sent by the Cloud Functions
  /// (`type`, `userId`, `capsuleId`).
  factory NotificationTap.fromData(Map<String, dynamic> data) =>
      NotificationTap(
        type: NotificationType.parse(data['type']),
        userId: _nonEmpty(data['userId']),
        capsuleId: _nonEmpty(data['capsuleId']),
      );

  factory NotificationTap.fromNotification(AppNotification n) =>
      NotificationTap(
        type: n.type,
        userId: n.fromUserId,
        capsuleId: n.capsuleId,
      );

  final NotificationType type;
  final String? userId;
  final String? capsuleId;

  static String? _nonEmpty(Object? v) => v is String && v.isNotEmpty ? v : null;
}

/// FCM + local notifications: permission, token, foreground display and tap
/// events for all three app states (foreground, background, terminated).
class PushMessagingService {
  PushMessagingService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messagingOverride = messaging,
       _local = localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging? _messagingOverride;
  final FlutterLocalNotificationsPlugin _local;

  FirebaseMessaging get _messaging =>
      _messagingOverride ?? FirebaseMessaging.instance;

  static const channelId = 'high_importance_channel';
  static const _channelName = 'High Importance Notifications';
  static const _channelDescription =
      'This channel is used for important notifications';

  final _taps = StreamController<NotificationTap>.broadcast();
  final List<StreamSubscription<RemoteMessage>> _subscriptions = [];
  NotificationTap? _initialTap;
  Future<void>? _initialized;

  /// Taps on notifications while the app is running (foreground local
  /// notifications and FCM notifications opened from the background).
  Stream<NotificationTap> get taps => _taps.stream;

  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  /// The notification that launched the app from a terminated state, once.
  NotificationTap? takeInitialTap() {
    final tap = _initialTap;
    _initialTap = null;
    return tap;
  }

  /// Idempotent; never throws (push is optional for the app to work).
  Future<void> initialize() => _initialized ??= _initialize();

  Future<void> _initialize() async {
    try {
      await _local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings(
            '@drawable/ic_stat_notification',
          ),
          // Permission is requested by the permission gate, not at startup.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) =>
            _onLocalTap(response.payload),
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              channelId,
              _channelName,
              description: _channelDescription,
              importance: Importance.max,
            ),
          );

      // iOS shows FCM banners in the foreground only with these options; the
      // app displays its own local notification instead, like on Android.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );

      _subscriptions
        ..add(FirebaseMessaging.onMessage.listen(_showForeground))
        ..add(
          FirebaseMessaging.onMessageOpenedApp.listen(
            (m) => _taps.add(NotificationTap.fromData(m.data)),
          ),
        );

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _initialTap = NotificationTap.fromData(initialMessage.data);
      }
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _initialTap ??= _parsePayload(launch!.notificationResponse?.payload);
      }
    } catch (e, st) {
      AppLogger.warning('Push setup failed', error: e, stackTrace: st);
    }
  }

  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      AppLogger.warning('Notification permission request failed', error: e);
      return false;
    }
  }

  /// The device token, or null when FCM is unavailable (no Play services,
  /// misconfigured project, offline).
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      AppLogger.warning('Could not get the FCM token', error: e);
      return null;
    }
  }

  /// Revokes this device's token so the previous user stops receiving pushes.
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
    } catch (e) {
      AppLogger.warning('Could not delete the FCM token', error: e);
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    try {
      await _local.show(
        message.messageId?.hashCode ?? message.hashCode,
        notification.title ?? 'New Notification',
        notification.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/ic_stat_notification',
            color: _brandGreen,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      AppLogger.warning('Could not show a foreground notification', error: e);
    }
  }

  void _onLocalTap(String? payload) {
    final tap = _parsePayload(payload);
    if (tap != null) _taps.add(tap);
  }

  static NotificationTap? _parsePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final data = jsonDecode(payload);
      return data is Map<String, dynamic>
          ? NotificationTap.fromData(data)
          : null;
    } catch (_) {
      return null;
    }
  }

  static String get platformName => Platform.isIOS ? 'ios' : 'android';

  static const _brandGreen = AppColors.brandGreen;

  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _taps.close();
  }
}
