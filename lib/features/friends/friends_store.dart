import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../core/session/session_scoped.dart';
import '../../data/models/friend_request.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/repositories.dart';

/// The signed-in user's friends and pending friend requests, live.
///
/// Replaces UserFriendsService, which widgets also instantiated ad hoc with
/// never-cancelled listeners (BUG-074, BUG-075, BUG-085). One instance
/// follows the session; every action is guarded against double taps and
/// reports failures instead of throwing (BUG-084).
class FriendsStore extends ChangeNotifier implements SessionScoped {
  FriendsStore({
    required FriendsRepository friends,
    required UserRepository users,
    required NotificationRepository notifications,
  }) : _friends = friends,
       _users = users,
       _notifications = notifications;

  final FriendsRepository _friends;
  final UserRepository _users;
  final NotificationRepository _notifications;

  final List<StreamSubscription<Object?>> _subs = [];
  String? _uid;
  UserProfile? _me;
  Set<String> _friendIds = const {};
  Set<String> _sentTo = const {};
  Set<String> _receivedFrom = const {};
  Set<String> _blocked = const {};
  final Set<String> _dismissed = {};
  final Set<String> _busy = {};
  bool _loaded = false;

  String? get uid => _uid;
  bool get isLoaded => _loaded;
  Set<String> get friendIds => _friendIds;

  /// Users this user sent a pending request to.
  Set<String> get sentTo => _sentTo;

  /// Users who sent this user a pending request.
  Set<String> get receivedFrom => _receivedFrom;
  int get incomingCount => _receivedFrom.length;

  /// Users this user blocked.
  Set<String> get blocked => _blocked;
  bool isBlocked(String otherUid) => _blocked.contains(otherUid);

  /// Suggestions the user hid in this session.
  Set<String> get dismissed => _dismissed;

  /// Whether an action for [otherUid] is running.
  bool isBusy(String otherUid) => _busy.contains(otherUid);

  FriendRelation relationTo(String otherUid) {
    if (otherUid == _uid) return FriendRelation.self;
    if (_friendIds.contains(otherUid)) return FriendRelation.friends;
    if (_sentTo.contains(otherUid)) return FriendRelation.requestSent;
    if (_receivedFrom.contains(otherUid)) return FriendRelation.requestReceived;
    return FriendRelation.none;
  }

  @override
  void attach(String uid) {
    _uid = uid;
    void onError(Object e, StackTrace st) =>
        AppLogger.warning('Friends stream failed', error: e, stackTrace: st);
    _subs
      ..add(
        _users.watchProfile(uid).listen((profile) {
          _me = profile;
          _friendIds = profile?.friends.toSet() ?? const {};
          _loaded = true;
          notifyListeners();
        }, onError: onError),
      )
      ..add(
        _friends.watchOutgoingPending(uid).listen((requests) {
          _sentTo = {for (final r in requests) r.toUserId};
          notifyListeners();
        }, onError: onError),
      )
      ..add(
        _friends.watchIncomingPending(uid).listen((requests) {
          _receivedFrom = {for (final r in requests) r.fromUserId};
          notifyListeners();
        }, onError: onError),
      )
      ..add(
        _friends.watchBlocked(uid).listen((blocked) {
          _blocked = blocked;
          notifyListeners();
        }, onError: onError),
      );
  }

  @override
  void detach() {
    for (final sub in _subs) {
      unawaited(sub.cancel());
    }
    _subs.clear();
    _uid = null;
    _me = null;
    _friendIds = const {};
    _sentTo = const {};
    _receivedFrom = const {};
    _blocked = const {};
    _dismissed.clear();
    _busy.clear();
    _loaded = false;
    notifyListeners();
  }

  @override
  Future<void> beforeSignOut(String uid) async {}

  void dismissSuggestion(String otherUid) {
    if (_dismissed.add(otherUid)) notifyListeners();
  }

