import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../motion/app_motion_widgets.dart';

/// How a [PillV2] is filled: solid green for the one main action, soft
/// green for a secondary one, outlined for the rest.
enum PillV2Kind { solid, soft, outline }

/// The two pill sizes: small 28 dp (13 bold), medium 36 dp (15 bold).
enum PillV2Size { small, medium }

/// The pill of the v2 design (Figma "Pill v2"): one family for buttons with
/// words on cards and sheets. Green text is `accentText` (4.5:1).
class PillV2 extends StatelessWidget {
  const PillV2({
    super.key,
    required this.label,
    this.onTap,
    this.kind = PillV2Kind.solid,
    this.size = PillV2Size.medium,
  });

  final String label;

  /// Null: shown, not pressable (a status such as "Locked").
  final VoidCallback? onTap;
  final PillV2Kind kind;
  final PillV2Size size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final small = size == PillV2Size.small;
    final height = small ? 28.0 : 36.0;
    final color = kind == PillV2Kind.solid
        ? AppColors.onAccent
        : palette.accentText;
    final pill = Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: small ? 12 : 16),
      decoration: BoxDecoration(
        color: switch (kind) {
          PillV2Kind.solid => AppColors.brandGreen,
          PillV2Kind.soft => palette.accentSoft,
          PillV2Kind.outline => null,
        },
        borderRadius: BorderRadius.circular(height / 2),
        border: kind == PillV2Kind.outline
            ? Border.all(color: palette.accentText, width: 1.5)
            : null,
      ),
      // As wide as its words (a Container with an alignment would fill
      // the room it is given).
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: small ? 13 : 15,
            fontWeight: FontWeight.bold,
            height: 1,
            color: color,
          ),
        ),
      ),
    );
    final tap = onTap;
    if (tap == null) return pill;
    return Semantics(
      button: true,
      child: AppPressable(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: tap,
          child: pill,
        ),
      ),
    );
  }
}
