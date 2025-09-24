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
}
