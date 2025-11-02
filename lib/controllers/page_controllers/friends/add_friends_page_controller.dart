import 'dart:async';
import 'package:flutter/material.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/services/popup_notification_service.dart';

class AddFriendsPageController extends ChangeNotifier {
  final UserFriendsService _friendsService;
  final UserDataService _userService;

  AddFriendsPageController({
    required UserFriendsService friendsService,
    required UserDataService userService,
  }) : _friendsService = friendsService,
       _userService = userService {
    _friendsService.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    notifyListeners();
  }

  int get receivedRequestsCount => _friendsService.receivedRequests.length;

  @override
  void dispose() {
    _friendsService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  Future<void> sendFriendRequest({
    required String userId,
    required BuildContext context,
  }) async {
    final currentUserId = _userService.currentLoggedInUid;

    if (_friendsService.sentRequests.contains(userId)) {
      PopupNotificationService.showInfo(
        context: context,
        message: 'Friend request already exists',
        position: NotificationPosition.bottom,
      );
      return;
    }

    try {
      await _friendsService.sendFriendRequest(currentUserId, userId);

      PopupNotificationService.showSuccess(
        context: context,
        message: 'Friend request sent!',
        position: NotificationPosition.bottom,
      );
    } catch (e) {
      PopupNotificationService.showError(
        context: context,
        message: 'Failed to send friend request',
        position: NotificationPosition.bottom,
      );
    }
  }

  Future<void> cancelFriendRequest({
    required String userId,
    required BuildContext context,
  }) async {
    final currentUserId = _userService.currentLoggedInUid;

    try {
      await _friendsService.cancelFriendRequest(currentUserId, userId);

      PopupNotificationService.showInfo(
        context: context,
        message: 'Friend request cancelled',
        position: NotificationPosition.bottom,
      );
    } catch (e) {
      PopupNotificationService.showError(
        context: context,
        message: 'Failed to cancel friend request',
        position: NotificationPosition.bottom,
      );
    }
  }

  void removeSuggestedFriend({
    required String userId,
    required BuildContext context,
  }) {
    _friendsService.removeSuggestedFriend(userId);
    PopupNotificationService.showInfo(
      context: context,
      message: 'Suggested friend removed from the list!',
      position: NotificationPosition.bottom,
    );
  }
}
