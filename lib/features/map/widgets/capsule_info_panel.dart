import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import '../../../shared/widgets/app_sheets.dart';
import '../../../shared/widgets/capsule/capsule_author_row.dart';
import '../../../shared/widgets/loop_mark.dart';
import '../../../shared/widgets/pill_v2.dart';
import '../../capsules/opening/capsule_openings.dart';
import '../../capsules/social/capsule_sheet.dart';
import '../../capsules/opening/capsule_locks.dart';
import '../current_location.dart';
import '../../../data/services/location_service.dart';
import '../directions.dart';
import '../../../data/models/geo_position.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';

/// The card above a tapped pin (capsule v3, Figma "v3 Map / Card open" and
/// "Card locked"): a picture, the title, who left it and, for an open
/// capsule, a check with when it opened and the Open pill; for a locked one,
/// the countdown, how much of the wait is done, the day it opens and a soft
/// Locked pill. A locked capsule shows its pin, never its photo. The opened
/// capsule grows out of the photo ([SheetOrigin]).
class CapsuleInfoPanel extends StatefulWidget {
  const CapsuleInfoPanel({
    super.key,
    required this.capsule,
    required this.onMoreInfo,
  });

  final Capsule capsule;

  /// Opens the capsule, from where its photo is on screen.
  final ValueChanged<SheetOrigin?> onMoreInfo;

  /// The locked card's height at the normal text size: its five short lines
  /// with the padding and the dark theme's border (the tallest card).
  static const double minHeight = 108;

  /// How close you must be to open a place capsule (functions/lib/locks.js;
  /// the server adds the fix's accuracy).
  static const double openRadius = 150;

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
    final column = open ? 76.0 : 88.0;
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
  ///
  /// The words go by the check; a day ("Opened on" / "3 Oct 2025") goes on
  /// the line under them.
  static (String, String?) openedLabel(
    Capsule capsule,
    DateTime now,
    AppLocalizations l10n,
  ) {
    final opened = capsule.openAt;
    if (opened == null) return (l10n.mapCapsuleOpenAnytime, null);
    final days = DateUtils.dateOnly(
      now,
    ).difference(DateUtils.dateOnly(opened)).inDays;
    if (days <= 0) return (l10n.mapCapsuleOpenedToday, null);
    if (days == 1) return (l10n.mapCapsuleOpenedYesterday, null);
    return (
      l10n.mapCapsuleOpenedOnLabel,
      AppDates.medium(opened, l10n.localeName),
    );
  }

  @override
  State<CapsuleInfoPanel> createState() => _CapsuleInfoPanelState();
}

class _CapsuleInfoPanelState extends State<CapsuleInfoPanel> {
  Timer? _timer;
  DateTime _now = DateTime.now();
  final _photo = GlobalKey();

  /// A place capsule being opened at its spot (B4).
  bool _opening = false;

  /// Where the user is, when the map knows (null in tests and before the
  /// first fix).
  GeoPosition? _here(BuildContext context) {
    try {
      return context.select<CurrentLocation, GeoPosition?>((l) => l.position);
    } on ProviderNotFoundException {
      return null;
    }
  }

  /// "350 m away", "2.4 km away"; null when unknown.
  static String? _away(double? metres, AppLocalizations l10n) {
    if (metres == null) return null;
    if (metres < 1000) {
      return l10n.mapCapsuleAwayMetres(((metres / 10).round() * 10).toInt());
    }
    final km = metres / 1000;
    final format = NumberFormat(
      km < 100 ? '#,##0.0' : '#,##0',
      l10n.localeName,
    );
    return l10n.mapCapsuleAwayKm(format.format(km));
  }

