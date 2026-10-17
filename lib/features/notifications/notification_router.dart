import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../app/router/app_routes.dart';
import '../../app/session/session_controller.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/app_notification.dart';
import '../../data/models/chat.dart';
import '../../app/shell/selected_page.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/push_messaging_service.dart';
import '../capsules/social/capsule_detail_dialog.dart';
import '../map/map_focus.dart';

/// Where a notification tap leads (decided first, then opened).
sealed class NotificationDestination {
  const NotificationDestination();
}

/// A profile: the friend page for a friend, the add-friend page otherwise.
class ProfileDestination extends NotificationDestination {
  const ProfileDestination(this.userId, {required this.isFriend});
  final String userId;
  final bool isFriend;
}

class FriendRequestsDestination extends NotificationDestination {
  const FriendRequestsDestination();
}

/// A capsule on the map; [open] also opens its card (and the thread with
/// [comments]).
class CapsuleDestination extends NotificationDestination {
  const CapsuleDestination(
    this.capsuleId, {
    required this.open,
    required this.comments,
  });
  final String capsuleId;
  final bool open;
  final bool comments;
}

class ChatDestination extends NotificationDestination {
  const ChatDestination({this.userId, this.groupId});
  final String? userId;
  final String? groupId;
}

class AchievementsDestination extends NotificationDestination {
  const AchievementsDestination();
}

/// Turns notification taps (system notifications in every app state, local
/// foreground notifications and rows of the in-app list) into navigation.
/// Taps that arrive before the home screen exists are queued (BUG-024).
class NotificationRouter {
  NotificationRouter({
    required PushMessagingService push,
    required SessionController session,
    required CapsuleRepository capsules,
    required MapFocus mapFocus,
    @visibleForTesting
    Future<void> Function(NotificationDestination destination)? navigate,
  }) : _push = push,
       _session = session,
       _capsules = capsules,
       _mapFocus = mapFocus,
       _navigate = navigate;

  final PushMessagingService _push;
  final SessionController _session;
  final CapsuleRepository _capsules;
  final MapFocus _mapFocus;
  final Future<void> Function(NotificationDestination)? _navigate;

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

  /// Where [tap] leads; null when it leads nowhere (a tap without the id
  /// its kind needs, or a kind that opens nothing).
  static NotificationDestination? destinationFor(
    NotificationTap tap, {
    required Set<String> friends,
  }) {
    switch (tap.type) {
      case NotificationType.follow || NotificationType.friendAccepted:
        final userId = tap.userId;
        if (userId == null) return null;
        return ProfileDestination(userId, isFriend: friends.contains(userId));
      case NotificationType.friendRequest:
        return const FriendRequestsDestination();
      case NotificationType.capsule ||
          NotificationType.coAuthor ||
          NotificationType.reaction ||
          NotificationType.comment ||
          NotificationType.reply:
        final capsuleId = tap.capsuleId;
        if (capsuleId == null) return null;
        return CapsuleDestination(
          capsuleId,
          // A new capsule is shown on the map; the others open it.
          open: tap.type != NotificationType.capsule,
          comments:
              tap.type == NotificationType.comment ||
              tap.type == NotificationType.reply,
        );
      case NotificationType.message:
        final chatId = tap.chatId;
        if (chatId != null && Chat.isGroupId(chatId)) {
          return ChatDestination(groupId: chatId);
        }
        final userId = tap.userId;
        if (userId == null) return null;
        return ChatDestination(userId: userId);
      case NotificationType.achievement:
        return const AchievementsDestination();
      case NotificationType.other:
        return null;
    }
  }

  Future<void> _open(NotificationTap tap) async {
    final destination = destinationFor(
      tap,
      friends: {...?_session.profile?.friends},
    );
    if (destination == null) return;
    final navigate = _navigate;
    if (navigate != null) return navigate(destination);
    await _go(destination);
  }

  Future<void> _go(NotificationDestination destination) async {
    final context = AppRoutes.navigatorKey.currentContext;
    if (context == null) return;
    switch (destination) {
      case ProfileDestination(:final userId, :final isFriend):
        await (isFriend
            ? AppRoutes.toFriendProfile(context, userId)
            : AppRoutes.toAddFriendProfile(context, userId));
      case FriendRequestsDestination():
        await AppRoutes.toFriendRequests(context);
      case CapsuleDestination(:final capsuleId, :final open, :final comments):
        try {
          final capsule = await _capsules.getById(capsuleId);
          if (capsule == null) return;
          AppRoutes.backToRoot();
          selectedPageNotifier.value = AppTabs.map;
          if (capsule.location != null) _mapFocus.focus(capsule);
          if (!open) return;
          // A reaction, comment, reply or co-authored capsule: the capsule
          // itself, and for comments the thread, over the map.
          final root = AppRoutes.navigatorKey.currentContext;
          if (root == null || !root.mounted) return;
          await CapsuleDetailDialog.show(root, capsule, openComments: comments);
        } catch (e) {
          AppLogger.warning('Could not open capsule $capsuleId', error: e);
        }
      case ChatDestination(:final groupId?):
        await AppRoutes.toGroupChat(context, groupId);
      case ChatDestination(:final userId?):
        await AppRoutes.toChat(context, userId);
      case ChatDestination():
        break;
      case AchievementsDestination():
        AppRoutes.backToRoot();
        selectedPageNotifier.value = AppTabs.profile;
    }
  }

  Future<void> dispose() async => _sub?.cancel();
}
