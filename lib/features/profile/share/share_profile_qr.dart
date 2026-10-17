import 'package:flutter/material.dart';
import 'package:later/shared/styles/box_decorations.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:later/core/theme/app_colors.dart';
import 'package:later/core/l10n/l10n.dart';

class ShareProfileQR extends StatelessWidget {
  final String profileLink;
  final double screenWidth;

  const ShareProfileQR({
    super.key,
    required this.profileLink,
    required this.screenWidth,
  });

  /// The code itself stays black on white in both themes: it is an image to
  /// be scanned, and many scanners cannot read an inverted code.
  static const _qrDark = AppColors.mediaBlack;
  static const _qrLight = AppColors.onMedia;

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
          backgroundColor: _qrLight,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: _qrDark,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: _qrDark,
          ),
          errorStateBuilder: (context, error) => Center(
            child: DefaultText(
              context.l10n.profileQrError,
              color: AppColors.materialRed,
            ),
          ),
        ),
      ),
    );
  }
}
