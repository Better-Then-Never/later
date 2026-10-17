import 'package:flutter/material.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/core/theme/app_text_styles.dart';

class CapsuleCreationTitleInput extends StatelessWidget {
  final TextEditingController controller;
  final int maxTitleLength = 30;
  const CapsuleCreationTitleInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxTitleLength,
      decoration: InputDecoration(
        hintText: context.l10n.capsulesCreationTitleHint,
        counterText: '',
        hintStyle: const TextStyle(
          fontSize: 25,
          fontFamily: kAppFontFamily,
          fontWeight: FontWeight.bold,
        ),
        border: InputBorder.none,
      ),
      style: const TextStyle(
        fontSize: 25,
        fontFamily: kAppFontFamily,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
