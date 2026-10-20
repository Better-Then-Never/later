import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/l10n/app_dates.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../data/models/social.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../../../shared/widgets/capsule/capsule_author_row.dart';
import '../../../shared/widgets/capsule/capsule_place_chip.dart';
import '../../../shared/widgets/loop_mark.dart';
import '../../../shared/widgets/loop_picture.dart';
import '../../../shared/widgets/photo_viewer.dart';
import '../../../shared/widgets/user/user_round_avatar.dart';
import '../../profile/share/sharing_service.dart';
import '../../users/user_directory.dart';
import 'capsule_comments_sheet.dart';
import 'capsule_social_controller.dart';
import 'capsule_social_panel.dart';
import 'quick_reply_card.dart';

/// An opened capsule (capsule v3): a sheet over the map with the photo first
/// (a square; a tap shows it whole), the title and its place (a tap: the
/// map), who left it, when it was left and opened, the words, the six
/// reactions and the newest comment; pinned at the bottom, actions with
/// words. [controller] is null when there is nothing social to show.
class CapsuleSheet extends StatelessWidget {
  const CapsuleSheet({
    super.key,
    required this.capsule,
    this.controller,
    this.onPlaceTap,
  });

  final Capsule capsule;
  final CapsuleSocialController? controller;

  /// Closes the sheet's route first, then shows the capsule on the map.
  final VoidCallback? onPlaceTap;

  /// The photo's [Hero] tag (by capsule, not URL: capsules may share one).
  /// Only one widget per route may carry it.
  static Object photoHeroTag(Capsule capsule) => 'capsule-photo:${capsule.id}';

  /// Whether there is anything social to show for [capsule]: reactions or
  /// comments the author allowed, or a way to share it.
  static bool showsAnything(Capsule capsule) =>
      (FeatureFlags.reactions && capsule.allowReactions) ||
      (FeatureFlags.comments && capsule.allowComments) ||
      shareable(capsule);

  /// Capsules that can travel as a link: public and friends-only ones
  /// (whoever opens it still needs to be allowed to see it).
  static bool shareable(Capsule capsule) =>
      capsule.privacy != CapsulePrivacy.private;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final social = controller;
    final reactions =
        social != null && FeatureFlags.reactions && capsule.allowReactions;
    final comments =
        social != null && FeatureFlags.comments && capsule.allowComments;
    final description = capsule.description?.trim() ?? '';
    return Material(
      color: palette.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        // Keeps its place while a quick reply's keyboard is up over it.
        maintainBottomViewPadding: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CapsuleSheetPhoto(capsule: capsule),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            capsule.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CapsulePlaceChip(capsule: capsule, onTap: onPlaceTap),
                      ],
                    ),
                    CapsuleAuthorRow(capsule: capsule),
                    _DatesLine(capsule: capsule),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: AppTextStyles.body.copyWith(
                          color: palette.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (reactions) ...[
                      const SizedBox(height: 14),
                      ListenableBuilder(
                        listenable: social,
                        builder: (context, _) =>
                            CapsuleReactionsBar(controller: social),
                      ),
                    ],
                    if (comments)
                      ListenableBuilder(
                        listenable: social,
                        builder: (context, _) =>
                            _NewestComment(controller: social),
                      ),
                  ],
                ),
              ),
            ),
            _ActionBar(
              capsule: capsule,
              controller: social,
              comments: comments,
              onPlaceTap: onPlaceTap,
            ),
          ],
        ),
      ),
    );
  }
}

/// The capsule's photo as a square (a loop plays); a tap shows the whole
/// photo full screen.
class CapsuleSheetPhoto extends StatelessWidget {
  const CapsuleSheetPhoto({super.key, required this.capsule});

  final Capsule capsule;

