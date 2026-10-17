import 'package:flutter/material.dart';
import 'package:later/core/theme/app_colors.dart';

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
          ? Image.network(
              thumbnailImage!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
            )
          : Image.asset(
              thumbnailImage!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
            ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: size,
      height: size,
      color: AppColors.grey300,
      child: const Icon(Icons.image, color: AppColors.grey500),
    );
  }
}
