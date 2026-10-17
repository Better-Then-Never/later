import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../data/models/chat.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../messages/chats_store.dart';
import '../../users/user_directory.dart';

/// A quick reply to someone's capsule: a card with a field; what is written
/// goes to the author's chat with the capsule attached.
class QuickReplyCard extends StatefulWidget {
  const QuickReplyCard({super.key, required this.capsule});

  final Capsule capsule;

  static Future<void> show(BuildContext context, Capsule capsule) =>
      showCenteredSheet<void>(context, QuickReplyCard(capsule: capsule));

  @override
  State<QuickReplyCard> createState() => _QuickReplyCardState();
}

class _QuickReplyCardState extends State<QuickReplyCard> {
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send(String name) async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final failure = await context.read<ChatsStore>().replyToCapsule(
      widget.capsule,
      text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (failure != null) {
      PopupNotificationService.showError(
        context: context,
        message: failure.message,
        position: NotificationPosition.top,
      );
      return;
    }
    navigator.pop();
    final root = navigator.context;
    if (root.mounted) {
      PopupNotificationService.showSuccess(
        context: root,
        message: l10n.capsulesQuickReplySent(name),
        position: NotificationPosition.bottom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final owner = widget.capsule.ownerId;
    final name = context.select<UserDirectory, String>(
      (d) => d.profile(owner)?.name ?? '',
    );
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSheets.radius),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              widget.capsule.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSheets.radius),
                  ),
                  child: TextField(
                    controller: _text,
                    autofocus: true,
                    minLines: 1,
                    maxLines: 4,
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
                      hintText: l10n.capsulesQuickReplyHint(name),
                      hintStyle: TextStyle(
                        fontFamily: kAppFontFamily,
                        color: palette.textMuted,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: l10n.messagesSend,
                child: AppPressable(
                  child: GestureDetector(
                    onTap: () => _send(name),
                    child: Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(9),
                      decoration: const BoxDecoration(
                        color: AppColors.brandGreen,
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onAccent,
                            )
                          : Image.asset(AppIcons.messagesSend),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
