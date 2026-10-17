import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../data/services/app_image_cache.dart';

/// A photo from the network with the app's placeholders: a grey box while it
/// loads (fading the image in), and the same box with a picture icon when it
/// cannot be loaded (as the notification thumbnail always looked).
///
/// Photos come from the disk cache after the first download and are decoded
/// at a bucketed width (AppImageCache), from [cacheWidth] when given, else
/// from the space the widget gets.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  final String url;
  final BoxFit fit;

  /// Decode width in pixels (rounded up to a bucket).
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final cacheWidth = this.cacheWidth;
    if (cacheWidth != null) {
      return _image(context, AppImageCache.decodeWidth(cacheWidth * 1.0, 1));
    }
    return LayoutBuilder(
      builder: (context, constraints) => _image(
        context,
        constraints.hasBoundedWidth
            ? AppImageCache.decodeWidth(
                constraints.maxWidth,
                MediaQuery.devicePixelRatioOf(context),
              )
            : null,
      ),
    );
  }

  Widget _image(BuildContext context, int? width) {
    return Image(
      image: AppImageCache.provider(url, width: width),
      fit: fit,
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
