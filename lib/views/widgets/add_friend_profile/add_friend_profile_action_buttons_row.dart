import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_buttons/default_icon_button.dart';

class AddFriendProfileActionButtons extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onShare;

  const AddFriendProfileActionButtons({
    super.key,
    required this.onBack,
    required this.onShare,
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
          DefaultIconButton(
            onTap: onShare,
            assetPath: 'assets/images/icons/prof_page/share_button.png',
            size: 44,
          ),
        ],
      ),
    );
  }
}
