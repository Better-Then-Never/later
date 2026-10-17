import 'package:flutter/material.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/core/theme/app_palette.dart';
import 'package:later/features/notifications/notification_texts.dart';
import 'package:later/shared/widgets/default_text.dart';

class NotificationTimestamp extends StatelessWidget {
  final DateTime timestamp;

  const NotificationTimestamp({super.key, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return DefaultText(
      NotificationTexts.time(timestamp, DateTime.now(), l10n: context.l10n),
      fontSize: 12,
      color: context.palette.textMuted,
    );
  }
}
