import 'dart:io';
import 'package:flutter/material.dart';

class CapsuleCreationPage extends StatelessWidget {
  final String imagePath;

  const CapsuleCreationPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 120,
                height: 120,
                child: Image.file(File(imagePath), fit: BoxFit.cover),
              ),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  //TODO : Proper handling of returning to WidgetTree
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("Post"),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
