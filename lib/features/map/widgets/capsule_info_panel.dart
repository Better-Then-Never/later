import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';

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

  /// Smallest height that fits the content (title, date, status, button);
  /// the original fixed 17.1% of the screen overflowed on most phones.
  static const double minHeight = 152;

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

  static String formatDuration(Duration d) {
    if (d.isNegative) return '';
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return [
      if (days > 0) '${days}d',
      if (hours > 0 || days > 0) '${hours}h',
      if (minutes > 0 || hours > 0 || days > 0) '${minutes}m',
      '${seconds}s',
    ].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final capsule = widget.capsule;
    final isOpen = _isOpen;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.lCircular,
        boxShadow: AppShadows.mapInfo,
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
            DateFormat(
              'dd-MM-yyyy',
            ).format(capsule.createdAt ?? DateTime.now()),
            style: const TextStyle(fontFamily: kAppFontFamily, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            isOpen
                ? "Check out what's inside!"
                : 'Opens in ${formatDuration(capsule.timeUntilOpen(_now))}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isOpen ? AppColors.brandGreen : Colors.red,
              fontFamily: kAppFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isOpen ? AppColors.brandGreen : Colors.grey,
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
              child: Text(
                isOpen ? 'Open' : 'Locked',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: kAppFontFamily,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
