import 'package:flutter/material.dart';

class CapsuleCreationTitleInput extends StatelessWidget {
  final TextEditingController controller;

  const CapsuleCreationTitleInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        hintText: "Add Title... ",
        hintStyle: TextStyle(
          fontSize: 25,
          fontFamily: 'Irina',
          fontWeight: FontWeight.bold,
        ),
        border: InputBorder.none,
      ),
      style: const TextStyle(
        fontSize: 25,
        fontFamily: 'Irina',
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
