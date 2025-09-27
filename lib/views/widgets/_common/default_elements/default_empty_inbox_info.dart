import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';

class DefaultEmptyInboxInfo extends StatelessWidget {
  final String message;
  final String? subtitle;
  final String assetPath;

  const DefaultEmptyInboxInfo({
    super.key,
    required this.message,
    this.subtitle,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(assetPath, width: 72, height: 72),
          SizedBox(height: 5),
          DefaultText(
            message,
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: 8),
          if (subtitle != null)
            DefaultText(
              subtitle!,
              textAlign: TextAlign.center,
              fontSize: screenWidth * 0.035,
              color: Colors.grey[600],
            ),
        ],
      ),
    );
  }
}