  /// Runs [action] for [otherUid] unless one is already running (callers
  /// check [isBusy] first so a double tap shows no second message).
  /// Returns null on success. [logMessage] goes to the log (English);
  /// [fallbackMessage] is shown to the user in the app's language.
  Future<AppFailure?> _guard(
    String otherUid,
    String logMessage,
    String fallbackMessage,
    Future<void> Function(String me) action,
  ) async {
    final me = _uid;
    if (me == null || _busy.contains(otherUid)) return null;
    _busy.add(otherUid);
    notifyListeners();
    try {
      await action(me);
      return null;
    } catch (e, st) {
      AppLogger.warning(logMessage, error: e, stackTrace: st);
      return AppFailure.from(e, fallbackMessage: fallbackMessage);
    } finally {
      if (_uid == me) {
        _busy.remove(otherUid);
        notifyListeners();
      }
    }
  }

  Future<AppFailure?> sendRequest(String to) => _guard(
    to,
    'Failed to send friend request',
    AppL10n.current.friendsErrorSendRequest,
    (me) => _friends.sendRequest(from: me, to: to),
  );

  Future<AppFailure?> cancelRequest(String to) => _guard(
    to,
    'Failed to cancel request',
    AppL10n.current.friendsErrorCancelRequest,
    (me) => _friends.cancelRequest(from: me, to: to),
  );

  Future<AppFailure?> acceptRequest(String from) => _guard(
    from,
    'Failed to accept request',
    AppL10n.current.friendsErrorAcceptRequest,
    (me) => _friends.acceptRequest(from: from, to: me),
  );

  Future<AppFailure?> rejectRequest(String from) => _guard(
    from,
    'Failed to reject request',
    AppL10n.current.friendsErrorRejectRequest,
    (me) => _friends.rejectRequest(from: from, to: me),
  );

  Future<AppFailure?> removeFriend(String friend) => _guard(
    friend,
    'Failed to remove friend',
    AppL10n.current.friendsErrorRemoveFriend,
    (me) => _friends.removeFriend(me: me, friend: friend),
  );

  Future<bool> isFollowing(String target) async {
    final me = _uid;
    if (me == null) return false;
    try {
      return await _friends.isFollowing(me: me, target: target);
    } catch (e) {
      AppLogger.debug('Follow status unavailable: $e');
      return false;
    }
  }

  /// Follows [target] and leaves them a "started following you"
  /// notification (the Cloud Function turns it into a push).
  Future<AppFailure?> follow(String target) => _guard(
    target,
    'Failed to follow user',
    AppL10n.current.friendsErrorFollow,
    (me) async {
      await _friends.follow(
        me: me,
        target: target,
        myUsername: _me?.username ?? '',
      );
      try {
        await _notifications.createFollowNotification(
          targetUid: target,
          fromUid: me,
          fromUserName: _me?.username ?? 'Someone',
        );
      } catch (e) {
        // Following worked; only the notice for the other user failed.
        AppLogger.warning('Follow notification failed', error: e);
      }
    },
  );

  Future<AppFailure?> unfollow(String target) => _guard(
    target,
    'Failed to unfollow user',
    AppL10n.current.friendsErrorUnfollow,
    (me) => _friends.unfollow(me: me, target: target),
  );

  /// Blocks [other]: they can no longer send this user messages.
  Future<AppFailure?> block(String other) => _guard(
    other,
    'Failed to block user',
    AppL10n.current.friendsErrorBlock,
    (me) => _friends.block(me: me, other: other),
  );

  Future<AppFailure?> unblock(String other) => _guard(
    other,
    'Failed to unblock user',
    AppL10n.current.friendsErrorUnblock,
    (me) => _friends.unblock(me: me, other: other),
  );

  /// Whether [other] blocked this user (false when it cannot be checked;
  /// the rules refuse the messages anyway).
  Future<bool> isBlockedBy(String other) async {
    final me = _uid;
    if (me == null) return false;
    try {
      return await _friends.isBlockedBy(me: me, other: other);
    } catch (e) {
      AppLogger.debug('Block status unavailable: $e');
      return false;
    }
  }
}
