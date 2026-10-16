import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/session/session_controller.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/profile_image_cache.dart';
import '../../../shared/widgets/later_loading_bar.dart';
import '../profile_image_editor.dart';
import 'edit_profile_image.dart';
import '../../../core/theme/app_colors.dart';

/// The signed-in user's profile background; tap to change or delete.
class ProfileBackgroundPicture extends StatelessWidget {
  final double? pictureHeight;

  const ProfileBackgroundPicture({super.key, this.pictureHeight});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileImageEditor(
        uid: context.read<SessionController>().uid!,
        kind: ProfileImageKind.background,
        images: context.read<ImageStorageRepository>(),
        cache: context.read<ProfileImageCache>(),
      ),
      child: _BackgroundView(height: pictureHeight ?? 200),
    );
  }
}

class _BackgroundView extends StatelessWidget {
  const _BackgroundView({required this.height});

  final double height;

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
              title: 'Background picture',
              deleteLabel: 'Delete background picture',
              successMessage: 'Background picture updated successfully!',
            ),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.emptyBackground,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
          image: image != null && !editor.isBusy
              ? DecorationImage(image: image, fit: BoxFit.cover)
              : null,
        ),
        child: editor.isBusy
            ? const Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: LaterLoadingBar(
                    width: 40,
                    height: 40,
                    message: 'Updating...',
                    messageSpacing: 5,
                    messageStyle: TextStyle(
                      fontSize: 12,
                      // Was misspelt "Inria" (system font, BUG-087).
                      fontFamily: kAppFontFamily,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : image == null && isOwnImageResolved(context, editor)
            ? Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Image.asset(
                    AppIcons.profileChooseBackground,
                    width: 35,
                    height: 35,
                    fit: BoxFit.contain,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
