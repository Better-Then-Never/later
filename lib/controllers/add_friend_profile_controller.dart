import 'package:flutter/material.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/services/popup_notification_service.dart';

class AddFriendProfileController extends ChangeNotifier {
  final String userId;
  final UserFriendsService _requestService;
  final UserDataService _userService;

  bool isLoading = false;
  bool isCancelling = false;
  String buttonState = 'add';

  VoidCallback? onNavigateToFriendProfile;

  AddFriendProfileController({
    required this.userId,
    required UserFriendsService requestService,
    required UserDataService userService,
    this.onNavigateToFriendProfile,
  }) : _requestService = requestService,
       _userService = userService {
    _checkRelationshipStatus();
  }

  Future<void> _checkRelationshipStatus() async {
    final currentUserUid = _userService.currentLoggedInUid;
    if (currentUserUid == userId) {
      buttonState = 'own_profile';
    } else if (await _requestService.areFriends(currentUserUid, userId)) {
      buttonState = 'friends';
    } else if (await _requestService.requestExists(currentUserUid, userId)) {
      buttonState = 'pending';
    } else {
      buttonState = 'add';
    }
    notifyListeners();
  }

  Future<void> sendFriendRequest(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      final currentUserUid = _userService.currentLoggedInUid;
      final exists = await _requestService.requestExists(
        currentUserUid,
        userId,
      );

      if (exists) {
        buttonState = 'pending';
        PopupNotificationService.showInfo(
          context: context,
          message: 'Friend request already exists',
          position: NotificationPosition.center,
        );
        return;
      }

      await _requestService.sendFriendRequest(currentUserUid, userId);
      buttonState = 'pending';
      PopupNotificationService.showSuccess(
        context: context,
        message: 'Friend request sent!',
        position: NotificationPosition.center,
      );
    } catch (e) {
      PopupNotificationService.showError(
        context: context,
        message: 'Failed to send friend request',
        position: NotificationPosition.center,
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelFriendRequest(BuildContext context) async {
    isCancelling = true;
    notifyListeners();

    try {
      final currentUserUid = _userService.currentLoggedInUid;
      await _requestService.cancelFriendRequest(currentUserUid, userId);
      buttonState = 'add';
      PopupNotificationService.showInfo(
        context: context,
        message: 'Friend request cancelled',
        position: NotificationPosition.center,
      );
    } catch (e) {
      PopupNotificationService.showError(
        context: context,
        message: 'Failed to cancel request',
        position: NotificationPosition.center,
      );
    } finally {
      isCancelling = false;
      notifyListeners();
    }
  }

  Future<void> handleButtonPress(BuildContext context) async {
    if (buttonState == 'own_profile') {
      PopupNotificationService.showInfo(
        context: context,
        message: 'This is your account',
        position: NotificationPosition.center,
      );
    } else if (buttonState == 'friends') {
      if (onNavigateToFriendProfile != null) {
        onNavigateToFriendProfile!();
      }
    } else if (buttonState == 'pending') {
      PopupNotificationService.showInfo(
        context: context,
        message: 'Friend request is pending',
        position: NotificationPosition.center,
      );
    } else {
      await sendFriendRequest(context);
    }
  }
}
