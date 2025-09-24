import 'package:flutter/material.dart';

class BoxDecorations {
  static BoxDecoration whiteCard({double borderRadius = 25}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          spreadRadius: 1,
          blurRadius: 9,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration blackShadow() {
    return BoxDecoration(
      color: const Color.fromARGB(255, 0, 0, 0),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(120),
          spreadRadius: 60,
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      ],
    );
  }
}
