import 'package:flutter/material.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:later/shared/widgets/buttons/default_icon_button.dart';
import 'package:later/core/theme/app_text_styles.dart';
import '../../core/theme/app_palette.dart';
import '../../core/l10n/l10n.dart';

class DefaultSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final DefaultIconButton? trailingButton;

  /// "Search..." in the app's language when null.
  final String? hintText;
  final Color? color;
  final void Function(String value)? onChanged;
  final FocusNode? searchFocusNode;

  const DefaultSearchBar({
    super.key,
    required this.controller,
    this.trailingButton,
    this.hintText,
    this.color,
    this.searchFocusNode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color ?? context.palette.surfaceMuted,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Image.asset(
                AppIcons.friendsLookFor,
                width: screenWidth * 0.07,
                height: screenWidth * 0.07,
              ),
            ),
            Expanded(
              child: TextField(
                focusNode: searchFocusNode,
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText ?? context.l10n.commonSearchHint,
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 22,
                ),
                onChanged: (value) {
                  if (onChanged != null) {
                    onChanged!(value);
                  }
                },
              ),
            ),
            if (trailingButton != null)
              Padding(
                padding: EdgeInsetsGeometry.only(right: screenWidth * 0.03),
                child: trailingButton,
              ),
          ],
        ),
      ),
    );
  }
}
