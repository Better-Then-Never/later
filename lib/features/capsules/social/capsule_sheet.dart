import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/session/session_controller.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/l10n/app_dates.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../data/models/social.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/widgets/anchored_menu.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../../../shared/widgets/capsule/capsule_author_row.dart';
import '../../../shared/widgets/capsule/capsule_place_chip.dart';
import '../../../shared/widgets/capsule/cropped_photo.dart';
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

/// An opened capsule (capsule v3, Figma "v3 Capsule / Opened"): a sheet over
/// the map, as tall as what it shows, with the photo first (a square; a tap
/// shows it whole; share and ⋯ on its corner), the title and its place (a
/// tap: the map), who left it, when it was left and opened, the words, the
/// six reactions across the width and the newest comment; under them the
/// comments and a reply to the author as pills with words. [controller] is
/// null when there is nothing social to show.
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
    return SheetSurface(
      color: palette.surface,
      radius: radius,
      // As tall as its content (it scrolls when that is taller than the
      // screen allows); the pills stay at the bottom.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle.v2(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CapsuleSheetPhoto(
                    capsule: capsule,
                    actions: _PhotoActions(
                      capsule: capsule,
                      controller: social,
                      onPlaceTap: onPlaceTap,
                    ),
                  ),
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
          _ActionBar(capsule: capsule, controller: social, comments: comments),
        ],
      ),
    );
  }
}

/// The capsule's photo as a square with rounded corners (a loop plays, with
/// a "Loop · N frames" badge); a tap shows the whole photo full screen.
/// Opened from the map card, it grows out of the card's thumbnail
/// ([SheetPicture]).
class CapsuleSheetPhoto extends StatelessWidget {
  const CapsuleSheetPhoto({super.key, required this.capsule, this.actions});

  final Capsule capsule;

  /// Buttons on the top right corner (share, ⋯).
  final Widget? actions;

  /// The decode width of the map card's thumbnail, in pixels. The opened
  /// photo lies on the same picture, straight from memory, so it shows from
  /// the first frame (while the photo itself loads).
  static const thumbDecodeWidth = 384;

