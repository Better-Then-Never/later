import 'package:flutter/material.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/core/theme/app_palette.dart';
import 'package:later/core/theme/app_text_styles.dart';

/// The capsule's title on the preview card, written in place, as big as it
/// shows on the opened capsule.
class CapsuleCreationTitleInput extends StatelessWidget {
  final TextEditingController controller;
  final int maxTitleLength = 30;
  const CapsuleCreationTitleInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextField(
      controller: controller,
      maxLength: maxTitleLength,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: context.l10n.capsulesCreationTitleHint,
        counterText: '',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        hintStyle: TextStyle(
          fontSize: 24,
          fontFamily: kAppFontFamily,
          fontWeight: FontWeight.bold,
          color: palette.textMuted,
        ),
        border: InputBorder.none,
      ),
      style: TextStyle(
        fontSize: 24,
        fontFamily: kAppFontFamily,
        fontWeight: FontWeight.bold,
        color: palette.textPrimary,
      ),
    );
  }
}
