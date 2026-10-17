import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../core/l10n/app_dates.dart';

/// Small window above a marker: title, creation date, countdown or
/// "Check out what's inside!", and the Open/Locked button.
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

  /// Compact countdown ("2d 5h 30m 15s" in English) in the app's language.
  static String formatDuration(Duration d, AppLocalizations l10n) {
    if (d.isNegative) return '';
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return [
      if (days > 0) l10n.mapDurationDays(days),
      if (hours > 0 || days > 0) l10n.mapDurationHours(hours),
      if (minutes > 0 || hours > 0 || days > 0)
        l10n.mapDurationMinutes(minutes),
      l10n.mapDurationSeconds(seconds),
    ].join(' ');
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
      child: Column(
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
            style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 16),
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
                      formatDuration(capsule.timeUntilOpen(_now), l10n),
                    ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isOpen ? AppColors.brandGreen : AppColors.materialRed,
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
    );
  }
}
