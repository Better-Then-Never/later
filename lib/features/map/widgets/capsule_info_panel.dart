import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/app_dates.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/capsule/capsule_author_row.dart';
import '../../../shared/widgets/loop_mark.dart';
import '../../capsules/social/capsule_sheet.dart';

/// The card above a tapped pin (capsule v3): a picture, the title, who left
/// it and, for an open capsule, when it opened with a normal-size Open pill;
/// for a locked one, the countdown in ink, how much of the wait is done, the
/// day it opens and a quiet Locked pill. A locked capsule shows its pin, never
/// its photo. The photo flies into the opened capsule as a [Hero].
class CapsuleInfoPanel extends StatefulWidget {
  const CapsuleInfoPanel({
    super.key,
    required this.capsule,
    required this.onMoreInfo,
  });

  final Capsule capsule;
  final VoidCallback onMoreInfo;

  /// The card's height at the normal text size: the 76 dp picture, or the
  /// four short lines of a locked capsule, with the padding.
  static const double minHeight = 124;

  /// The card's height on this screen: [minHeight] grown with the system
  /// text size, at most 200. Measured at the card's small text: Android 14+
  /// scales large text less than small text (nonlinear).
  static double heightFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
    return (minHeight * scale).clamp(minHeight, 200);
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

  /// How much of the wait is done: 0 the day it was left, 1 when it opens.
  static double waitDone(Capsule capsule, DateTime now) {
    final start = capsule.createdAt;
    final end = capsule.openAt;
    if (start == null || end == null || !end.isAfter(start)) return 1;
    final total = end.difference(start).inSeconds;
    return (now.difference(start).inSeconds / total).clamp(0.0, 1.0);
  }

  /// When an open capsule opened, in words: today, yesterday or the day;
  /// "Open anytime" for one without a date.
  static String openedLabel(
    Capsule capsule,
    DateTime now,
    AppLocalizations l10n,
  ) {
    final opened = capsule.openAt;
    if (opened == null) return l10n.mapCapsuleOpenAnytime;
    final days = DateUtils.dateOnly(
      now,
    ).difference(DateUtils.dateOnly(opened)).inDays;
    if (days <= 0) return l10n.mapCapsuleOpenedToday;
    if (days == 1) return l10n.mapCapsuleOpenedYesterday;
    return l10n.mapCapsuleOpenedOn(AppDates.medium(opened, l10n.localeName));
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
    final palette = context.palette;
    final left = AppDates.medium(capsule.createdAt ?? _now, l10n.localeName);
    final String second;
    if (isOpen) {
      second =
          CapsuleAuthorRow.namesOf(context, capsule) ??
          l10n.mapCapsuleLeftOn(left);
    } else {
      final owner = CapsuleAuthorRow.ownerNameOf(context, capsule);
      second = owner == null
          ? l10n.mapCapsuleLeftOn(left)
          : l10n.mapCapsuleLeftBy(owner, left);
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: palette.isDark ? Border.all(color: palette.cardBorder) : null,
        boxShadow: AppShadows.mapInfo(context),
      ),
      child: LayoutBuilder(
        builder: (context, box) => Row(
          children: [
            _Thumbnail(
              capsule: capsule,
              isOpen: isOpen,
              size: math.min(76, box.hasBoundedHeight ? box.maxHeight : 76),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    capsule.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    second,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _line(palette.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  if (isOpen)
                    Text(
                      CapsuleInfoPanel.openedLabel(capsule, _now, l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _line(palette.accentText, bold: true),
                    )
                  else ...[
                    Row(
                      children: [
                        Image.asset(AppIcons.capsuleTimer, width: 15),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            l10n.mapCapsuleOpensIn(
                              CapsuleInfoPanel.formatDuration(
                                capsule.timeUntilOpen(_now),
                                l10n,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _line(palette.textPrimary, bold: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    _WaitLine(done: CapsuleInfoPanel.waitDone(capsule, _now)),
                    if (capsule.openAt != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        l10n.mapCapsuleOpensOn(
                          AppDates.medium(capsule.openAt!, l10n.localeName),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _line(palette.textMuted, size: 12),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (isOpen)
              _OpenPill(onTap: widget.onMoreInfo)
            else
              const _LockedPill(),
          ],
        ),
      ),
    );
  }

  static TextStyle _line(Color color, {bool bold = false, double size = 13}) =>
      TextStyle(
        fontFamily: kAppFontFamily,
        fontSize: size,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: color,
      );
}

/// How much of a locked capsule's wait is done, as a thin green line.
class _WaitLine extends StatelessWidget {
  const _WaitLine({required this.done});

  final double done;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(2),
    child: SizedBox(
      height: 4,
      child: LinearProgressIndicator(
        value: done,
        backgroundColor: context.palette.surfaceMuted,
        color: AppColors.brandGreen,
      ),
    ),
  );
}

/// The open capsule's way in: a normal-size green pill (it was a full-width
/// button).
class _OpenPill extends StatelessWidget {
  const _OpenPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.brandGreen,
      foregroundColor: AppColors.onAccent,
      elevation: 0,
      shape: const StadiumBorder(),
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
    ),
    onPressed: onTap,
    child: Text(
      context.l10n.mapCapsuleOpen,
      style: const TextStyle(
        fontFamily: kAppFontFamily,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/// A locked capsule's state: a quiet pill, not a disabled button.
class _LockedPill extends StatelessWidget {
  const _LockedPill();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: context.palette.accentSoft,
      borderRadius: AppRadii.lCircular,
    ),
    child: Text(
      context.l10n.mapCapsuleLocked,
      style: TextStyle(
        fontFamily: kAppFontFamily,
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: context.palette.accentText,
      ),
    ),
  );
}

/// The card's picture: the photo of an open capsule (the [Hero] the opened
/// capsule's photo flies from), or the capsule's pin on a muted tile while it
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
        tag: CapsuleSheet.photoHeroTag(capsule),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.s),
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
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.s),
      ),
      child: Image.asset(AppIcons.mapPin(capsule.color.name)),
    );
  }
}
