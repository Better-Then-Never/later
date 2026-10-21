import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';

/// The v2 radio (Figma "Radio" / "Radio on"): a grey ring, or a green ring
/// with a green dot.
class AppRadio extends StatelessWidget {
  const AppRadio({super.key, required this.on, this.size = 20});

  final bool on;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * 0.2),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: on ? AppColors.brandGreen : context.palette.disabled,
        width: 2,
      ),
    ),
    child: on
        ? const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.brandGreen,
              shape: BoxShape.circle,
            ),
          )
        : null,
  );
}
