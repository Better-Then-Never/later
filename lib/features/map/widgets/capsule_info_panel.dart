import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../core/l10n/app_dates.dart';
import '../../../core/assets/app_assets.dart';
import '../../../shared/widgets/app_network_image.dart';
import 'capsule_preview_card.dart';
import '../../../shared/widgets/loop_mark.dart';

/// Small window above a marker: the capsule's photo (once it is open; its
/// pin while locked, so nothing is given away), title, creation date,
/// countdown or "Check out what's inside!", and the Open/Locked button.
/// The photo flies into the capsule dialog as a [Hero].
class CapsuleInfoPanel extends StatefulWidget {
  const CapsuleInfoPanel({
    super.key,
    required this.capsule,
    required this.onMoreInfo,
  });

  final Capsule capsule;
  final VoidCallback onMoreInfo;

  /// Smallest height that fits the content (title, date, status, button)
  /// with the app font; the original fixed 17.1% of the screen overflowed on
  /// most phones, and 152 still did by 2 px.
  static const double minHeight = 156;

  /// The card's height on this screen: a share of the screen between
  /// [minHeight] and 220, both grown with the system text size (at 130 %
  /// the button was cut off).
  static double heightFor(BuildContext context) {
    // Measured at the card's body size: Android 14+ scales large text
    // less than small text (nonlinear), so a big reference would say 1.0.
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final screen = MediaQuery.sizeOf(context).height;
    return (screen * 0.171).clamp(minHeight * scale, 220 * scale);
  }

  /// Compact countdown ("2d 5h 30m" in English) in the app's language:
  /// seconds only in the last minute (M-10).
  static String formatDuration(Duration d, AppLocalizations l10n) {
    if (d.isNegative) return '';
    if (d < const Duration(minutes: 1)) {
      return l10n.mapDurationSeconds(d.inSeconds);
    }
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);
    return [
      if (days > 0) l10n.mapDurationDays(days),
      if (hours > 0 || days > 0) l10n.mapDurationHours(hours),
      l10n.mapDurationMinutes(minutes),
    ].join(' ');
  }

  @override
  State<CapsuleInfoPanel> createState() => _CapsuleInfoPanelState();
}

class _CapsuleInfoPanelState extends State<CapsuleInfoPanel> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  bool get _isOpen => widget.capsule.isOpen(_now);

  @override
  void initState() {
    super.initState();
    _startTimerIfLocked();
  }

  @override
  void didUpdateWidget(CapsuleInfoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.capsule.openAt != widget.capsule.openAt) {
      _now = DateTime.now();
      _startTimerIfLocked();
    }
  }

  void _startTimerIfLocked() {
    _timer?.cancel();
    if (_isOpen) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      // Stop ticking once the capsule has opened.
      if (_isOpen) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final capsule = widget.capsule;
    final isOpen = _isOpen;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: AppRadii.lCircular,
        boxShadow: AppShadows.mapInfo(context),
      ),
      // The picture takes at most 30 % of the card's width and never more
      // than its height.
      child: LayoutBuilder(
        builder: (context, box) => Row(
          children: [
            _Thumbnail(
              capsule: capsule,
              isOpen: isOpen,
              size: [
                box.maxWidth * 0.3,
                if (box.hasBoundedHeight) box.maxHeight,
              ].reduce((a, b) => a < b ? a : b),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    capsule.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.dialogTitle,
                  ),
                  Text(
                    AppDates.short(
                      capsule.createdAt ?? DateTime.now(),
                      l10n.localeName,
                    ),
                    style: const TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Scales down instead of cutting off the countdown when a language
                  // needs more room.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isOpen
                          ? l10n.mapCapsuleReady
                          : l10n.mapCapsuleOpensIn(
                              CapsuleInfoPanel.formatDuration(
                                capsule.timeUntilOpen(_now),
                                l10n,
                              ),
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isOpen
                            ? AppColors.brandGreen
                            : AppColors.materialRed,
                        fontFamily: kAppFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandGreen,
                        // Locked: the grey of the design, not Flutter's pale
                        // disabled colour (the white label was unreadable on it).
                        disabledBackgroundColor: context.palette.iconMuted,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.lCircular,
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                      ),
                      onPressed: isOpen ? widget.onMoreInfo : null,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isOpen ? l10n.mapCapsuleOpen : l10n.mapCapsuleLocked,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: kAppFontFamily,
                            color: AppColors.onAccent,
                          ),
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

/// The card's picture: the photo of an open capsule (the [Hero] the capsule
/// dialog's photo flies from), or the capsule's pin on a muted tile while it
/// is locked.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.capsule,
    required this.isOpen,
    required this.size,
  });

  final Capsule capsule;
  final bool isOpen;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = capsule.thumbUrl ?? capsule.imageUrl;
    if (isOpen && url != null) {
      return Hero(
        tag: CapsulePreviewCard.photoHeroTag(capsule),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.m),
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(url: url),
                if (capsule.isLoop)
                  const Positioned(left: 6, bottom: 6, child: LoopMark()),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.24),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.m),
      ),
      child: Image.asset(AppIcons.mapPin(capsule.color.name)),
    );
  }
}