  @override
  Widget build(BuildContext context) {
    final url = capsule.imageUrl;
    if (url == null) return const SizedBox.shrink();
    final tag = CapsuleSheet.photoHeroTag(capsule);
    final corner = actions;
    return AspectRatio(
      aspectRatio: 1,
      child: SheetPicture(
        radius: 20,
        over: [
          if (capsule.isLoop)
            Positioned(
              left: 10,
              top: 10,
              child: PhotoBadge(
                text: context.l10n.capsulesLoopBadge(capsule.frames.length),
              ),
            ),
          if (corner != null) Positioned(top: 10, right: 10, child: corner),
        ],
        child: GestureDetector(
          onTap: () => PhotoViewer.show(
            context,
            url,
            frames: capsule.frames,
            frameDelay: Duration(milliseconds: capsule.frameDelayMs),
            heroTag: tag,
            crop: capsule.crop,
          ),
          child: Hero(
            tag: tag,
            // Straight from square to square (the default arc bends it).
            createRectTween: (begin, end) => RectTween(begin: begin, end: end),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(
                  url: capsule.thumbUrl ?? url,
                  cacheWidth: thumbDecodeWidth,
                ),
                if (capsule.isLoop)
                  LoopPicture(
                    sources: capsule.frames,
                    frameDelay: Duration(milliseconds: capsule.frameDelayMs),
                  )
                else
                  CroppedPhoto(
                    crop: capsule.crop,
                    image: (fit) => AppNetworkImage(
                      url: url,
                      fit: fit,
                      // The thumbnail under it until it loads.
                      placeholder: const SizedBox.shrink(),
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

/// Share and ⋯ on the photo's corner: dark round buttons, white signs.
class _PhotoActions extends StatelessWidget {
  const _PhotoActions({
    required this.capsule,
    required this.controller,
    required this.onPlaceTap,
  });

  final Capsule capsule;
  final CapsuleSocialController? controller;
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
    final l10n = context.l10n;
    final link = CapsuleSheet.shareable(capsule);
    // Your own private capsule shares its photo instead of a link (known
    // from who is signed in: it may have no reactions or comments).
    final me = context.read<SessionController>().uid;
    final mine =
        me != null && (capsule.ownerId == me || capsule.coAuthors.contains(me));
    final share = link || mine;
    final choices = _choices;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (share)
          _PhotoButton(
            label: l10n.capsulesShare,
            onTap: () => link
                ? SharingService.shareCapsule(
                    context: context,
                    capsule: capsule,
                  )
                : SharingService.shareCapsulePhoto(
                    context: context,
                    capsule: capsule,
                  ),
            child: Image.asset(AppIcons.shareWhite, width: 20),
          ),
        if (share && choices.isNotEmpty) const SizedBox(width: 8),
        if (choices.isNotEmpty)
          Builder(
            builder: (button) => _PhotoButton(
              label: l10n.capsulesMore,
              onTap: () => _menu(button, choices),
              child: const Icon(
                Icons.more_horiz,
                size: 22,
                color: AppColors.onMedia,
              ),
            ),
          ),
      ],
    );
  }

  /// A small menu under the ⋯ button: show on the map, leave as co-author,
  /// report (Figma "v3b Capsule / More menu").
  Future<void> _menu(BuildContext button, List<_MenuChoice> choices) async {
    final l10n = button.l10n;
    final choice = await showAnchoredMenu<_MenuChoice>(
      button,
      width: 228,
      alignEnd: true,
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
    if (choice == null || !button.mounted) return;
    switch (choice) {
      case _MenuChoice.showOnMap:
        onPlaceTap?.call();
      case _MenuChoice.leave:
        await leaveCapsule(button, capsule.id);
      case _MenuChoice.report:
        await reportFlow(
          button,
          controller!,
          target: ReportTarget.capsule,
          targetPath: 'capsules/${capsule.id}',
        );
    }
  }
}

/// A 36 dp dark round button on the photo (no hold-to-see label).
class _PhotoButton extends StatelessWidget {
  const _PhotoButton({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: AppPressable(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.mediaScrim,
            shape: BoxShape.circle,
          ),
          child: ExcludeSemantics(child: child),
        ),
      ),
    ),
  );
}

/// At the bottom: the comments (soft) and a reply to the author (outlined)
/// as pills with words, sharing the width so the name fits.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.capsule,
    required this.controller,
    required this.comments,
  });

  final Capsule capsule;
  final CapsuleSocialController? controller;
  final bool comments;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final social = controller;
    final reply = social != null && !social.isOwner;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    if (!comments && !reply) return SizedBox(height: 8 + bottom);
    final author = reply
        ? CapsuleAuthorRow.ownerFirstNameOf(context, capsule)
        : null;
    final commentsPill = comments
        ? ListenableBuilder(
            listenable: social!,
            builder: (context, _) => PillV2(
              label: l10n.capsulesCommentsPill(social.commentCount),
              kind: PillV2Kind.soft,
              onTap: () => CapsuleCommentsSheet.show(context, social),
            ),
          )
        : null;
    final replyPill = reply
        ? PillV2(
            label: author == null
                ? l10n.capsulesQuickReply
                : l10n.capsulesReplyTo(author),
            kind: PillV2Kind.outline,
            onTap: () => QuickReplyCard.show(context, capsule),
          )
        : null;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottom),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.divider)),
      ),
      child: Row(
        children: [
          if (commentsPill != null) Expanded(child: commentsPill),
          if (commentsPill != null && replyPill != null)
            const SizedBox(width: 8),
          if (replyPill != null) Expanded(child: replyPill),
        ],
      ),
    );
  }
}
