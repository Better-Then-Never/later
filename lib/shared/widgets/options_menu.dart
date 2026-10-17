import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_palette.dart';
import 'app_sheets.dart';

export 'app_sheets.dart' show showCenteredSheet;

/// White rounded card holding [OptionsMenuItem]s separated by
/// [OptionsMenuDivider]s.
class OptionsMenu extends StatelessWidget {
  const OptionsMenu({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSheets.cardWidth,
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppSheets.radius),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class OptionsMenuItem extends StatelessWidget {
  const OptionsMenuItem({
    super.key,
    required this.text,
    required this.onPressed,
    this.textColor,
    this.trailing,
    this.isFirst = false,
    this.isLast = false,
  });

  final String text;
  final VoidCallback onPressed;
  final Color? textColor;

  /// At the right edge, e.g. a chevron for a row that opens a submenu.
  final Widget? trailing;

  /// Round the top / bottom corners to match the card.
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(AppSheets.radius);
    final borderRadius = BorderRadius.only(
      topLeft: isFirst ? radius : Radius.zero,
      topRight: isFirst ? radius : Radius.zero,
      bottomLeft: isLast ? radius : Radius.zero,
      bottomRight: isLast ? radius : Radius.zero,
    );

    return SizedBox(
      height: 37,
      width: AppSheets.cardWidth,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: textColor ?? context.palette.textPrimary,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            fontFamily: kAppFontFamily,
          ),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
        ),
        child: trailing == null
            ? Center(child: Text(text))
            : Stack(
                alignment: Alignment.center,
                children: [
                  // The full row, so [trailing] sits at its right edge.
                  const SizedBox(width: double.infinity),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Positioned(right: 4, child: trailing!),
                ],
              ),
      ),
    );
  }
}

class OptionsMenuDivider extends StatelessWidget {
  const OptionsMenuDivider({super.key, this.color, this.thickness = 2});

  final Color? color;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSheets.cardWidth,
      height: thickness,
      color: color ?? context.palette.divider,
    );
  }
}

/// The green title row on top of a menu, with its green rule: whose
/// picture, which friend.
class OptionsMenuTitle extends StatelessWidget {
  const OptionsMenuTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 37,
          width: AppSheets.cardWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              // A long name shrinks instead of being cut.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  maxLines: 1,
                  style: const TextStyle(
                    color: AppColors.brandGreen,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    fontFamily: kAppFontFamily,
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          width: AppSheets.cardWidth,
          height: 1,
          color: AppColors.brandGreen,
        ),
      ],
    );
  }
}
