import 'package:flutter/material.dart';
import 'package:later/app/router/app_link_handler.dart';
import 'package:flutter/services.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/features/users/user_directory.dart';
import 'package:later/shared/widgets/popup/popup_notification_service.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class SharingService {
  static String generateProfileLink(String userId) {
    return AppLinkHandler.profileWebLink(userId);
  }

  static Future<void> shareUserProfile({
    required BuildContext context,
    required String userId,
  }) async {
    // Read before the lookup: the context may be gone after it.
    final l10n = context.l10n;
    try {
      final profiles = await context.read<UserDirectory>().resolveAll([userId]);
      final friendName = profiles[userId]?.name ?? l10n.commonUnknownUser;
      final link = generateProfileLink(userId);

      await SharePlus.instance.share(
        ShareParams(
          text: l10n.profileShareMessage(friendName, link),
          subject: l10n.profileShareSubject(friendName),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        PopupNotificationService.showError(
          context: context,
          message: context.l10n.profileErrorShare,
          position: NotificationPosition.bottom,
        );
      }
    }
  }

  /// Shares a link to [capsule]: a page that opens it in the app for those
  /// who may see it (nothing of the capsule is shown on the web).
  static Future<void> shareCapsule({
    required BuildContext context,
    required Capsule capsule,
  }) async {
    final l10n = context.l10n;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: l10n.capsulesShareMessage(
            capsule.title,
            AppLinkHandler.capsuleWebLink(capsule.id),
          ),
          subject: capsule.title,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        PopupNotificationService.showError(
          context: context,
          message: l10n.profileErrorShare,
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
          message: context.l10n.profileLinkCopied,
          position: NotificationPosition.bottom,
        );
      }
    } catch (e) {
      if (context.mounted) {
        PopupNotificationService.showError(
          context: context,
          message: context.l10n.profileErrorCopyLink,
          position: NotificationPosition.bottom,
        );
      }
    }
  }
}
