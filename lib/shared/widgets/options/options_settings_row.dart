import 'package:flutter/material.dart';
import 'package:later/app/router/app_page_route.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/shared/widgets/options/settings_row_layout.dart';
import 'package:later/core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

class OptionsSettingsRow extends StatelessWidget {
  final String title;
  final Widget? subtitle;
  final Widget? trailing;
  final String? leadingIconPath;
  final bool isLast;
  final bool withDivider;
  final VoidCallback? onTap;
  final Widget? navigateTo;
  final double minVerticalPadding;

  const OptionsSettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.isLast = false,
    this.onTap,
    this.navigateTo,
    this.trailing,
    this.leadingIconPath,
    this.minVerticalPadding = 6,
    this.withDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth * 0.09;
    return Column(
      children: [
        SettingsRowLayout(
          padding: EdgeInsets.only(
            left: screenWidth * 0.05,
            right: screenWidth * 0.03,
          ),
          verticalPadding: minVerticalPadding,
          title: DefaultText(
            title,
            textAlign: TextAlign.start,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.045,
            color: isLast ? AppColors.danger : context.palette.textPrimary,
          ),
          subtitle: subtitle,
          leading: leadingIconPath != null
              ? Image.asset(leadingIconPath!, width: iconSize, height: iconSize)
              : null,
          trailing: isLast
              ? null
              : trailing ??
                    Image.asset(
                      AppIcons.goHere,
                      width: iconSize,
                      height: iconSize,
                      // Dimmed in its own paint (an Opacity widget would
                      // be a layer per row).
                      opacity: const AlwaysStoppedAnimation(0.3),
                    ),
          onTap: navigateTo != null
              ? () => Navigator.push(context, appRoute<void>(navigateTo!))
              : onTap,
        ),
        if (!isLast && withDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 0,
            endIndent: 0,
            color: context.palette.divider,
          ),
      ],
    );
  }
}
