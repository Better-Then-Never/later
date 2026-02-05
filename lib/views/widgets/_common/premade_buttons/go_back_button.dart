import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_buttons/default_icon_button.dart';

class GoBackButton extends DefaultIconButton {
  GoBackButton({
    super.key,
    required BuildContext context,
    double? size,
    bool isBlack = true,
  }) : super(
         size: size,
         onTap: () => Navigator.pop(context),
         assetPath: isBlack
             ? 'assets/images/icons/prof_page/go_back.png'
             : 'assets/images/icons/prof_page/go_back_white.png',
       );
}
