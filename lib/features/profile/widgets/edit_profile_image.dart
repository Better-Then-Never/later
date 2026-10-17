import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/repositories.dart';
import '../../../data/services/app_image_cache.dart';
import '../../../data/services/profile_image_cache.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../profile_image_editor.dart';
import 'image_options_sheet.dart';
import 'pick_image.dart';

/// What the signed-in user's own picture shows: the stored picture, else
/// the one just uploaded (until its URL resolves), else nothing.
ImageProvider? ownImage(BuildContext context, ProfileImageEditor editor) {
  final small = editor.kind != ProfileImageKind.profile;
  final url = context.select<ProfileImageCache, String?>(
    (c) => c.url(editor.uid, editor.kind, small: small),
  );
  final preview = editor.preview;
  if (url != null) return AppImageCache.provider(url);
  if (preview != null) return MemoryImage(preview);
  return null;
}

/// Whether the lookup finished, so the "choose a picture" icon does not
/// flash before an existing picture appears.
bool isOwnImageResolved(BuildContext context, ProfileImageEditor editor) {
  final small = editor.kind != ProfileImageKind.profile;
  return context.select<ProfileImageCache, bool>(
    (c) => c.isResolved(editor.uid, editor.kind, small: small),
  );
}

/// Shows the gallery / camera / delete menu and runs the choice.
Future<void> editProfileImage(
  BuildContext context,
  ProfileImageEditor editor, {
  required String title,
  required String deleteLabel,
  required String successMessage,
}) async {
  final option = await ImageOptionsSheet.show(
    context,
    title: title,
    deleteLabel: deleteLabel,
  );
  if (option == null || !context.mounted) return;

  void showError(String message) => PopupNotificationService.showError(
    context: context,
    message: message,
    duration: const Duration(seconds: 3),
    position: NotificationPosition.top,
  );

  if (option == ImageOption.delete) {
    final failure = await editor.delete();
    if (failure != null && context.mounted) showError(failure.message);
    return;
  }

  final bytes = await pickImageBytes(
    option == ImageOption.camera ? ImageSource.camera : ImageSource.gallery,
  );
  if (bytes == null) return;
  final failure = await editor.upload(bytes);
  if (!context.mounted) return;
  if (failure != null) {
    showError(failure.message);
    return;
  }
  PopupNotificationService.showSuccess(
    context: context,
    message: successMessage,
    duration: const Duration(seconds: 2),
    position: NotificationPosition.top,
  );
}
