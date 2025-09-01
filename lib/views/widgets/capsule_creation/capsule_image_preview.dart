import 'package:flutter/material.dart';
import 'dart:io';

class CapsuleImagePreview extends StatelessWidget {
  final String imagePath;

  const CapsuleImagePreview({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25), 
      child: Image.file(File(imagePath), fit: BoxFit.cover),
    );
  }
}
