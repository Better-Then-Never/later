import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/session/session_controller.dart';
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
import '../../../shared/widgets/pill_v2.dart';
import '../../capsules/opening/capsule_openings.dart';
import '../../capsules/social/capsule_sheet.dart';

/// The card above a tapped pin (capsule v3, Figma "v3 Map / Card open" and
/// "Card locked"): a picture, the title, who left it and, for an open
/// capsule, a check with when it opened and the Open pill; for a locked one,
/// the countdown, how much of the wait is done, the day it opens and a soft
/// Locked pill. A locked capsule shows its pin, never its photo. The photo
/// flies into the opened capsule as a [Hero].
class CapsuleInfoPanel extends StatefulWidget {
  const CapsuleInfoPanel({
    super.key,
    required this.capsule,
    required this.onMoreInfo,
  });

  final Capsule capsule;
  final VoidCallback onMoreInfo;

  /// The locked card's height at the normal text size: its five short lines
  /// with the padding and the dark theme's border (the tallest card).
  static const double minHeight = 108;

  /// The open card's height at the normal text size: the 76 dp picture with
  /// the padding.
  static const double openHeight = 96;

  /// The card's height on this screen for [capsule] (the locked height when
  /// unknown), grown with the system text size, at most 220. Measured at the
  /// card's small text: Android 14+ scales large text less than small text
  /// (nonlinear).
  static double heightFor(BuildContext context, {Capsule? capsule}) {
    final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
    final open = capsule != null && capsule.isOpen(DateTime.now());
    // The text column at the normal size, and the card's padding.
    final column = open ? 62.0 : 88.0;
    return math
        .max(open ? openHeight : minHeight, column * scale + 20)
        .clamp(0.0, 220.0);
  }

  /// Compact countdown in the app's language, as the locked card shows it:
  /// days and hours ("41d 6h") while a day or more is left, then hours and
  /// minutes; seconds only in the last minute (M-10).
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
      if (days == 0) l10n.mapDurationMinutes(minutes),
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
    return l10n.mapCapsuleOpenedOn(
      AppDates.compact(opened, l10n.localeName, now),
    );
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
    final uid = context.select<SessionController, String?>((s) => s.uid);
    // Not unwrapped yet (D1): it waits for its first open.
    final wrapped =
        isOpen &&
        context.select<CapsuleOpenings, bool>(
          (o) => o.isWrapped(capsule, uid, _now),
        );
    final left = AppDates.compact(
      capsule.createdAt ?? _now,
      l10n.localeName,
      _now,
    );
    final String second;
    if (isOpen) {
      second =
          CapsuleAuthorRow.namesOf(context, capsule) ??
          l10n.mapCapsuleLeftOn(left);
    } else {
      // The first name, so the date still fits ("Left by Bob · 6 Oct").
      final owner = CapsuleAuthorRow.ownerFirstNameOf(context, capsule);
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
        boxShadow: AppShadows.raised(context),
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
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: isOpen ? 2 : 3),
                  _SecondLine(
                    second,
                    date: left,
                    style: _line(palette.textSecondary),
                  ),
                  SizedBox(height: isOpen ? 2 : 3),
                  if (isOpen)
                    Row(
                      // The check stays by the first line when it wraps.
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Image.asset(AppIcons.profileDone, width: 14),
                        ),
                        const SizedBox(width: 4),
                        // Two lines when it must: the open card has room.
                        Flexible(
                          child: Text(
                            wrapped
                                ? l10n.mapCapsuleYoursToOpen
                                : CapsuleInfoPanel.openedLabel(
                                    capsule,
                                    _now,
                                    l10n,
                                  ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _line(palette.accentText, bold: true),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Row(
                      children: [
                        Image.asset(AppIcons.capsuleTimer, width: 16),
                        const SizedBox(width: 5),
                        Flexible(
                          child: _Fit(
                            l10n.mapCapsuleOpensIn(
                              CapsuleInfoPanel.formatDuration(
                                capsule.timeUntilOpen(_now),
                                l10n,
                              ),
                            ),
                            style: _line(palette.textPrimary, bold: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    _WaitLine(done: CapsuleInfoPanel.waitDone(capsule, _now)),
                    if (capsule.openAt != null) ...[
                      const SizedBox(height: 3),
                      _Fit(
                        l10n.mapCapsuleOpensOn(
                          AppDates.compact(
                            capsule.openAt!,
                            l10n.localeName,
                            _now,
                          ),
                        ),
                        style: _line(palette.textMuted, size: 12),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isOpen)
              PillV2(label: l10n.mapCapsuleOpen, onTap: widget.onMoreInfo)
            else
              PillV2(
                label: l10n.mapCapsuleLocked,
                kind: PillV2Kind.soft,
                size: PillV2Size.small,
              ),
          ],
        ),
      ),
    );
  }

  static TextStyle _line(Color color, {bool bold = false, double size = 13}) =>
      TextStyle(
        fontFamily: kAppFontFamily,
        fontSize: size,
        height: 1.25,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: color,
      );
}

/// Who left it and when. A line a little too long shrinks a little (up to
/// [_shrink]); a longer one lets the name give way ("Left by Jonathan… ·
/// 21 Dec 2025") so the date at the end stays whole.
class _SecondLine extends StatelessWidget {
  const _SecondLine(this.text, {required this.date, required this.style});

  final String text;

  /// The date the line ends with, if it does.
  final String date;
  final TextStyle style;

  /// The most the line may shrink before the name gives way.
  static const _shrink = 0.88;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width = (TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout()).width;
      if (width <= box.maxWidth) {
        return Text(text, maxLines: 1, style: style);
      }
      if (width * _shrink <= box.maxWidth) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(text, maxLines: 1, style: style),
        );
      }
      return _split();
    },
  );

  Widget _split() {
    if (!text.endsWith(date) || text == date) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return Row(
      children: [
        Flexible(
          child: Text(
            text.substring(0, text.length - date.length),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        Text(date, maxLines: 1, style: style),
      ],
    );
  }
}

/// A line that must be read whole (a countdown, a date): it shrinks a
/// little rather than lose its end when a language runs long.
class _Fit extends StatelessWidget {
  const _Fit(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text(text, maxLines: 1, style: style),
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
        backgroundColor: context.palette.pill,
        color: AppColors.brandGreen,
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
        // Straight from square to square (the default arc bends it).
        createRectTween: (begin, end) => RectTween(begin: begin, end: end),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
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
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Image.asset(
        AppIcons.mapPin(capsule.color.name),
        width: size * 48 / 76,
      ),
    );
  }
}
