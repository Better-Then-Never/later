import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/social.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../../../shared/widgets/capsule/capsule_author_row.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/default_empty_inbox_info.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../../shared/widgets/user/user_round_avatar.dart';
import '../../notifications/notification_texts.dart';
import '../../users/user_directory.dart';
import 'capsule_social_controller.dart';
import 'capsule_social_panel.dart';

/// The comments of a capsule (capsule v3): one level of replies on a thread
/// line, newest at the bottom, the author's comments marked, a composer under
/// the list. Long press a comment for a small menu beside it: reply, copy,
/// and delete (author or capsule owner) or report.
class CapsuleCommentsSheet extends StatefulWidget {
  const CapsuleCommentsSheet({super.key, required this.controller});

  final CapsuleSocialController controller;

  static Future<void> show(
    BuildContext context,
    CapsuleSocialController controller,
  ) => showEdgeSheet<void>(
    context,
    (_) => CapsuleCommentsSheet(controller: controller),
  );

  @override
  State<CapsuleCommentsSheet> createState() => _CapsuleCommentsSheetState();
}

class _CapsuleCommentsSheetState extends State<CapsuleCommentsSheet> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  CapsuleComment? _replyTo;
  bool _sending = false;

  /// The comment whose menu is open: it is tinted meanwhile.
  String? _pressedId;

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

  /// The small menu beside a long-pressed comment ([row] is its context):
  /// reply, copy, then delete (yours, or any on your capsule) or report.
  Future<void> _options(CapsuleComment comment, BuildContext row) async {
    final l10n = context.l10n;
    final palette = context.palette;
    final canDelete = _c.canDelete(comment);
    final box = row.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    // Under the comment, lined up with its text (a narrow anchor: the menu
    // lines up with its left edge).
    final anchor = Rect.fromLTWH(
      origin.dx + 56,
      origin.dy + box.size.height - 8,
      1,
      8,
    );
    setState(() => _pressedId = comment.id);
    TextStyle item(Color color) =>
        AppTextStyles.body.copyWith(fontSize: 16, color: color);
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(anchor, Offset.zero & overlay.size),
      color: palette.surface,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      items: [
        PopupMenuItem(
          value: 'reply',
          child: Text(l10n.capsulesReply, style: item(palette.textPrimary)),
        ),
        PopupMenuItem(
          value: 'copy',
          child: Text(l10n.capsulesCopyText, style: item(palette.textPrimary)),
        ),
        if (canDelete)
          PopupMenuItem(
            value: 'delete',
            child: Text(
              l10n.capsulesCommentDelete,
              style: item(AppColors.danger),
            ),
          )
        else
          PopupMenuItem(
            value: 'report',
            child: Text(l10n.capsulesReport, style: item(AppColors.danger)),
          ),
      ],
    );
    if (!mounted) return;
    setState(() => _pressedId = null);
    switch (choice) {
      case 'reply':
        _startReply(comment);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: comment.text));
        if (mounted) {
          PopupNotificationService.showSuccess(
            context: context,
            message: l10n.capsulesCopied,
            position: NotificationPosition.top,
          );
        }
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
    final owner = CapsuleAuthorRow.ownerNameOf(context, _c.capsule);

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
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSheets.radius),
          ),
        ),
        child: Column(
          children: [
            const SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Row(
                children: [
                  Text(
                    l10n.capsulesComments,
                    style: TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  ListenableBuilder(
                    listenable: _c,
                    builder: (context, _) => _c.commentCount == 0
                        ? const SizedBox.shrink()
                        : Text(
                            '  ${_c.commentCount}',
                            style: TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: palette.textMuted,
                            ),
                          ),
                  ),
                ],
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
                      subtitle: owner == null
                          ? l10n.capsulesCommentsEmptyHint
                          : l10n.capsulesCommentsEmptyHintFor(owner),
                      assetPath: AppIcons.messagesNew,
                    );
                  }
                  // The first row offers older comments when there are.
                  final more = _c.canLoadMoreComments ? 1 : 0;
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    itemCount: thread.length + more,
                    itemBuilder: (context, index) {
                      if (index < more) {
                        return Center(
                          child: _c.isLoadingMoreComments
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : TextButton(
                                  onPressed: _c.loadMoreComments,
                                  child: Text(l10n.capsulesCommentsEarlier),
                                ),
                        );
                      }
                      final comment = thread[index - more];
                      return Builder(
                        key: ValueKey(comment.id),
                        builder: (row) => _CommentRow(
                          comment: comment,
                          isMine: comment.authorId == _c.uid,
                          isAuthor: comment.authorId == _c.capsule.ownerId,
                          pressed: comment.id == _pressedId,
                          onReply: comment.replyTo == null
                              ? () => _startReply(comment)
                              : null,
                          onLongPress: () => _options(comment, row),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: palette.divider)),
              ),
              child: const SizedBox(width: double.infinity),
            ),
            if (replyName != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: _ReplyingChip(
                    name: replyName,
                    onClose: () => setState(() => _replyTo = null),
                  ),
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
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(6),
                            child: UserRoundAvatar(userId: _c.uid, radius: 14),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
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

/// "Replying to Erin ×" above the comment field.
class _ReplyingChip extends StatelessWidget {
  const _ReplyingChip({required this.name, required this.onClose});

  final String name;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadii.lCircular,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              l10n.capsulesReplyingTo(name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: palette.textSecondary,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.commonCancel,
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: Image.asset(AppIcons.capsuleClose, width: 14),
          ),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.comment,
    required this.isMine,
    required this.isAuthor,
    required this.pressed,
    required this.onReply,
    required this.onLongPress,
  });

  final CapsuleComment comment;
  final bool isMine;

  /// Written by whoever left the capsule: an Author chip by the name.
  final bool isAuthor;

  /// Its menu is open: tinted soft green.
  final bool pressed;

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
    final reply = comment.replyTo != null;
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserRoundAvatar(userId: comment.authorId, radius: reply ? 13 : 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  if (isAuthor)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: palette.accentSoft,
                        borderRadius: AppRadii.lCircular,
                      ),
                      child: Text(
                        l10n.capsulesAuthorChip,
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: palette.accentText,
                        ),
                      ),
                    ),
                  if (at != null)
                    Text(
                      NotificationTexts.time(at, DateTime.now(), l10n: l10n),
                      style: TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 12,
                        color: palette.textMuted,
                      ),
                    ),
                ],
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
              if (onReply != null && !isMine)
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
                        color: palette.accentText,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    return Material(
      color: pressed ? palette.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          // A reply hangs on a thread line under its comment's picture.
          child: reply
              ? Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Container(
                    padding: const EdgeInsets.only(left: 22),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: palette.divider, width: 2),
                      ),
                    ),
                    child: content,
                  ),
                )
              : content,
        ),
      ),
    );
  }
}
