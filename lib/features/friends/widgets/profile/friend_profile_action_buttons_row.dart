import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:later/shared/widgets/buttons/default_icon_button.dart';

class ProfileActionButtonsRow extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback? onOptions;

  const ProfileActionButtonsRow({
    super.key,
    required this.onBack,
    required this.onShare,
    this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // Clear of the status bar / notch (BUG-086); 32 as before otherwise.
      top: math.max(32, MediaQuery.paddingOf(context).top + 8),
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DefaultIconButton(
            onTap: onBack,
            assetPath: AppIcons.goBackCircle,
            size: 44,
          ),

          Row(
            children: [
              DefaultIconButton(
                onTap: onShare,
                assetPath: AppIcons.share,
                size: 44,
              ),
              if (onOptions != null) ...[
                const SizedBox(width: 8),
                DefaultIconButton(
                  onTap: onOptions!,
                  assetPath: AppIcons.openMenu,
                  size: 44,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
