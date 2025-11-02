import 'package:flutter/material.dart';
import 'package:later/services/popup_notification_service.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/services/user_data_service.dart';

class FriendRequestsPageController extends ChangeNotifier {
  final UserFriendsService _friendsService;
  final UserDataService _userService;

  FriendRequestsPageController({
    required UserFriendsService friendsService,
    required UserDataService userService,
  }) : _friendsService = friendsService,
       _userService = userService {
    _friendsService.addListener(_onServiceUpdate);
    _preloadSentRequestUsers();
  }

  void _onServiceUpdate() => notifyListeners();

  List<String> get sentRequests => _friendsService.sentRequests.toList();
  List<String> get receivedRequests =>
      _friendsService.receivedRequests.toList();

  Future<void> _preloadSentRequestUsers() async {
    for (var toUserId in _friendsService.sentRequests) {
      await _userService.getUserData(toUserId);
    }
    notifyListeners();
  }

  Future<void> cancelFriendRequest({
    required String userId,
    required BuildContext context,
  }) async {
    try {
      await _friendsService.cancelFriendRequest(
        _userService.currentLoggedInUid,
        userId,
      );
      PopupNotificationService.showInfo(
        context: context,
        message: 'Friend request cancelled',
        position: NotificationPosition.bottom,
      );
    } catch (_) {
      PopupNotificationService.showError(
        context: context,
        message: 'Failed to cancel request',
        position: NotificationPosition.bottom,
      );
    }
  }

  Future<void> acceptRequest({
    required String fromUserId,
    required BuildContext context,
  }) async {
    try {
      final requestId = '${fromUserId}_${_userService.currentLoggedInUid}';
      await _friendsService.acceptFriendRequest(
        requestId,
        fromUserId,
        _userService.currentLoggedInUid,
      );
      PopupNotificationService.showSuccess(
        context: context,
        message: 'Friend request accepted!',
        position: NotificationPosition.bottom,
      );
    } catch (_) {
      PopupNotificationService.showError(
        context: context,
        message: 'Failed to accept request',
        position: NotificationPosition.bottom,
      );
    }
  }

  Future<void> rejectRequest({
    required String fromUserId,
    required BuildContext context,
  }) async {
    try {
      final requestId = '${fromUserId}_${_userService.currentLoggedInUid}';
      await _friendsService.rejectFriendRequest(requestId, fromUserId);
      PopupNotificationService.showInfo(
        context: context,
        message: 'Friend request rejected',
        position: NotificationPosition.bottom,
      );
    } catch (_) {
      PopupNotificationService.showError(
        context: context,
        message: 'Failed to reject request',
        position: NotificationPosition.bottom,
      );
    }
  }

  @override
  void dispose() {
    _friendsService.removeListener(_onServiceUpdate);
    super.dispose();
  }
}
