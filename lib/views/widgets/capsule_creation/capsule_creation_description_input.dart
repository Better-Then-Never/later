import 'package:flutter/material.dart';

class CapsuleCreationDescriptionInputField extends StatelessWidget {
  final TextEditingController controller;

  const CapsuleCreationDescriptionInputField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: "Add description...",
          hintStyle: TextStyle(
            fontFamily: 'Irina',
            fontSize: 15,
            fontWeight: FontWeight.normal,
          ),
          border: InputBorder.none,
        ),
        style: const TextStyle(
          fontFamily: 'Irina',
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
