import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons/default_icon_button.dart';

/// Above the composer while answering a message: whose message and what it
/// said, and a button to stop answering.
class ReplyBar extends StatelessWidget {
  const ReplyBar({
    super.key,
    required this.name,
    required this.text,
    required this.onCancel,
  });

  final String name;
  final String text;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final palette = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        screen.width * 0.03,
        8,
        screen.width * 0.03,
        0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadii.m),
          boxShadow: AppShadows.card(context),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.brandGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandGreen,
                      ),
                    ),
                    Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              DefaultIconButton(
                onTap: onCancel,
                assetPath: AppIcons.capsuleClose,
                size: 22,
                semanticLabel: context.l10n.commonCancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
