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
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/widgets/anchored_menu.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../../../shared/widgets/capsule/capsule_author_row.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../../shared/widgets/user/user_round_avatar.dart';
import '../../notifications/notification_texts.dart';
import '../../users/user_directory.dart';
import 'capsule_social_controller.dart';
import 'capsule_social_panel.dart';

/// The comments of a capsule (capsule v3, Figma "v3b Capsule / Comments"):
/// one level of replies on a thread line, newest at the bottom, the author's
/// comments marked, a composer under the list. Long press a comment for a
/// small menu by it: reply, copy, and delete (author or capsule owner) or
/// report.
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

  /// The small menu by a long-pressed comment ([row] is its context; Figma
  /// "Comment menu"): reply, copy, then delete (yours, or any on your
  /// capsule) or report.
  Future<void> _options(CapsuleComment comment, BuildContext row) async {
    final l10n = context.l10n;
    final canDelete = _c.canDelete(comment);
    setState(() => _pressedId = comment.id);
    final choice = await showAnchoredMenu<String>(
      row,
      width: 200,
      offset: const Offset(120, 40),
      items: [
        AnchoredMenuItem(value: 'reply', label: l10n.capsulesReply),
        AnchoredMenuItem(value: 'copy', label: l10n.capsulesCopyText),
        if (canDelete)
          AnchoredMenuItem(
            value: 'delete',
            label: l10n.capsulesCommentDelete,
            danger: true,
          )
        else
          AnchoredMenuItem(
            value: 'report',
            label: l10n.capsulesReport,
            danger: true,
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
    final owner = CapsuleAuthorRow.ownerFirstNameOf(context, _c.capsule);
    final title = TextStyle(
      fontFamily: kAppFontFamily,
      fontSize: 18,
      height: 1.2,
      fontWeight: FontWeight.bold,
      color: palette.textPrimary,
    );

    // 650 of 800 dp in the design. The sheet stays put while the keyboard
    // opens: the composer rides on the keyboard and the list gets shorter
    // (the whole sheet jumping up to the top looked broken). Only a keyboard
    // that would leave the list too little room lifts the sheet, never under
    // the status bar.
    final keyboard = media.viewInsets.bottom;
    final ceiling = media.size.height - media.viewPadding.top - 12;
    final height = math.min(
      ceiling,
      math.max(media.size.height * 650 / 800, keyboard + 260),
    );
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        // One gap that follows the keyboard down to the system bar and
        // stops there (it dropped under the bar, then jumped back).
        padding: EdgeInsets.only(
          bottom: math.max(keyboard, media.viewPadding.bottom),
        ),
        child: Column(
          children: [
            const SheetHandle.v2(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  Text(l10n.capsulesComments, style: title),
                  ListenableBuilder(
                    listenable: _c,
                    builder: (context, _) => _c.commentCount == 0
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              '${_c.commentCount}',
                              style: title.copyWith(color: palette.textMuted),
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
                    return _Empty(
                      hint: owner == null
                          ? l10n.capsulesCommentsEmptyHint
                          : l10n.capsulesCommentsEmptyHintFor(owner),
                    );
                  }
                  // The first row offers older comments when there are.
                  final more = _c.canLoadMoreComments ? 1 : 0;
                  return SheetList(
                    list: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 12),
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
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border(top: BorderSide(color: palette.divider)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (replyName != null) ...[
                    _ReplyingChip(
                      name: replyName,
                      onClose: () => setState(() => _replyTo = null),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: _field(context)),
                      const SizedBox(width: 8),
                      SendCircle(
                        tooltip: l10n.messagesSend,
                        onTap: _sending ? null : _send,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The grey field with the user's picture inside.
  Widget _field(BuildContext context) {
    final palette = context.palette;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.fromLTRB(6, 0, 14, 0),
      decoration: BoxDecoration(
        color: palette.pill,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          UserRoundAvatar(userId: _c.uid, radius: 16),
          const SizedBox(width: 8),
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
                fontSize: 16,
                height: 1.25,
                color: palette.textPrimary,
              ),
              decoration: InputDecoration(
                counterText: '',
                isDense: true,
                hintText: context.l10n.capsulesCommentHint,
                hintStyle: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 16,
                  height: 1.25,
                  color: palette.textMuted,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
        ],
      ),
    );
  }
}

/// The 44 dp green send button with the white arrow (Figma "Send").
class SendCircle extends StatelessWidget {
  const SendCircle({super.key, required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: tooltip,
    child: AppPressable(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.brandGreen,
            shape: BoxShape.circle,
          ),
          // The camera's white back arrow, turned to point ahead.
          child: RotatedBox(
            quarterTurns: 2,
            child: Image.asset(AppIcons.cameraBack, width: 22),
          ),
        ),
      ),
    ),
  );
}

/// No comments yet: the "write" drawing, the words, who will read them.
class _Empty extends StatelessWidget {
  const _Empty({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    return Align(
      alignment: const Alignment(0, -0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AppIcons.profileWriteNewMessage, width: 64),
            const SizedBox(height: 6),
            Text(
              l10n.capsulesCommentsEmpty,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle.copyWith(
                color: palette.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 13,
                height: 1.25,
                color: palette.textSecondary,
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
    return Semantics(
      button: true,
      label: '${l10n.capsulesReplyingTo(name)}, ${l10n.commonCancel}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: ExcludeSemantics(
          child: Container(
            height: 32,
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: palette.pill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    l10n.capsulesReplyingTo(name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 13,
                      height: 1.25,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                // The app's own cross, with room around it for a thumb.
                SizedBox(
                  width: 36,
                  height: 32,
                  child: Center(
                    child: Image.asset(AppIcons.capsuleClose, width: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    TextStyle small(Color color, {bool bold = false, double size = 13}) =>
        TextStyle(
          fontFamily: kAppFontFamily,
          fontSize: size,
          height: 1.25,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color,
        );
    final row = Padding(
      padding: EdgeInsets.fromLTRB(reply ? 58 : 16, 8, 16, 8),
      child: Row(
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
                    Text(name, style: small(palette.textPrimary, bold: true)),
                    if (isAuthor)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: palette.accentSoft,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          l10n.capsulesAuthorChip,
                          style: small(
                            palette.accentText,
                            bold: true,
                            size: 12,
                          ).copyWith(height: 1),
                        ),
                      ),
                    if (at != null)
                      Text(
                        NotificationTexts.time(at, DateTime.now(), l10n: l10n),
                        style: small(palette.textMuted, size: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.text,
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 14,
                    height: 1.3,
                    color: palette.textPrimary,
                  ),
                ),
                if (onReply != null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onReply,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        l10n.capsulesReply,
                        style: small(palette.accentText, bold: true),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    return Material(
      color: pressed ? palette.accentSoft : Colors.transparent,
      child: InkWell(
        onLongPress: onLongPress,
        // A reply hangs on a thread line under its comment's picture.
        child: reply
            ? Stack(
                children: [
                  Positioned(
                    left: 31,
                    top: 0,
                    bottom: 8,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: palette.divider,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                  row,
                ],
              )
            : row,
      ),
    );
  }
}
