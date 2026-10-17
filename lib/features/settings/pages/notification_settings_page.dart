import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/models/user_settings.dart';
import '../../../shared/widgets/options/options_section.dart';
import '../../../shared/widgets/options/options_settings_row.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../../shared/widgets/default_text.dart';
import '../settings_store.dart';
import '../widgets/settings_scaffold.dart';

/// Which pushes the user gets. The Cloud Functions read the same settings
/// before every push (functions/lib/prefs.js).
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage>
    with WidgetsBindingObserver {
  /// Whether the phone lets Later show notifications at all.
  bool? _systemAllowed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from the phone's settings: show what changed there.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      final status = await Permission.notification.status;
      if (mounted) setState(() => _systemAllowed = status.isGranted);
    } catch (_) {
      // Unknown: show no banner.
    }
  }

  Future<void> _allowInSystem() async {
    final status = await Permission.notification.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _systemAllowed = true);
    } else {
      await openAppSettings();
    }
  }

  Future<void> _save(NotificationSettings next) async {
    final failure = await context.read<SettingsStore>().updateNotifications(
      next,
    );
    if (failure != null && mounted) {
      PopupNotificationService.showError(
        context: context,
        message: failure.message,
        position: NotificationPosition.bottom,
      );
    }
  }

  Future<void> _pickTime(QuietHours quiet, {required bool start}) async {
    final minutes = start ? quiet.start : quiet.end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      helpText: start
          ? context.l10n.settingsQuietFrom
          : context.l10n.settingsQuietUntil,
    );
    if (picked == null || !mounted) return;
    final value = picked.hour * 60 + picked.minute;
    final n = context.read<SettingsStore>().notifications;
    await _save(
      n.copyWith(
        quietHours: start
            ? n.quietHours.copyWith(start: value)
            : n.quietHours.copyWith(end: value),
      ),
    );
  }

  String _time(int minutes) =>
      MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
        alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
      );

  /// Switches of the features that are on (FeatureFlags); the last one has
  /// no divider.
  List<Widget> _activityRows(
    AppLocalizations l10n,
    NotificationSettings n,
    bool on,
  ) {
    final rows = <(String, String?, bool, NotificationSettings Function(bool))>[
      if (FeatureFlags.reactions)
        (
          l10n.settingsNotificationsReactions,
          null,
          n.reactions,
          (v) => n.copyWith(reactions: v),
        ),
      if (FeatureFlags.comments)
        (
          l10n.settingsNotificationsComments,
          l10n.settingsNotificationsCommentsHint,
          n.comments,
          (v) => n.copyWith(comments: v),
        ),
      if (FeatureFlags.achievements)
        (
          l10n.settingsNotificationsAchievements,
          null,
          n.achievements,
          (v) => n.copyWith(achievements: v),
        ),
      if (FeatureFlags.streaks)
        (
          l10n.settingsNotificationsStreak,
          l10n.settingsNotificationsStreakHint,
          n.streakReminder,
          (v) => n.copyWith(streakReminder: v),
        ),
      if (FeatureFlags.news)
        (
          l10n.settingsNotificationsNews,
          l10n.settingsNotificationsNewsHint,
          n.news,
          (v) => n.copyWith(news: v),
        ),
    ];
    return [
      for (final (i, (title, subtitle, value, next)) in rows.indexed)
        OptionsSwitchRow(
          title: title,
          subtitle: subtitle,
          value: value,
          withDivider: i < rows.length - 1,
          onChanged: on ? (v) => _save(next(v)) : null,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final n = context.select<SettingsStore, NotificationSettings>(
      (s) => s.notifications,
    );
    // Until the saved settings arrive the page shows the defaults; a change
    // then would save them over the user's real choices.
    final loaded = context.select<SettingsStore, bool>((s) => s.isLoaded);
    final on = n.enabled && loaded;
    final quiet = n.quietHours;
    final l10n = context.l10n;

    return SettingsScaffold(
      title: l10n.settingsNotifications,
      description: l10n.settingsNotificationsDescription,
      children: [
        if (_systemAllowed == false)
          OptionsSection(
            footer: l10n.settingsNotificationsBlockedFooter,
            children: [
              OptionsSettingsRow(
                title: l10n.settingsNotificationsAllow,
                subtitle: DefaultText(
                  l10n.settingsNotificationsOffInPhone,
                  textAlign: TextAlign.left,
                ),
                withDivider: false,
                onTap: _allowInSystem,
              ),
            ],
          ),
        OptionsSection(
          children: [
            OptionsSwitchRow(
              title: l10n.settingsNotificationsPush,
              subtitle: n.enabled ? null : l10n.settingsNotificationsPushOff,
              value: n.enabled,
              withDivider: false,
              onChanged: loaded ? (v) => _save(n.copyWith(enabled: v)) : null,
            ),
          ],
        ),
        OptionsSection(
          title: l10n.settingsSectionNotifyAbout,
          children: [
            OptionsSwitchRow(
              title: l10n.settingsNotificationsMessages,
              value: n.messages,
              onChanged: on ? (v) => _save(n.copyWith(messages: v)) : null,
            ),
            OptionsSwitchRow(
              title: l10n.settingsNotificationsFollowers,
              value: n.follows,
              onChanged: on ? (v) => _save(n.copyWith(follows: v)) : null,
            ),
            OptionsSwitchRow(
              title: l10n.settingsNotificationsFriendRequests,
              subtitle: l10n.settingsNotificationsFriendRequestsHint,
              value: n.friendRequests,
              onChanged: on
                  ? (v) => _save(n.copyWith(friendRequests: v))
                  : null,
            ),
            OptionsSwitchRow(
              title: l10n.settingsNotificationsCapsules,
              subtitle: l10n.settingsNotificationsCapsulesHint,
              value: n.capsules,
              withDivider: false,
              onChanged: on ? (v) => _save(n.copyWith(capsules: v)) : null,
            ),
          ],
        ),
        if (_activityRows(l10n, n, on) case final rows when rows.isNotEmpty)
          OptionsSection(
            title: l10n.settingsSectionMoreActivity,
            children: rows,
          ),
        OptionsSection(
          title: l10n.settingsSectionHow,
          children: [
            OptionsSwitchRow(
              title: l10n.settingsNotificationsPreview,
              subtitle: n.preview ? null : l10n.settingsNotificationsPreviewOff,
              value: n.preview,
              onChanged: on ? (v) => _save(n.copyWith(preview: v)) : null,
            ),
            OptionsSwitchRow(
              title: l10n.settingsNotificationsSound,
              value: n.sound,
              onChanged: on ? (v) => _save(n.copyWith(sound: v)) : null,
            ),
            // With the sound only: a silent push never vibrates.
            OptionsSwitchRow(
              title: l10n.settingsNotificationsVibrate,
              subtitle: n.sound
                  ? null
                  : l10n.settingsNotificationsVibrateNeedsSound,
              value: n.sound && n.vibrate,
              withDivider: false,
              onChanged: on && n.sound
                  ? (v) => _save(n.copyWith(vibrate: v))
                  : null,
            ),
          ],
        ),
        OptionsSection(
          title: l10n.settingsSectionQuietHours,
          footer: l10n.settingsQuietHoursFooter,
          children: [
            OptionsSwitchRow(
              title: l10n.settingsQuietHours,
              value: quiet.enabled,
              withDivider: quiet.enabled,
              onChanged: on
                  ? (v) => _save(
                      n.copyWith(quietHours: quiet.copyWith(enabled: v)),
                    )
                  : null,
            ),
            if (quiet.enabled) ...[
              OptionsSettingsRow(
                title: l10n.settingsQuietHoursFrom,
                trailing: DefaultText(_time(quiet.start)),
                onTap: on ? () => _pickTime(quiet, start: true) : null,
              ),
              OptionsSettingsRow(
                title: l10n.settingsQuietHoursUntil,
                trailing: DefaultText(_time(quiet.end)),
                withDivider: false,
                onTap: on ? () => _pickTime(quiet, start: false) : null,
              ),
            ],
          ],
        ),
        SettingsNote(l10n.settingsNotificationsMuteHint),
      ],
    );
  }
}
