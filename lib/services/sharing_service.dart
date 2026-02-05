import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/services/popup_notification_service.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class SharingService {
  static String generateProfileLink(String userId) {
    return 'https://later-da778.web.app/?userId=$userId';
  }

  static Future<void> shareUserProfile({
    required BuildContext context,
    required String userId,
  }) async {
    try {
      final userService = Provider.of<UserDataService>(context, listen: false);
      final userData = await userService.getUserData(userId);
      final friendName = userData['name'] ?? 'Unknown User';
      final link = generateProfileLink(userId);

      await SharePlus.instance.share(
        ShareParams(
          text: 'Check out $friendName on Later! \n$link',
          subject: 'Connect with $friendName on Later',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        PopupNotificationService.showError(
          context: context,
          message: 'Failed to share profile',
          position: NotificationPosition.bottom,
        );
      }
    }
  }

  static Future<void> copyProfileLink({
    required BuildContext context,
    required String userId,
  }) async {
    try {
      final link = generateProfileLink(userId);
      await Clipboard.setData(ClipboardData(text: link));

      if (context.mounted) {
        PopupNotificationService.showSuccess(
          context: context,
          message: 'Link copied to clipboard!',
          position: NotificationPosition.bottom,
        );
      }
    } catch (e) {
      if (context.mounted) {
        PopupNotificationService.showError(
          context: context,
          message: 'Failed to copy link',
          position: NotificationPosition.bottom,
        );
      }
    }
  }
}
