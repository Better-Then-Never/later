import 'package:flutter/material.dart';
import 'package:later/core/theme/app_palette.dart';
import 'package:later/data/services/app_image_cache.dart';

class NotificationThumbnail extends StatelessWidget {
  final String? thumbnailImage;
  final double size;

  const NotificationThumbnail({
    super.key,
    required this.thumbnailImage,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    if (thumbnailImage == null || thumbnailImage!.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: thumbnailImage!.startsWith('http')
          ? Image(
              image: AppImageCache.provider(
                thumbnailImage!,
                width: AppImageCache.decodeWidth(
                  size,
                  MediaQuery.devicePixelRatioOf(context),
                ),
              ),
              width: size,
              height: size,
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, sync) =>
                  sync || frame != null
                  ? child
                  : Container(
                      width: size,
                      height: size,
                      color: context.palette.skeleton,
                    ),
              errorBuilder: (context, error, stackTrace) =>
                  _buildErrorWidget(context),
            )
          : Image.asset(
              thumbnailImage!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildErrorWidget(context),
            ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: size,
      height: size,
      color: palette.skeleton,
      child: Icon(Icons.image, color: palette.iconMuted),
    );
  }
}
