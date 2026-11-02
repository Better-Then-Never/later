import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/session/session_controller.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/app_image_cache.dart';
import '../../../data/services/profile_image_cache.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../../../shared/widgets/pill_v2.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../../shared/widgets/user/profile_stamp.dart';
import '../profile_image_editor.dart';
import '../widgets/edit_profile_image.dart';
import 'any_colour_sheet.dart';

/// "Your stamp" (Figma page 13, Round 5 `7179:4229`): the shape and the
/// colour of your photo's stamp, and a way to change the photo itself.
/// Saves when closed with Done.
class StampSheet extends StatefulWidget {
  const StampSheet({super.key, required this.initial});

  final ProfileStampStyle initial;

  static String shapeName(BuildContext context, StampShape s) {
    final l = context.l10n;
    return switch (s) {
      StampShape.classic => l.stampShapeClassic,
      StampShape.rounded => l.stampShapeRounded,
      StampShape.round => l.stampShapeRound,
      StampShape.soft => l.stampShapeSoft,
      StampShape.ticket => l.stampShapeTicket,
      StampShape.polaroid => l.stampShapePolaroid,
    };
  }

  static String colourName(BuildContext context, StampColor c) {
    final l = context.l10n;
    if (c.isCustom) return c.value;
    return switch (c.value) {
      'paper' => l.stampColourPaper,
      'green' => l.stampColourGreen,
      'yellow' => l.stampColourYellow,
      'orange' => l.stampColourOrange,
      'red' => l.stampColourRed,
      'blue' => l.stampColourBlue,
      'forest' => l.stampColourForest,
      'black' => l.stampColourBlack,
      _ => l.stampColourWhite,
    };
  }

  /// Opens the sheet for the signed-in user and saves what they choose.
  static Future<void> show(BuildContext context) async {
    final session = context.read<SessionController>();
    final uid = session.uid;
    if (uid == null) return;
    final users = context.read<UserRepository>();
    final initial = session.profile?.stamp ?? const ProfileStampStyle();
    final result = await showEdgeSheet<_StampResult>(
      context,
      (_) => StampSheet(initial: initial),
    );
    if (result == null || !context.mounted) return;
    if (result.changePhoto) {
      final editor = ProfileImageEditor(
        uid: uid,
        kind: ProfileImageKind.profile,
        images: context.read<ImageStorageRepository>(),
        cache: context.read<ProfileImageCache>(),
      );
      final l10n = context.l10n;
      await editProfileImage(
        context,
        editor,
        title: l10n.profilePictureTitle,
        deleteLabel: l10n.profilePictureDelete,
        successMessage: l10n.profilePictureUpdated,
      );
      editor.dispose();
      return;
    }
    final style = result.style;
    if (style == null || style == initial) return;
    try {
      await users.setStamp(uid, style);
    } catch (e) {
      AppLogger.warning('Stamp not saved', error: e);
      if (context.mounted) {
        PopupNotificationService.showError(
          context: context,
          message: context.l10n.stampSaveFailed,
          duration: const Duration(seconds: 3),
          position: NotificationPosition.top,
        );
      }
    }
  }

  @override
  State<StampSheet> createState() => _StampSheetState();
}

typedef _StampResult = ({ProfileStampStyle? style, bool changePhoto});

class _StampSheetState extends State<StampSheet> {
  late ProfileStampStyle _style = widget.initial;

  Future<void> _anyColour() async {
    final argb = await AnyColourSheet.show(
      context,
      initial: _style.color.argb,
      shape: _style.shape,
    );
    if (argb != null && mounted) {
      setState(() => _style = _style.copyWith(color: StampColor.custom(argb)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final uid = context.read<SessionController>().uid;
    final url = uid == null
        ? null
        : context.select<ProfileImageCache, String?>(
            (c) => c.url(uid, ProfileImageKind.profile),
          );
    final photo = url == null ? null : AppImageCache.provider(url, width: 240);
    final initial = context.select<SessionController, String>(
      (s) => s.profile?.initial ?? '',
    );
    final first = context.select<SessionController, String>(
      (s) => (s.profile?.name ?? '').split(' ').first.toLowerCase(),
    );
    final custom = _style.color.isCustom ? _style.color : null;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: SheetHandle.v2()),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.stampTitle,
                          style: AppTextStyles.sectionTitle.copyWith(
                            color: palette.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.stampSubtitle,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 14,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PillV2(
                    label: l10n.stampChangePhoto,
                    kind: PillV2Kind.outline,
                    size: PillV2Size.small,
                    onTap: () => Navigator.pop<_StampResult>(context, (
                      style: null,
                      changePhoto: true,
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.82,
                children: [
                  for (final s in StampShape.values)
                    _ShapeTile(
                      key: ValueKey('stamp-shape-${s.name}'),
                      label: StampSheet.shapeName(context, s),
                      selected: _style.shape == s,
                      onTap: () =>
                          setState(() => _style = _style.copyWith(shape: s)),
                      child: ProfileStamp(
                        style: _style.copyWith(shape: s),
                        size: s == StampShape.polaroid ? 62 : 70,
                        photo: photo,
                        initial: initial,
                        caption: first,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                l10n.stampColour,
                style: AppTextStyles.body.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 8,
                children: [
                  for (final name in StampColor.names)
                    _Swatch(
                      key: ValueKey('stamp-colour-$name'),
                      color: ProfileStamp.paperColor(StampColor.named(name)),
                      label: StampSheet.colourName(
                        context,
                        StampColor.named(name),
                      ),
                      selected: _style.color.value == name,
                      onTap: () => setState(
                        () => _style = _style.copyWith(
                          color: StampColor.named(name),
                        ),
                      ),
                    ),
                  if (custom != null)
                    _Swatch(
                      color: ProfileStamp.paperColor(custom),
                      label: custom.value,
                      selected: true,
                      onTap: _anyColour,
                    ),
                  _Swatch(
                    label: l10n.stampColourAny,
                    selected: false,
                    rainbow: true,
                    onTap: _anyColour,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: PillV2(
                  label: l10n.stampDone,
                  onTap: () => Navigator.pop<_StampResult>(context, (
                    style: _style,
                    changePhoto: false,
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShapeTile extends StatelessWidget {
  const _ShapeTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brandGreen.withValues(alpha: 0.12)
                : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.brandGreen : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              child,
              const SizedBox(height: 8),
              ExcludeSemantics(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: palette.textPrimary,
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

/// A round colour to pick; [rainbow] is "Any colour".
class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.rainbow = false,
  });

  final Color? color;
  final String label;
  final bool selected;
  final bool rainbow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.brandGreen : Colors.transparent,
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              gradient: rainbow ? AnyColourSheet.rainbow(sweep: true) : null,
              border: Border.all(color: palette.divider),
            ),
            child: rainbow
                ? Center(
                    child: Text(
                      '+',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onMedia,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
