import 'package:flutter/material.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:later/views/widgets/_common/default_buttons/default_icon_button.dart';

class GoBackButton extends DefaultIconButton {
  GoBackButton({
    super.key,
    required BuildContext context,
    super.size,
    bool isBlack = true,
  }) : super(
         onTap: () => Navigator.pop(context),
         assetPath: isBlack ? AppIcons.goBack : AppIcons.goBackWhite,
       );
}
