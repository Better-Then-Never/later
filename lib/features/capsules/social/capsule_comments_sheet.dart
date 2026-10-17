import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/social.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/default_empty_inbox_info.dart';
import '../../../shared/widgets/options_menu.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../../shared/widgets/user/user_round_avatar.dart';
import '../../notifications/notification_texts.dart';
import '../../users/user_directory.dart';
import 'capsule_social_controller.dart';
import 'capsule_social_panel.dart';

/// The comments of a capsule: one level of replies, newest at the bottom,
/// a composer under the list (F-50). Long press a comment to reply, delete
/// (author or capsule owner) or report it.
class CapsuleCommentsSheet extends StatefulWidget {
  const CapsuleCommentsSheet({super.key, required this.controller});

  final CapsuleSocialController controller;

  static Future<void> show(
    BuildContext context,
    CapsuleSocialController controller,
  ) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: context.palette.scrim,
    builder: (_) => CapsuleCommentsSheet(controller: controller),
  );

  @override
  State<CapsuleCommentsSheet> createState() => _CapsuleCommentsSheetState();
}

class _CapsuleCommentsSheetState extends State<CapsuleCommentsSheet> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  CapsuleComment? _replyTo;
  bool _sending = false;

  CapsuleSocialController get _c => widget.controller;

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _showError(String message) => PopupNotificationService.showError(
    context: context,
    message: message,
    position: NotificationPosition.top,
  );

  Future<void> _send() async {
    if (_sending || _text.text.trim().isEmpty) return;
    setState(() => _sending = true);
    // Replies always attach to the top-level comment (one level).
    final reply = _replyTo;
    final failure = await _c.addComment(
      _text.text,
      replyTo: reply == null ? null : (reply.replyTo ?? reply.id),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (failure != null) {
      _showError(failure.message);
      return;
    }
    _text.clear();
    setState(() => _replyTo = null);
  }

  void _startReply(CapsuleComment comment) {
    setState(() => _replyTo = comment);
    _focus.requestFocus();
  }

  Future<void> _options(CapsuleComment comment) async {
    final l10n = context.l10n;
    final canDelete = _c.canDelete(comment);
    final mine = comment.authorId == _c.uid;
    final choice = await showCenteredSheet<String>(
      context,
      OptionsMenu(
        children: [
          OptionsMenuItem(
            text: l10n.capsulesReply,
            isFirst: true,
            isLast: !canDelete && mine,
            onPressed: () => Navigator.of(context).pop('reply'),
          ),
          if (canDelete) ...[
            const OptionsMenuDivider(),
            OptionsMenuItem(
              text: l10n.capsulesCommentDelete,
              textColor: AppColors.danger,
              isLast: mine,
              onPressed: () => Navigator.of(context).pop('delete'),
            ),
          ],
          if (!mine) ...[
            const OptionsMenuDivider(),
            OptionsMenuItem(
              text: l10n.capsulesReport,
              textColor: AppColors.danger,
              isLast: true,
              onPressed: () => Navigator.of(context).pop('report'),
            ),
          ],
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'reply':
        _startReply(comment);
      case 'delete':
        await ConfirmDialog.show(
          context: context,
          title: l10n.capsulesCommentDeleteConfirm,
          confirmText: l10n.commonDelete,
          onConfirm: () async {
            final failure = await _c.deleteComment(comment);
            if (failure != null && mounted) _showError(failure.message);
          },
        );
      case 'report':
        await reportFlow(
          context,
          _c,
          target: ReportTarget.comment,
          targetPath: 'capsules/${_c.capsule.id}/comments/${comment.id}',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final palette = context.palette;
    final l10n = context.l10n;
    final directory = context.watch<UserDirectory>();
    final replyName = _replyTo == null
        ? null
        : (directory.profile(_replyTo!.authorId)?.name ?? '');

    return Padding(
      // The composer rides on top of the keyboard.
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        // Three quarters of the screen, less when the keyboard needs room
        // (it never reaches under the status bar).
        height: math.min(
          media.size.height * 0.75,
          media.size.height -
              media.viewInsets.bottom -
              media.viewPadding.top -
              12,
        ),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Grab handle: the sheet can be dragged down to close.
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: palette.disabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Text(
                l10n.capsulesComments,
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _c,
                builder: (context, _) {
                  if (!_c.commentsLoaded) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final thread = _c.thread;
                  if (thread.isEmpty) {
                    return DefaultEmptyInboxInfo(
                      message: l10n.capsulesCommentsEmpty,
                      subtitle: l10n.capsulesCommentsEmptyHint,
                      assetPath: AppIcons.messagesNew,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    itemCount: thread.length,
                    itemBuilder: (context, index) {
                      final comment = thread[index];
                      return _CommentRow(
                        key: ValueKey(comment.id),
                        comment: comment,
                        isMine: comment.authorId == _c.uid,
                        onReply: comment.replyTo == null
                            ? () => _startReply(comment)
                            : null,
                        onLongPress: () => _options(comment),
                      );
                    },
                  );
                },
              ),
            ),
            if (replyName != null)
              Container(
                color: palette.surfaceMuted,
                padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.capsulesReplyHint(replyName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.commonCancel,
                      onPressed: () => setState(() => _replyTo = null),
                      icon: Image.asset(AppIcons.capsuleClose, width: 18),
                    ),
                  ],
                ),
              ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                color: palette.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        focusNode: _focus,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: CapsuleComment.maxLength,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          color: palette.textPrimary,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          isDense: true,
                          hintText: l10n.capsulesCommentHint,
                          filled: true,
                          fillColor: palette.surfaceMuted,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.messagesSend,
                      onPressed: _sending ? null : _send,
                      icon: Image.asset(AppIcons.messagesSend, width: 30),
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

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    super.key,
    required this.comment,
    required this.isMine,
    required this.onReply,
    required this.onLongPress,
  });

  final CapsuleComment comment;
  final bool isMine;

  /// Null for replies (one level only).
  final VoidCallback? onReply;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final name = isMine
        ? l10n.capsulesYou
        : context.select<UserDirectory, String>(
            (d) => d.profile(comment.authorId)?.name ?? '',
          );
    final at = comment.createdAt;
    return Padding(
      padding: EdgeInsets.only(
        left: comment.replyTo == null ? 0 : 40,
        bottom: 10,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: onLongPress,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserRoundAvatar(userId: comment.authorId, radius: 17),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (at != null)
                          TextSpan(
                            text:
                                '  ${NotificationTexts.time(at, DateTime.now(), l10n: l10n)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textMuted,
                            ),
                          ),
                      ],
                    ),
                    style: TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 14,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    comment.text,
                    style: TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 15,
                      color: palette.textPrimary,
                    ),
                  ),
                  if (onReply != null)
                    GestureDetector(
                      onTap: onReply,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          l10n.capsulesReply,
                          style: TextStyle(
                            fontFamily: kAppFontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
