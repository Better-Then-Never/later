import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/session/session_controller.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/profile_image_cache.dart';
import '../../../shared/widgets/later_loading_bar.dart';
import '../profile_image_editor.dart';
import 'edit_profile_image.dart';
import '../../../core/theme/app_palette.dart';

/// The signed-in user's square profile picture; tap to change or delete.
class ProfilePicture extends StatelessWidget {
  final double? pictureHeight;
  final double? pictureWidth;

  const ProfilePicture({super.key, this.pictureHeight, this.pictureWidth});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileImageEditor(
        uid: context.read<SessionController>().uid!,
        kind: ProfileImageKind.profile,
        images: context.read<ImageStorageRepository>(),
        cache: context.read<ProfileImageCache>(),
      ),
      child: _ProfilePictureView(
        height: pictureHeight ?? 150,
        width: pictureWidth ?? 150,
      ),
    );
  }
}

class _ProfilePictureView extends StatelessWidget {
  const _ProfilePictureView({required this.height, required this.width});

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<ProfileImageEditor>();
    final image = ownImage(context, editor);
    final l10n = context.l10n;

    return GestureDetector(
      onTap: editor.isBusy
          ? null
          : () => editProfileImage(
              context,
              editor,
              title: l10n.profilePictureTitle,
              deleteLabel: l10n.profilePictureDelete,
              successMessage: l10n.profilePictureUpdated,
            ),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: context.palette.emptyAvatar,
          borderRadius: BorderRadius.circular(25),
          image: image != null && !editor.isBusy
              ? DecorationImage(image: image, fit: BoxFit.cover)
              : null,
        ),
        child: editor.isBusy
            ? LaterLoadingBar(
                width: 40,
                height: 40,
                message: l10n.profileUpdating,
                messageSpacing: 5,
              )
            : image == null && isOwnImageResolved(context, editor)
            ? Center(
                child: Image.asset(
                  AppIcons.profileChoosePhoto,
                  width: 35,
                  height: 35,
                  fit: BoxFit.contain,
                ),
              )
            : null,
      ),
    );
  }
}
