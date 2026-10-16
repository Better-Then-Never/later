import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Shows [child] centred over a dimmed barrier; tapping outside closes it.
/// The look of every option menu and confirmation in the app.
Future<T?> showCenteredSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: AppColors.barrier,
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: GestureDetector(onTap: () {}, child: child),
        ),
      ),
    );

/// White rounded card holding [OptionsMenuItem]s separated by
/// [OptionsMenuDivider]s.
class OptionsMenu extends StatelessWidget {
  const OptionsMenu({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
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
    this.isFirst = false,
    this.isLast = false,
  });

  final String text;
  final VoidCallback onPressed;
  final Color? textColor;

  /// Round the top / bottom corners to match the card.
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(25);
    final borderRadius = BorderRadius.only(
      topLeft: isFirst ? radius : Radius.zero,
      topRight: isFirst ? radius : Radius.zero,
      bottomLeft: isLast ? radius : Radius.zero,
      bottomRight: isLast ? radius : Radius.zero,
    );

    return SizedBox(
      height: 37,
      width: 264,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: textColor ?? AppColors.black,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            fontFamily: kAppFontFamily,
          ),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
        ),
        child: Center(child: Text(text)),
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
      width: 264,
      height: thickness,
      color: color ?? AppColors.divider,
    );
  }
}
