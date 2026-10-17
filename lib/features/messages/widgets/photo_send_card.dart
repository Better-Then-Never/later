import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/chat.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/widgets/app_sheets.dart';

/// Before a photo goes: the picture, a caption field and Send, on a card
/// above the keyboard. Resolves to the caption ('' for none), or null when
/// the card is dismissed (tap outside, drag down, Back).
class PhotoSendCard extends StatefulWidget {
  const PhotoSendCard({super.key, required this.path});

  final String path;

  static Future<String?> show(BuildContext context, String path) =>
      showCenteredSheet<String>(context, PhotoSendCard(path: path));

  @override
  State<PhotoSendCard> createState() => _PhotoSendCardState();
}

class _PhotoSendCardState extends State<PhotoSendCard> {
  final _caption = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  void _send() => Navigator.of(context).pop(_caption.text.trim());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final screen = MediaQuery.sizeOf(context);
    final width = (screen.width - 32).clamp(0.0, 440.0);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSheets.radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: screen.height * 0.5),
            child: ColoredBox(
              color: AppColors.mediaBlack,
              child: Image.file(
                File(widget.path),
                width: width,
                fit: BoxFit.contain,
                cacheWidth: (width * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                errorBuilder: (_, _, _) => SizedBox(height: width * 0.75),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _caption,
                    autofocus: false,
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(Chat.maxMessageLength),
                    ],
                    style: TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 16,
                      color: palette.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.messagesPhotoCaption,
                      hintStyle: TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 16,
                        color: palette.textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: l10n.messagesSend,
                  child: AppPressable(
                    child: GestureDetector(
                      onTap: _send,
                      child: Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(9),
                        decoration: const BoxDecoration(
                          color: AppColors.brandGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(AppIcons.messagesSend),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
