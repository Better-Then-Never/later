import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';

enum ImageOption { gallery, camera, delete }

/// "Profile picture" / "Background picture" menu: gallery, camera, delete.
/// One widget for both pictures (they were two copies). Pops with the
/// chosen [ImageOption], or null when dismissed.
class ImageOptionsSheet extends StatelessWidget {
  const ImageOptionsSheet({
    super.key,
    required this.title,
    required this.deleteLabel,
  });

  final String title;
  final String deleteLabel;

  static Future<ImageOption?> show(
    BuildContext context, {
    required String title,
    required String deleteLabel,
  }) => showModalBottomSheet<ImageOption>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: context.palette.scrim,
    builder: (context) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Center(
        child: GestureDetector(
          onTap: () {},
          child: ImageOptionsSheet(title: title, deleteLabel: deleteLabel),
        ),
      ),
    ),
  );

  static const _width = 264.0;
  static const _rowHeight = 37.0;
  static const _green = AppColors.brandGreen;
  static const _red = AppColors.danger;

  /// [foreground] is the theme's text colour when null.
  Widget _option(
    BuildContext context,
    String text,
    ImageOption value, {
    Color? foreground,
    BorderRadius borderRadius = BorderRadius.zero,
  }) => SizedBox(
    height: _rowHeight,
    width: _width,
    child: TextButton(
      onPressed: () => Navigator.pop(context, value),
      style: TextButton.styleFrom(
        foregroundColor: foreground ?? context.palette.textPrimary,
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          fontFamily: kAppFontFamily,
        ),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      child: Center(child: Text(text)),
    ),
  );

  static Widget _divider(BuildContext context) =>
      Container(width: _width, height: 2, color: context.palette.divider);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: _width,
      height: 153,
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _rowHeight,
            width: _width,
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: _green,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  fontFamily: kAppFontFamily,
                ),
              ),
            ),
          ),
          Container(width: _width, height: 1, color: _green),
          _option(context, l10n.profileImageFromGallery, ImageOption.gallery),
          _divider(context),
          _option(context, l10n.profileImageTakePhoto, ImageOption.camera),
          _divider(context),
          _option(
            context,
            deleteLabel,
            ImageOption.delete,
            foreground: _red,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
        ],
      ),
    );
  }
}
