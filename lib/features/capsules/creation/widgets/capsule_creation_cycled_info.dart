import 'package:flutter/material.dart';
import 'package:later/shared/styles/box_decorations.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/core/theme/app_colors.dart';

class CapsuleCreationCycledInfo extends StatelessWidget {
  final String infoText;
  final String? trailingLeadingIconPath;

  const CapsuleCreationCycledInfo({
    super.key,
    required this.infoText,
    this.trailingLeadingIconPath,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Container(
        decoration: BoxDecorations.defaultBorderRadius(color: AppColors.pill),
        width: screenWidth * 0.4,
        alignment: Alignment.centerRight,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  DefaultText(
                    infoText,
                    fontSize: 35,
                    color: AppColors.textTertiary,
                  ),
                  if (trailingLeadingIconPath != null) const SizedBox(width: 8),
                  if (trailingLeadingIconPath != null)
                    Image.asset(
                      trailingLeadingIconPath!,
                      width: screenWidth * 0.1,
                      height: screenWidth * 0.1,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
