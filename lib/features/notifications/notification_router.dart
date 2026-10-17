import 'dart:async';

import '../../app/router/app_routes.dart';
import '../../app/session/session_controller.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/app_notification.dart';
import '../../app/shell/selected_page.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/push_messaging_service.dart';
import '../map/map_focus.dart';

/// Turns notification taps (system notifications in every app state, local
/// foreground notifications and rows of the in-app list) into navigation.
/// Taps that arrive before the home screen exists are queued (BUG-024).
class NotificationRouter {
  NotificationRouter({
    required PushMessagingService push,
    required SessionController session,
    required CapsuleRepository capsules,
    required MapFocus mapFocus,
  }) : _push = push,
       _session = session,
       _capsules = capsules,
       _mapFocus = mapFocus;

  final PushMessagingService _push;
  final SessionController _session;
  final CapsuleRepository _capsules;
  final MapFocus _mapFocus;

  StreamSubscription<NotificationTap>? _sub;
  NotificationTap? _pending;
  bool _homeReady = false;

  void start() {
    _sub ??= _push.taps.listen(handle);
  }

  void onHomeReady() {
    _homeReady = true;
    _pending ??= _push.takeInitialTap();
    final tap = _pending;
    _pending = null;
    if (tap != null) unawaited(_open(tap));
  }

  void onHomeGone() => _homeReady = false;

  void handle(NotificationTap tap) {
    if (_homeReady) {
      unawaited(_open(tap));
    } else {
      _pending = tap;
    }
  }

  Future<void> _open(NotificationTap tap) async {
    final context = AppRoutes.navigatorKey.currentContext;
    if (context == null) return;
    switch (tap.type) {
      case NotificationType.follow:
        final userId = tap.userId;
        if (userId == null) return;
        final isFriend = _session.profile?.friends.contains(userId) ?? false;
        await (isFriend
            ? AppRoutes.toFriendProfile(context, userId)
            : AppRoutes.toAddFriendProfile(context, userId));
      case NotificationType.capsule:
        final capsuleId = tap.capsuleId;
        if (capsuleId == null) return;
        try {
          final capsule = await _capsules.getById(capsuleId);
          if (capsule == null) return;
          AppRoutes.backToRoot();
          selectedPageNotifier.value = 0;
          _mapFocus.focus(capsule);
        } catch (e) {
          AppLogger.warning('Could not open capsule $capsuleId', error: e);
        }
      case NotificationType.message:
        final userId = tap.userId;
        if (userId == null) return;
        await AppRoutes.toChat(context, userId);
      case NotificationType.reply ||
          NotificationType.comment ||
          NotificationType.other:
        // No destination exists for these types yet.
        break;
    }
  }

  Future<void> dispose() async => _sub?.cancel();
}
