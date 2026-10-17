import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/chat.dart';
import '../../../data/services/app_image_cache.dart';

/// The picture of a photo message, in its own shape (from the size the
/// message carries, so nothing jumps when it arrives). A photo sent from
/// this phone shows the file on the phone; others come from the disk cache.
/// While sending, a small ring turns on it. Tapping it calls [onTap] (the
/// full-screen viewer, flying from here as a [Hero]).
class PhotoMessage extends StatelessWidget {
  const PhotoMessage({super.key, required this.message, this.onTap});

  final ChatMessage message;
  final VoidCallback? onTap;

  static Object heroTag(ChatMessage message) => 'chat-photo:${message.id}';

  /// Where the viewer reads the picture: the phone's file or the URL.
  static String? source(ChatMessage message) {
    final local = message.localPath;
    if (local != null) return Uri.file(local).toString();
    return message.imageUrl;
  }

  /// Width and height on [screen]: at most 62 % of its width and 42 % of
  /// its height, in the photo's proportions (a missing size counts as 3:4;
  /// very long or very wide photos are cropped to 1:2 or 2:1).
  static Size displaySize(ChatMessage message, Size screen) {
    final w = message.width;
    final h = message.height;
    final aspect = (w != null && h != null ? w / h : 3 / 4).clamp(0.5, 2.0);
    final maxWidth = screen.width * 0.62;
    final maxHeight = screen.height * 0.42;
    var width = maxWidth;
    var height = width / aspect;
    if (height > maxHeight) {
      height = maxHeight;
      width = height * aspect;
    }
    return Size(width, height);
  }

  @override
  Widget build(BuildContext context) {
    final size = displaySize(message, MediaQuery.sizeOf(context));
    final decodeWidth = AppImageCache.decodeWidth(
      size.width,
      MediaQuery.devicePixelRatioOf(context),
    );
    final local = message.localPath;
    final url = message.imageUrl;
    final ImageProvider? image = local != null
        ? ResizeImage.resizeIfNeeded(decodeWidth, null, FileImage(File(local)))
        : url != null
        ? AppImageCache.provider(url, width: decodeWidth)
        : null;
    final sending = message.delivery == MessageDelivery.sending;

    return Semantics(
      button: onTap != null,
      image: true,
      label: context.l10n.messagesOpenPhoto,
      child: GestureDetector(
        onTap: onTap,
        child: Hero(
          tag: heroTag(message),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.s),
            child: SizedBox.fromSize(
              size: size,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: context.palette.skeleton),
                  if (image != null)
                    Image(
                      image: image,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  if (sending)
                    Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(9),
                        decoration: const BoxDecoration(
                          color: AppColors.mediaScrim,
                          shape: BoxShape.circle,
                        ),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.onMedia,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
