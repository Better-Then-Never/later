import 'dart:async';
import 'package:flutter/material.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/services/popup_notification_service.dart';

class AddFriendsPageController extends ChangeNotifier {
  final UserFriendsService _friendsService;
  final UserDataService _userService;

  int _receivedRequestsCount = 0;
  int get receivedRequestsCount => _receivedRequestsCount;

  late final StreamSubscription _requestsSub;

  AddFriendsPageController({
    required UserFriendsService friendsService,
    required UserDataService userService,
  }) : _friendsService = friendsService,
       _userService = userService {
    _friendsService.addListener(_onServiceUpdate);

    _requestsSub =
        UserFriendsService.getReceivedRequestsCount(
          _userService.currentLoggedInUid,
        ).listen((count) {
          _receivedRequestsCount = count;
          notifyListeners();
        });
  }

  void _onServiceUpdate() {
    notifyListeners();
  }

  @override
  void dispose() {
    _friendsService.removeListener(_onServiceUpdate);
    _requestsSub.cancel();
    super.dispose();
  }

  Future<void> sendFriendRequest({
    required String userId,
    required BuildContext context,
  }) async {
    final currentUserId = _userService.currentLoggedInUid;

    try {
      final exists = await _friendsService.requestExists(currentUserId, userId);
      if (exists) {
        PopupNotificationService.showInfo(
          context: context,
          message: 'Friend request already exists',
          position: NotificationPosition.bottom,
        );
        return;
      }

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
