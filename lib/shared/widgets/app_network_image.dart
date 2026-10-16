import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';

/// A photo from the network with the app's placeholders: a grey box while it
/// loads (fading the image in), and the same box with a picture icon when it
/// cannot be loaded (as the notification thumbnail always looked).
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  final String url;
  final BoxFit fit;

  /// Decode width in pixels (keeps large photos small in memory).
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return Stack(
          fit: StackFit.passthrough,
          children: [
            ColoredBox(color: context.palette.skeleton),
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: AppMotion.of(context, AppMotion.fast),
              curve: AppMotion.enter,
              child: child,
            ),
          ],
        );
      },
      errorBuilder: (_, _, _) => ColoredBox(
        color: context.palette.skeleton,
        child: Center(
          child: Icon(Icons.image, color: context.palette.iconMuted),
        ),
      ),
    );
  }
}
