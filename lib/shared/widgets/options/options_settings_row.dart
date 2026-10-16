import 'package:flutter/material.dart';
import 'package:later/app/router/app_page_route.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/core/theme/app_colors.dart';

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
    return Column(
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
          child: ListTile(
            dense: true,
            minVerticalPadding: minVerticalPadding,
            visualDensity: const VisualDensity(vertical: -3),

            title: DefaultText(
              title,
              textAlign: TextAlign.start,
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.045,
              color: isLast ? AppColors.danger : AppColors.black,
            ),
            subtitle: subtitle,
            leading: leadingIconPath != null
                ? Image.asset(
                    leadingIconPath!,
                    width: screenWidth * 0.09,
                    height: screenWidth * 0.09,
                  )
                : null,
            trailing: isLast
                ? null
                : trailing ??
                      (Opacity(
                        opacity: 0.3,
                        child: Image.asset(
                          AppIcons.goHere,
                          width: screenWidth * 0.09,
                          height: screenWidth * 0.09,
                        ),
                      )),
            contentPadding: EdgeInsets.only(
              left: screenWidth * 0.05,
              right: screenWidth * 0.03,
            ),
            onTap: navigateTo != null
                ? () {
                    Navigator.push(context, fadeRoute<void>(navigateTo!));
                  }
                : onTap,
          ),
        ),
        if (!isLast && withDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 0,
            endIndent: 0,
            color: AppColors.divider,
          ),
      ],
    );
  }
}
