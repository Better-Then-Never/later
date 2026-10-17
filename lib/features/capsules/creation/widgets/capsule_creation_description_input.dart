import 'package:flutter/material.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/core/theme/app_text_styles.dart';

class CapsuleCreationDescriptionInputField extends StatelessWidget {
  final TextEditingController controller;

  const CapsuleCreationDescriptionInputField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    const int maxDescriptionLength = 2200;
    return Expanded(
      child: TextField(
        controller: controller,
        maxLength: maxDescriptionLength,
        decoration: InputDecoration(
          hintText: context.l10n.capsulesCreationDescriptionHint,
          counterText: '',
          hintStyle: const TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 15,
            fontWeight: FontWeight.normal,
          ),
          border: InputBorder.none,
        ),
        style: const TextStyle(
          fontFamily: kAppFontFamily,
          fontSize: 15,
          fontWeight: FontWeight.normal,
        ),
        expands: true,
        maxLines: null,
        minLines: null,
      ),
    );
  }
}
