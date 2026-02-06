import 'package:flutter/material.dart';

class LaterLoadingBar extends StatelessWidget {
  final String assetPath;
  final double width;
  final double height;
  final String? message;
  final double? messageSpacing;
  final TextStyle? messageStyle;

  const LaterLoadingBar({
    super.key,
    this.assetPath = 'assets/gifs/loading/later_logo_loading.gif',
    this.width = 150,
    this.height = 150,
    this.message,
    this.messageSpacing,
    this.messageStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(assetPath, width: width, height: height),
          if (message != null) ...[
            SizedBox(height: messageSpacing ?? 20),
            Text(
              message!,
              style: messageStyle ?? const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
