import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../models/app_notification.dart';
import '../../core/theme/app_colors.dart';

/// What a tapped notification points to.
class NotificationTap {
  const NotificationTap({
    required this.type,
    this.userId,
    this.capsuleId,
    this.chatId,
  });

  /// Reads the `data` map sent by the Cloud Functions
  /// (`type`, `userId`, `capsuleId`, `chatId`).
  factory NotificationTap.fromData(Map<String, dynamic> data) =>
      NotificationTap(
        type: NotificationType.parse(data['type']),
        userId: _nonEmpty(data['userId']),
        capsuleId: _nonEmpty(data['capsuleId']),
        chatId: _nonEmpty(data['chatId']),
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

  /// Message pushes: the chat (`{uidA}_{uidB}`), also the Android tag.
  final String? chatId;

  static String? _nonEmpty(Object? v) => v is String && v.isNotEmpty ? v : null;
}

/// FCM + local notifications: permission, token, foreground display and tap
/// events for all three app states (foreground, background, terminated).
/// Subscribes this device to FCM topics.
abstract interface class TopicSubscriber {
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
}

class PushMessagingService implements TopicSubscriber {
  PushMessagingService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messagingOverride = messaging,
       _local = localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging? _messagingOverride;
  final FlutterLocalNotificationsPlugin _local;

  FirebaseMessaging get _messaging =>
      _messagingOverride ?? FirebaseMessaging.instance;

  /// Android channels, one per kind of push and a silent variant of each
  /// (the user's "Sound" setting picks one on the server,
  /// functions/lib/prefs.js). Users can tune each in the system settings;
  /// names are in the app's language when the channels are (re)created.
  static List<AndroidNotificationChannel> get channels {
    final l10n = AppL10n.current;
    return [
      AndroidNotificationChannel(
        'messages',
        l10n.notificationsChannelMessages,
        description: l10n.notificationsChannelMessagesDescription,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'messages_silent',
        l10n.notificationsChannelMessagesSilent,
        description: l10n.notificationsChannelMessagesSilentDescription,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
      AndroidNotificationChannel(
        'activity',
        l10n.notificationsChannelActivity,
        description: l10n.notificationsChannelActivityDescription,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'activity_silent',
        l10n.notificationsChannelActivitySilent,
        description: l10n.notificationsChannelActivitySilentDescription,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
      // Pushes from Cloud Functions deployed before the channels above
      // (and the manifest's default channel).
      AndroidNotificationChannel(
        channelId,
        l10n.notificationsChannelOther,
        description: l10n.notificationsChannelOtherDescription,
        importance: Importance.max,
      ),
    ];
  }

  static const channelId = 'high_importance_channel';

  /// The chat on screen: its message pushes are not shown in the
  /// foreground (set by the chat page).
  String? activeChatId;

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
      final android = _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      for (final channel in channels) {
        await android?.createNotificationChannel(channel);
      }

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

  /// Topic pushes (announcements, see NewsTopics). Skipped in builds that
  /// talk to the local emulators: FCM topics are not emulated, so the phone
  /// would join the real project's topics.
  @override
  Future<void> subscribeToTopic(String topic) async {
    if (_usesEmulator) return;
    await _messaging.subscribeToTopic(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_usesEmulator) return;
    await _messaging.unsubscribeFromTopic(topic);
  }

  static const _usesEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

  /// Revokes this device's token so the previous user stops receiving pushes.
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
    } catch (e) {
      AppLogger.warning('Could not delete the FCM token', error: e);
    }
  }

  /// Removes the system notification of [chatId] (opening the chat reads
  /// its messages). Android only; FCM posts it with id 0 and the chat tag.
  Future<void> clearChat(String chatId) async {
    try {
      await _local.cancel(0, tag: chatId);
      await _local.cancel(chatId.hashCode, tag: chatId);
    } catch (e) {
      AppLogger.warning('Could not clear chat notifications', error: e);
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    final tap = NotificationTap.fromData(message.data);
    final chatId = tap.type == NotificationType.message ? tap.chatId : null;
    // The user is reading this chat right now.
    if (chatId != null && chatId == activeChatId) return;
    final channel = channels.firstWhere(
      (c) => c.id == notification.android?.channelId,
      orElse: () => channels.last,
    );
    try {
      await _local.show(
        // One notification per chat, replaced by the next message.
        chatId?.hashCode ?? message.messageId?.hashCode ?? message.hashCode,
        notification.title ?? AppL10n.current.notificationsTypeOther,
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: channel.importance,
            priority: channel.importance == Importance.low
                ? Priority.low
                : Priority.high,
            playSound: channel.playSound,
            enableVibration: channel.enableVibration,
            tag: chatId,
            icon: '@drawable/ic_stat_notification',
            color: _brandGreen,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: channel.playSound,
            threadIdentifier: chatId,
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