  @override
  Widget build(BuildContext context) {
    final url = capsule.imageUrl;
    if (url == null) return const SizedBox.shrink();
    final tag = CapsuleSheet.photoHeroTag(capsule);
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: () => PhotoViewer.show(
          context,
          url,
          frames: capsule.frames,
          frameDelay: Duration(milliseconds: capsule.frameDelayMs),
          heroTag: tag,
        ),
        child: Hero(
          tag: tag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.m),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (capsule.isLoop)
                  LoopPicture(
                    sources: capsule.frames,
                    frameDelay: Duration(milliseconds: capsule.frameDelayMs),
                  )
                else
                  AppNetworkImage(url: url),
                if (capsule.isLoop)
                  const Positioned(left: 10, top: 10, child: LoopMark()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// When it was left and when it opened, because the waiting is the point.
class _DatesLine extends StatelessWidget {
  const _DatesLine({required this.capsule});

  final Capsule capsule;

  @override
  Widget build(BuildContext context) {
    final created = capsule.createdAt;
    if (created == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final opened = capsule.openAt;
    final text = opened != null && opened.isAfter(created)
        ? l10n.capsulesDatesLeftOpened(
            AppDates.medium(created, locale),
            AppDates.medium(opened, locale),
          )
        : l10n.capsulesDatesLeft(AppDates.medium(created, locale));
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Image.asset(AppIcons.capsuleTimer, width: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: context.palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The newest comment as a preview; a tap opens them all.
class _NewestComment extends StatelessWidget {
  const _NewestComment({required this.controller});

  final CapsuleSocialController controller;

  @override
  Widget build(BuildContext context) {
    final comments = controller.comments;
    if (comments.isEmpty) return const SizedBox.shrink();
    final newest = comments.last;
    final palette = context.palette;
    final l10n = context.l10n;
    final mine = newest.authorId == controller.uid;
    final name = mine
        ? l10n.capsulesYou
        : context.select<UserDirectory, String>(
            (d) => d.profile(newest.authorId)?.name ?? '',
          );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => CapsuleCommentsSheet.show(context, controller),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
            child: Row(
              children: [
                UserRoundAvatar(userId: newest.authorId, radius: 14),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (name.isNotEmpty)
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                      Text(
                        newest.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${controller.commentCount} ›',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: palette.accentText,
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

enum _MenuChoice { showOnMap, leave, report }

/// Pinned at the bottom: the comments and a reply to the author as pills
/// with words, then share and ⋯.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.capsule,
    required this.controller,
    required this.comments,
    required this.onPlaceTap,
  });

  final Capsule capsule;
  final CapsuleSocialController? controller;
  final bool comments;
  final VoidCallback? onPlaceTap;

  bool get _owner => controller?.isOwner ?? false;

  bool get _coAuthor =>
      controller != null && capsule.coAuthors.contains(controller!.uid);

  List<_MenuChoice> get _choices => [
    if (onPlaceTap != null && capsule.location != null) _MenuChoice.showOnMap,
    if (_coAuthor) _MenuChoice.leave,
    if (controller != null && !_owner) _MenuChoice.report,
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final social = controller;
    final reply = social != null && !_owner;
    final share = CapsuleSheet.shareable(capsule);
    final choices = _choices;
    if (!comments && !reply && !share && choices.isEmpty) {
      return const SizedBox(height: 8);
    }
    final author = reply
        ? CapsuleAuthorRow.ownerFirstNameOf(context, capsule)
        : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.divider)),
      ),
      child: Row(
        children: [
          // The comments pill keeps its words; the reply pill takes what is
          // left and shortens the name if it must.
          Expanded(
            child: Row(
              children: [
                if (comments)
                  ListenableBuilder(
                    listenable: social!,
                    builder: (context, _) => SheetPill(
                      label: l10n.capsulesCommentsPill(social.commentCount),
                      onTap: () => CapsuleCommentsSheet.show(context, social),
                    ),
                  ),
                if (reply) ...[
                  if (comments) const SizedBox(width: 8),
                  Flexible(
                    child: SheetPill(
                      label: author == null
                          ? l10n.capsulesQuickReply
                          : l10n.capsulesReplyTo(author),
                      outlined: true,
                      onTap: () => QuickReplyCard.show(context, capsule),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (share)
            IconButton(
              tooltip: l10n.capsulesShare,
              visualDensity: VisualDensity.compact,
              onPressed: () => SharingService.shareCapsule(
                context: context,
                capsule: capsule,
              ),
              icon: CustomPaint(
                size: const Size.square(24),
                painter: ShareSignPainter(color: palette.icon),
              ),
            ),
          if (choices.isNotEmpty)
            Builder(
              builder: (buttonContext) => IconButton(
                tooltip: l10n.capsulesMore,
                visualDensity: VisualDensity.compact,
                onPressed: () => _menu(buttonContext, choices),
                icon: CustomPaint(
                  size: const Size.square(24),
                  painter: _MoreSignPainter(color: palette.icon),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// A small menu by the ⋯ button: show on the map, leave as co-author,
  /// report.
  Future<void> _menu(BuildContext context, List<_MenuChoice> choices) async {
    final l10n = context.l10n;
    final palette = context.palette;
    final button = context.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final origin = button.localToGlobal(Offset.zero, ancestor: overlay);
    final choice = await showMenu<_MenuChoice>(
      context: context,
      position: RelativeRect.fromRect(
        origin & button.size,
        Offset.zero & overlay.size,
      ),
      color: palette.surface,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      items: [
        for (final c in choices)
          PopupMenuItem(
            value: c,
            child: Text(
              switch (c) {
                _MenuChoice.showOnMap => l10n.capsulesShowOnMap,
                _MenuChoice.leave => l10n.capsulesLeaveCoAuthors,
                _MenuChoice.report => l10n.capsulesReportCapsule,
              },
              style: AppTextStyles.body.copyWith(
                fontSize: 16,
                color: c == _MenuChoice.report
                    ? AppColors.danger
                    : palette.textPrimary,
              ),
            ),
          ),
      ],
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case _MenuChoice.showOnMap:
        onPlaceTap?.call();
      case _MenuChoice.leave:
        await leaveCapsule(context, capsule.id);
      case _MenuChoice.report:
        await reportFlow(
          context,
          controller!,
          target: ReportTarget.capsule,
          targetPath: 'capsules/${capsule.id}',
        );
    }
  }
}

/// A pill with words at the bottom of a sheet: soft green, or outlined.
class SheetPill extends StatelessWidget {
  const SheetPill({
    super.key,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      child: AppPressable(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: outlined ? null : palette.accentSoft,
              borderRadius: AppRadii.lCircular,
              border: outlined
                  ? Border.all(color: AppColors.brandGreen, width: 1.5)
                  : null,
            ),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: palette.accentText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The ⋯ sign: three dots in the icons' weight.
class _MoreSignPainter extends CustomPainter {
  const _MoreSignPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = color;
    for (final x in [0.2, 0.5, 0.8]) {
      canvas.drawCircle(
        Offset(size.width * x, size.height / 2),
        size.width * 0.09,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(_MoreSignPainter old) => old.color != color;
}
