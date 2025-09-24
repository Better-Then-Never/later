import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_buttons/default_icon_button.dart';

class GoBackButton extends DefaultIconButton {
  GoBackButton({super.key, required BuildContext context, double? size})
    : super(
        size: size,
        onTap: () => Navigator.pop(context),
        assetPath: 'assets/images/icons/prof_page/go_back.png',
      );
}
