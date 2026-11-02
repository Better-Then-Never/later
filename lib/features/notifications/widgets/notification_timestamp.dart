import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../notification_texts.dart';

/// "2h ago" under a notification's sentence.
class NotificationTimestamp extends StatelessWidget {
  final DateTime timestamp;

  const NotificationTimestamp({super.key, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Text(
      NotificationTexts.time(timestamp, DateTime.now(), l10n: context.l10n),
      style: AppTextStyles.body.copyWith(
        fontSize: 13,
        height: 1.25,
        color: context.palette.textSecondary,
      ),
    );
  }
}
