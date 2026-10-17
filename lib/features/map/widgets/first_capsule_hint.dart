import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/styles/box_decorations.dart';
import '../../../shared/widgets/buttons/default_icon_button.dart';

/// Above the navigation bar while the user has no capsule yet: what to do
/// first. Tapping it opens the camera; the cross hides it for good.
class FirstCapsuleHint extends StatelessWidget {
  const FirstCapsuleHint({
    super.key,
    required this.onTap,
    required this.onClose,
  });

  final VoidCallback onTap;
  final VoidCallback onClose;

  /// Known in advance, so the map can keep its Google logo above the card
  /// (F-12); grows with the system text size (D-21).
  static double heightFor(BuildContext context) =>
      88 * MediaQuery.textScalerOf(context).scale(16) / 16;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return Semantics(
      button: true,
      label: l10n.mapFirstCapsuleTitle,
      child: AppPressable(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: heightFor(context),
            padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
            decoration: BoxDecorations.whiteCard(context),
            child: Row(
              children: [
                Image.asset(AppIcons.navbarAdd, width: 44, height: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.mapFirstCapsuleTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.mapFirstCapsuleBody,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 14,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DefaultIconButton(
                    onTap: onClose,
                    assetPath: AppIcons.capsuleClose,
                    size: 22,
                    semanticLabel: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
