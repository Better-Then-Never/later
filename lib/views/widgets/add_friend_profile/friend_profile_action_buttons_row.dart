import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_buttons/default_icon_button.dart';

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
      top: 32,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DefaultIconButton(
            onTap: onBack,
            assetPath: 'assets/images/icons/prof_page/go_back_circle.png',
            size: 44,
          ),

          Row(
            children: [
              DefaultIconButton(
                onTap: onShare,
                assetPath: 'assets/images/icons/prof_page/share_button.png',
                size: 44,
              ),
              if (onOptions != null) ...[
                const SizedBox(width: 8),
                DefaultIconButton(
                  onTap: onOptions!,
                  assetPath: 'assets/images/icons/prof_page/open_menu.png',
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