  /// Opens a place capsule here: a fresh fix, the server's check, then the
  /// capsule (wrapped the first time, D1); a note when it says no.
  Future<void> _openHere(CapsuleLocks locks) async {
    final l10n = context.l10n;
    final location = context.read<LocationService>();
    setState(() => _opening = true);
    void say(String message) => PopupNotificationService.showError(
      context: context,
      message: message,
      position: NotificationPosition.top,
    );
    try {
      final fix = await location.currentFix(request: true);
      if (!mounted) return;
      if (fix == null) return say(l10n.mapCapsuleUnlockNoLocation);
      await locks.unlockHere(
        widget.capsule,
        fix.position,
        accuracy: fix.accuracy,
      );
      if (!mounted) return;
      widget.onMoreInfo(null);
    } on CapsuleUnlockException catch (e) {
      if (!mounted) return;
      say(switch (e.reason) {
        UnlockRefusal.tooFar => l10n.mapCapsuleUnlockTooFar(e.distance ?? 0),
        UnlockRefusal.notYet => l10n.mapCapsuleUnlockNotYet,
        UnlockRefusal.offline => l10n.commonNoConnection,
        UnlockRefusal.notFound ||
        UnlockRefusal.other => l10n.mapCapsuleUnlockFailed,
      });
    } catch (_) {
      if (mounted) say(l10n.mapCapsuleUnlockFailed);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

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
    final locks = CapsuleLocks.maybeOf(context);
    // Its date came and, for a place capsule, it was opened there (B3).
    final isOpen = locks?.mayOpen(capsule, _now) ?? _isOpen;
    // A place capsule whose date came: it waits for you at its spot (B4).
    final ready = !isOpen && capsule.opensHere && _isOpen;
    final spot = capsule.location;
    final me = capsule.opensHere ? _here(context) : null;
    final metres = me == null || spot == null ? null : me.distanceTo(spot);
    final there = metres != null && metres <= CapsuleInfoPanel.openRadius;
    final l10n = context.l10n;
    final away = _away(metres, l10n);
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
              key: _photo,
              // A sealed capsule's picture once it may open (B3).
              capsule: locks?.resolve(capsule, _now) ?? capsule,
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
                  SizedBox(height: isOpen || ready ? 2 : 3),
                  _SecondLine(
                    second,
                    date: left,
                    style: _line(palette.textSecondary),
                  ),
                  SizedBox(height: isOpen || ready ? 2 : 3),
                  if (ready)
                    _PlaceStatus(
                      headline: there
                          ? l10n.mapCapsuleYouAreHere
                          : capsule.openAt == null
                          ? l10n.mapCapsuleBeThere
                          : l10n.mapCapsuleReadyToOpen,
                      away: away ?? l10n.mapCapsuleWhereUnknown,
                      headlineStyle: _line(palette.accentText, bold: true),
                      awayStyle: _line(palette.textSecondary, size: 12),
                    )
                  else if (isOpen)
                    _OpenedStatus(
                      label: wrapped
                          ? (l10n.mapCapsuleYoursToOpen, null)
                          : CapsuleInfoPanel.openedLabel(capsule, _now, l10n),
                      style: _line(palette.accentText, bold: true),
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
                      _Fit(switch (AppDates.compact(
                        capsule.openAt!,
                        l10n.localeName,
                        _now,
                      )) {
                        // Only at its spot: the day, "here" and how far.
                        final day when capsule.opensHere => [
                          l10n.mapCapsuleOpensOnHere(day),
                          ?away,
                        ].join(' · '),
                        final day => l10n.mapCapsuleOpensOn(day),
                      }, style: _line(palette.textMuted, size: 12)),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (ready && there && locks != null)
              PillV2(
                label: l10n.mapCapsuleOpen,
                onTap: _opening ? null : () => _openHere(locks),
              )
            else if (ready && spot != null)
              PillV2(
                label: l10n.mapCapsuleGoThere,
                onTap: () => Directions.open(spot),
              )
            else if (isOpen)
              PillV2(
                label: l10n.mapCapsuleOpen,
                onTap: () => widget.onMoreInfo(
                  SheetOrigin.of(
                    _photo.currentContext,
                    radius: _Thumbnail.radius,
                  ),
                ),
              )
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

/// A place capsule whose date came (B4): "Be there to open", "Ready to
/// open" or "You're here" in green, and how far it is under it.
class _PlaceStatus extends StatelessWidget {
  const _PlaceStatus({
    required this.headline,
    required this.away,
    required this.headlineStyle,
    required this.awayStyle,
  });

  final String headline;
  final String away;
  final TextStyle headlineStyle;
  final TextStyle awayStyle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Fit(headline, style: headlineStyle),
      const SizedBox(height: 2),
      Row(
        children: [
          Image.asset(AppIcons.capsuleLocation, width: 14),
          const SizedBox(width: 4),
          Flexible(child: _Fit(away, style: awayStyle)),
        ],
      ),
    ],
  );
}

/// An open capsule's state in green: the check with the words ("Opened
/// today", "Opened on"), and the day on its own line under the words.
class _OpenedStatus extends StatelessWidget {
  const _OpenedStatus({required this.label, required this.style});

  final (String, String?) label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final (words, day) = label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(AppIcons.profileDone, width: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                words,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ],
        ),
        if (day != null)
          Padding(
            // Under the words, not under the check.
            padding: const EdgeInsets.only(left: 18),
            child: _Fit(day, style: style),
          ),
      ],
    );
  }
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

/// The card's picture: the photo of an open capsule (the opened capsule
/// grows out of it), or the capsule's pin on a muted tile while it is locked.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    super.key,
    required this.capsule,
    required this.isOpen,
    required this.size,
  });

  final Capsule capsule;
  final bool isOpen;
  final double size;

  static const double radius = 14;

  @override
  Widget build(BuildContext context) {
    final url = capsule.thumbUrl ?? capsule.imageUrl;
    if (isOpen && url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The opened capsule lays this same picture under its photo.
              AppNetworkImage(
                url: url,
                cacheWidth: CapsuleSheetPhoto.thumbDecodeWidth,
              ),
              if (capsule.isLoop)
                const Positioned(left: 6, bottom: 6, child: LoopMark()),
            ],
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
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Image.asset(
        AppIcons.mapPin(capsule.color.name),
        width: size * 48 / 76,
      ),
    );
  }
}
