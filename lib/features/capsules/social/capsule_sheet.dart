import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/l10n/app_dates.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../data/models/social.dart';
import '../../../shared/widgets/anchored_menu.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../../../shared/widgets/capsule/capsule_author_row.dart';
import '../../../shared/widgets/capsule/capsule_place_chip.dart';
import '../../../shared/widgets/loop_picture.dart';
import '../../../shared/widgets/photo_viewer.dart';
import '../../../shared/widgets/pill_v2.dart';
import '../../../shared/widgets/user/user_round_avatar.dart';
import '../../profile/share/sharing_service.dart';
import '../../users/user_directory.dart';
import 'capsule_comments_sheet.dart';
import 'capsule_social_controller.dart';
import 'capsule_social_panel.dart';
import 'quick_reply_card.dart';

/// An opened capsule (capsule v3, Figma "v3 Capsule / Opened"): a tall sheet
/// over the map with the photo first (a square; a tap shows it whole), the
/// title and its place (a tap: the map), who left it, when it was left and
/// opened, the words, the six reactions and the newest comment; pinned at the
/// bottom, the actions with words. [controller] is null when there is
/// nothing social to show.
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

  /// The sheet's top corners.
  static const double radius = 28;

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
    const gap = SizedBox(height: 10);
    return Material(
      color: palette.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(radius)),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        // The sheet stands as tall as the route lets it; the actions stay
        // at the bottom.
        builder: (context, box) => SizedBox(
          height: box.maxHeight.isFinite ? box.maxHeight : null,
          child: Column(
            children: [
              const SheetHandle.v2(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CapsuleSheetPhoto(capsule: capsule),
                      gap,
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              capsule.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: kAppFontFamily,
                                fontSize: 26,
                                height: 1.1,
                                fontWeight: FontWeight.bold,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CapsulePlaceChip(capsule: capsule, onTap: onPlaceTap),
                        ],
                      ),
                      CapsuleAuthorRow(capsule: capsule, top: 10),
                      gap,
                      _DatesLine(capsule: capsule),
                      if (description.isNotEmpty) ...[
                        gap,
                        Text(
                          description,
                          style: AppTextStyles.body.copyWith(
                            color: palette.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ],
                      if (reactions) ...[
                        gap,
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
      ),
    );
  }
}

/// The capsule's photo as a square with rounded corners (a loop plays, with
/// a "Loop · N frames" badge); a tap shows the whole photo full screen.
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
          // Straight from square to square (the default arc bends it).
          createRectTween: (begin, end) => RectTween(begin: begin, end: end),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
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
                  Positioned(
                    left: 10,
                    top: 10,
                    child: PhotoBadge(
                      text: context.l10n.capsulesLoopBadge(
                        capsule.frames.length,
                      ),
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

/// A small dark label on a photo ("Loop · 6 frames", "Retake").
class PhotoBadge extends StatelessWidget {
  const PhotoBadge({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.mediaScrim,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: kAppFontFamily,
        fontSize: 12,
        height: 1,
        fontWeight: FontWeight.bold,
        color: AppColors.onMedia,
      ),
    ),
  );
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
    return Row(
      children: [
        Image.asset(AppIcons.capsuleTimer, width: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 13,
              height: 1.25,
              color: context.palette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// The newest comment as a preview on a grey pill; a tap opens them all.
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
    TextStyle line(Color color, {bool bold = false}) => TextStyle(
      fontFamily: kAppFontFamily,
      fontSize: 13,
      height: 1.25,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: palette.pill,
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
                          style: line(palette.textPrimary, bold: true),
                        ),
                      Text(
                        newest.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: line(palette.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${controller.commentCount} ›',
                  style: line(palette.accentText, bold: true),
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

/// Pinned at the bottom: the comments (soft) and a reply to the author
/// (outlined) as pills with words, then share and ⋯.
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
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    if (!comments && !reply && !share && choices.isEmpty) {
      return SizedBox(height: 8 + bottom);
    }
    final author = reply
        ? CapsuleAuthorRow.ownerFirstNameOf(context, capsule)
        : null;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 8, 10 + bottom),
      decoration: BoxDecoration(
        color: palette.surface,
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
                    builder: (context, _) => PillV2(
                      label: l10n.capsulesCommentsPill(social.commentCount),
                      kind: PillV2Kind.soft,
                      onTap: () => CapsuleCommentsSheet.show(context, social),
                    ),
                  ),
                if (reply) ...[
                  if (comments) const SizedBox(width: 6),
                  Flexible(
                    child: PillV2(
                      label: author == null
                          ? l10n.capsulesQuickReply
                          : l10n.capsulesReplyTo(author),
                      kind: PillV2Kind.outline,
                      onTap: () => QuickReplyCard.show(context, capsule),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (share)
            _IconButton36(
              tooltip: l10n.capsulesShare,
              onTap: () => SharingService.shareCapsule(
                context: context,
                capsule: capsule,
              ),
              child: Image.asset(AppIcons.capsuleSendArrow, width: 22),
            ),
          if (choices.isNotEmpty) ...[
            const SizedBox(width: 6),
            Builder(
              builder: (buttonContext) => _IconButton36(
                tooltip: l10n.capsulesMore,
                onTap: () => _menu(buttonContext, choices),
                child: Icon(Icons.more_horiz, size: 24, color: palette.icon),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// A small menu above the ⋯ button: show on the map, leave as co-author,
  /// report (Figma "v3b Capsule / More menu").
  Future<void> _menu(BuildContext context, List<_MenuChoice> choices) async {
    final l10n = context.l10n;
    final choice = await showAnchoredMenu<_MenuChoice>(
      context,
      width: 228,
      above: true,
      scrim: true,
      items: [
        for (final c in choices)
          AnchoredMenuItem(
            value: c,
            label: switch (c) {
              _MenuChoice.showOnMap => l10n.capsulesShowOnMap,
              _MenuChoice.leave => l10n.capsulesLeaveCoAuthors,
              _MenuChoice.report => l10n.capsulesReportCapsule,
            },
            danger: c == _MenuChoice.report,
            height: 46,
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

/// A 36 dp icon button of the sheet's action bar.
class _IconButton36 extends StatelessWidget {
  const _IconButton36({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Semantics(
      button: true,
      label: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox.square(dimension: 36, child: Center(child: child)),
      ),
    ),
  );
}
