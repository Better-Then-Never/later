import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../data/models/chat.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../../../shared/widgets/capsule/capsule_author_row.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../messages/chats_store.dart';

/// A quick reply to someone's capsule (capsule v3): a card right above the
/// keyboard with the capsule as a chip and a field; what is written goes to
/// the author's chat with the capsule attached. An author who chose not to
/// be shown stays unnamed.
class QuickReplyCard extends StatefulWidget {
  const QuickReplyCard({super.key, required this.capsule});

  final Capsule capsule;

  static Future<void> show(BuildContext context, Capsule capsule) =>
      Navigator.of(context).push(
        AppCardRoute<void>(
          builder: (_) => QuickReplyCard(capsule: capsule),
          alignment: Alignment.bottomCenter,
          barrierColor: context.palette.scrim,
          barrierLabel: MaterialLocalizations.of(
            context,
          ).modalBarrierDismissLabel,
        ),
      );

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

  Future<void> _send(String? name) async {
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
        message: name == null
            ? l10n.messagesReceiptSent
            : l10n.capsulesQuickReplySent(name),
        position: NotificationPosition.bottom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final capsule = widget.capsule;
    final name = CapsuleAuthorRow.ownerFirstNameOf(context, capsule);
    final width = MediaQuery.sizeOf(context).width;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          width: width - 32,
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(AppSheets.radius),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name == null
                    ? l10n.capsulesQuickReply
                    : l10n.capsulesReplyTo(name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _CapsuleChip(capsule: capsule),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
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
                        hintText: name == null
                            ? l10n.messagesInputHint
                            : l10n.capsulesQuickReplyHint(name),
                        hintStyle: TextStyle(
                          fontFamily: kAppFontFamily,
                          color: palette.textMuted,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: palette.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(
                            color: AppColors.brandGreen,
                            width: 1.5,
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
                          width: 46,
                          height: 46,
                          padding: const EdgeInsets.all(10),
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
        ),
      ),
    );
  }
}

/// The capsule that goes along: its photo, title and a word that it is
/// attached.
class _CapsuleChip extends StatelessWidget {
  const _CapsuleChip({required this.capsule});

  final Capsule capsule;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final url = capsule.thumbUrl ?? capsule.imageUrl;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.m),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.s),
            child: SizedBox.square(
              dimension: 40,
              child: url == null
                  ? ColoredBox(color: palette.divider)
                  : AppNetworkImage(url: url),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capsule.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  context.l10n.capsulesQuickReplyAttached,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    color: palette.textMuted,
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
