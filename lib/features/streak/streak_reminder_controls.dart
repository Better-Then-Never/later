import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n.dart';
import '../../shared/widgets/popup/popup_notification_service.dart';
import '../settings/device_settings_store.dart';
import '../settings/settings_store.dart';

/// The streak reminder's switch and time, the same on the Streak page and
/// in Settings > Notifications.
abstract final class StreakReminderControls {
  /// [minutes] after midnight as the phone writes times ("20:00", "8:00 PM").
  static String time(BuildContext context, int minutes) =>
      MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );

  /// Turns the reminder on or off. On asks the phone to allow notifications
  /// first (Android 13 and later); refused, it stays off. Either way the old
  /// evening push from the server is switched off: one reminder, from the
  /// phone.
  static Future<void> setOn(BuildContext context, bool value) async {
    final device = context.read<DeviceSettingsStore>();
    final settings = context.read<SettingsStore>();
    final l10n = context.l10n;
    if (value && !await _allowed()) {
      if (!context.mounted) return;
      PopupNotificationService.showError(
        context: context,
        message: l10n.streakReminderDenied,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    await device.setStreakReminder(value);
    final n = settings.notifications;
    if (settings.isLoaded && n.streakReminder) {
      unawaited(
        settings.updateNotifications(n.copyWith(streakReminder: false)),
      );
    }
  }

  static Future<bool> _allowed() async {
    try {
      return (await Permission.notification.request()).isGranted;
    } catch (_) {
      // No answer from the phone (tests, an old plugin): let it try.
      return true;
    }
  }

  /// Lets the user choose another time.
  static Future<void> pickTime(BuildContext context) async {
    final device = context.read<DeviceSettingsStore>();
    final minutes = device.streakReminderMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      helpText: context.l10n.streakReminderTimeTitle,
    );
    if (picked == null) return;
    await device.setStreakReminderMinutes(picked.hour * 60 + picked.minute);
  }
}
