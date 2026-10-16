import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
    barrierColor: AppColors.barrier,
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
  static const _red = Color.fromARGB(253, 253, 65, 64);

  Widget _option(
    BuildContext context,
    String text,
    ImageOption value, {
    Color foreground = AppColors.black,
    BorderRadius borderRadius = BorderRadius.zero,
  }) => SizedBox(
    height: _rowHeight,
    width: _width,
    child: TextButton(
      onPressed: () => Navigator.pop(context, value),
      style: TextButton.styleFrom(
        foregroundColor: foreground,
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

  static Widget _divider() =>
      Container(width: _width, height: 2, color: AppColors.divider);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      height: 153,
      decoration: BoxDecoration(
        color: AppColors.white,
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
          _option(context, 'Choose from gallery', ImageOption.gallery),
          _divider(),
          _option(context, 'Take a photo', ImageOption.camera),
          _divider(),
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
