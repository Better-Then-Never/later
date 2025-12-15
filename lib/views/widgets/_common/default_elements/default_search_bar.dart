import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_buttons/default_icon_button.dart';

class DefaultSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final DefaultIconButton? trailingButton;
  final String hintText;
  final Color? color;
  final void Function(String value)? onChanged;
  final FocusNode? searchFocusNode;

  const DefaultSearchBar({
    super.key,
    required this.controller,
    this.trailingButton,
    this.hintText = "Search...",
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
          color: color ?? Color(0xFFEAEAEA),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Image.asset(
                'assets/images/icons/friends_page/look_for.png',
                width: screenWidth * 0.07,
                height: screenWidth * 0.07,
              ),
            ),
            Expanded(
              child: TextField(
                focusNode: searchFocusNode ?? null,
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(fontFamily: 'Irina', fontSize: 22),
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
