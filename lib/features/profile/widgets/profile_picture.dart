import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/session/session_controller.dart';
import '../../../core/assets/app_assets.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/profile_image_cache.dart';
import '../../../shared/widgets/later_loading_bar.dart';
import '../profile_image_editor.dart';
import 'edit_profile_image.dart';
import '../../../core/theme/app_colors.dart';

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

    return GestureDetector(
      onTap: editor.isBusy
          ? null
          : () => editProfileImage(
              context,
              editor,
              title: 'Profile picture',
              deleteLabel: 'Delete profile icon',
              successMessage: 'Profile picture updated successfully!',
            ),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.emptyAvatar,
          borderRadius: BorderRadius.circular(25),
          image: image != null && !editor.isBusy
              ? DecorationImage(image: image, fit: BoxFit.cover)
              : null,
        ),
        child: editor.isBusy
            ? const LaterLoadingBar(
                width: 40,
                height: 40,
                message: 'Updating...',
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
