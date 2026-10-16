import 'package:flutter/material.dart';
import 'package:later/shared/styles/box_decorations.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:later/core/theme/app_colors.dart';

class ShareProfileQR extends StatelessWidget {
  final String profileLink;
  final double screenWidth;

  const ShareProfileQR({
    super.key,
    required this.profileLink,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: screenWidth * 0.75,
      height: screenWidth * 0.75,
      decoration: BoxDecorations.whiteCard(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: QrImageView(
          data: profileLink,
          version: QrVersions.auto,
          size: screenWidth * 0.55,
          backgroundColor: AppColors.white,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: AppColors.black,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: AppColors.black,
          ),
          errorStateBuilder: (context, error) => const Center(
            child: DefaultText(
              'Something went wrong...',
              color: AppColors.materialRed,
            ),
          ),
        ),
      ),
    );
  }
}
