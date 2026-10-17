import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/chat.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../chat_time.dart';
import 'photo_message.dart';

/// One message: brand green on the right for the user's own, a white card on
/// the left for the friend's. Consecutive messages of one sender form a
/// group; [showTail] squares the bottom corner of the group's last bubble.
/// Capsule messages show the capsule's photo; tapping it calls
/// [onCapsuleTap]. Photos show their picture ([PhotoMessage]) with the
/// caption under it; tapping calls [onPhotoTap]. A message still sending is
/// shown at once; a failed one is faded until it is retried.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showTail = false,
    this.onCapsuleTap,
    this.onPhotoTap,
    this.replyName,
    this.onQuoteTap,
  });

  final ChatMessage message;
  final bool isMine;
  final bool showTail;
  final VoidCallback? onCapsuleTap;
  final VoidCallback? onPhotoTap;

  /// Whose message [ChatMessage.replyTo] quotes ("You" or the friend).
  final String? replyName;

  /// Tapping the quote (shows the answered message).
  final VoidCallback? onQuoteTap;

  static const _radius = Radius.circular(AppRadii.m);
  static const _tail = Radius.circular(6);

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final palette = context.palette;
    final textColor = isMine ? AppColors.onAccent : palette.textPrimary;
    final imageUrl = message.imageUrl;
    final sentAt = message.sentAt;
    final failed = message.delivery == MessageDelivery.failed;
    // A reply's quote spans the bubble: the column is laid out at its
    // natural width and every line stretches to it.
    final quoted = message.replyTo != null;
    // A photo fills its bubble but for a thin frame.
    final photo = message.type == ChatMessageType.image;
    final photoWidth = photo
        ? PhotoMessage.displaySize(message, screen).width
        : 0.0;

    final bubble = Container(
      padding: photo
          ? const EdgeInsets.fromLTRB(4, 4, 4, 6)
          : EdgeInsets.symmetric(
              horizontal: screen.width * 0.035,
              vertical: screen.height * 0.009,
            ),
      constraints: BoxConstraints(maxWidth: screen.width * 0.72),
      decoration: BoxDecoration(
        color: isMine ? AppColors.brandGreen : palette.surface,
        borderRadius: BorderRadius.only(
          topLeft: _radius,
          topRight: _radius,
          bottomLeft: showTail && !isMine ? _tail : _radius,
          bottomRight: showTail && isMine ? _tail : _radius,
        ),
        boxShadow: isMine ? null : AppShadows.card(context),
      ),
      child: _NaturalWidth(
        enabled: quoted,
        child: Column(
          crossAxisAlignment: quoted
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.replyTo case final reply?)
              GestureDetector(
                onTap: onQuoteTap,
                child: _Quote(
                  name: replyName ?? '',
                  text: reply.text,
                  onGreen: isMine,
                ),
              ),
            if (message.isCapsule) ...[
              if (imageUrl != null)
                Semantics(
                  button: true,
                  label: context.l10n.messagesOpenCapsule(message.text),
                  child: GestureDetector(
                    onTap: onCapsuleTap,
                    child: _CapsulePhoto(
                      imageUrl: imageUrl,
                      width: screen.width * 0.6,
                      height: screen.width * 0.45,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: screen.height * 0.02,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ] else if (photo) ...[
              PhotoMessage(message: message, onTap: onPhotoTap),
              if (message.caption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                  child: SizedBox(
                    width: photoWidth - 12,
                    child: Text(
                      message.caption,
                      style: TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: screen.height * 0.022,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
            ] else
              Text(
                message.text,
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: screen.height * 0.022,
                  color: textColor,
                ),
              ),
            if (sentAt != null) ...[
              const SizedBox(height: 2),
              Padding(
                padding: EdgeInsets.only(right: photo ? 6 : 0),
                child: Text(
                  ChatTime.messageTime(sentAt, locale: context.l10n.localeName),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 11,
                    // Muted white on the green bubble, the same in both themes.
                    color: isMine ? AppColors.onMediaMuted : palette.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Opacity(opacity: failed ? 0.5 : 1, child: bubble),
    );
  }
}

/// [IntrinsicWidth] only when [enabled] (it costs a second layout pass).
class _NaturalWidth extends StatelessWidget {
  const _NaturalWidth({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      enabled ? IntrinsicWidth(child: child) : child;
}

/// The answered message inside a reply: a coloured edge, the name and the
/// start of its text.
class _Quote extends StatelessWidget {
  const _Quote({required this.name, required this.text, required this.onGreen});

  final String name;
  final String text;

  /// On the user's own (green) bubble: white tones instead of green.
  final bool onGreen;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = onGreen ? AppColors.onAccent : AppColors.brandGreen;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: onGreen
              ? AppColors.onAccent.withAlpha(0x2E)
              : palette.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadii.xxs),
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppRadii.xxs),
                  ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 10, 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                      Text(
                        text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 13,
                          color: onGreen
                              ? AppColors.onMediaMuted
                              : palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CapsulePhoto extends StatelessWidget {
  const _CapsulePhoto({
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  final String imageUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.s),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(url: imageUrl),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
                // A small card on the photo: it follows the theme, like the
                // capsule icon (swapped for dark by ThemedAssetBundle).
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  borderRadius: AppRadii.lCircular,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(AppIcons.sendCapsule, width: 18, height: 18),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.messagesCapsuleLabel,
                      style: TextStyle(
                        fontFamily: kAppFontFamily,
                        color: context.palette.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
