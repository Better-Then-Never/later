import 'package:flutter/material.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/shared/widgets/buttons/default_icon_button.dart';

class GoBackButton extends DefaultIconButton {
  GoBackButton({
    super.key,
    required BuildContext context,
    super.size,
    bool isBlack = true,
  }) : super(
         onTap: () => Navigator.pop(context),
         assetPath: isBlack ? AppIcons.goBack : AppIcons.goBackWhite,
         // Read out by screen readers (the arrow alone says nothing).
         semanticLabel: context.l10n.commonBack,
       );
}
