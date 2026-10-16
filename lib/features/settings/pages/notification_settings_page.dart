import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

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
      helpText: start ? 'Quiet from' : 'Quiet until',
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

  @override
  Widget build(BuildContext context) {
    final n = context.select<SettingsStore, NotificationSettings>(
      (s) => s.notifications,
    );
    final on = n.enabled;
    final quiet = n.quietHours;

    return SettingsScaffold(
      title: 'Notifications',
      description: 'Choose what Later tells you about',
      children: [
        if (_systemAllowed == false)
          OptionsSection(
            footer:
                'Your phone does not let Later show notifications, so none '
                'arrive whatever you choose below.',
            children: [
              OptionsSettingsRow(
                title: 'Allow notifications',
                subtitle: const DefaultText(
                  'Off in your phone settings',
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
              title: 'Push notifications',
              subtitle: on ? null : 'You get no pushes from Later',
              value: on,
              withDivider: false,
              onChanged: (v) => _save(n.copyWith(enabled: v)),
            ),
          ],
        ),
        OptionsSection(
          title: 'NOTIFY ME ABOUT',
          children: [
            OptionsSwitchRow(
              title: 'Messages',
              value: n.messages,
              onChanged: on ? (v) => _save(n.copyWith(messages: v)) : null,
            ),
            OptionsSwitchRow(
              title: 'New followers',
              value: n.follows,
              onChanged: on ? (v) => _save(n.copyWith(follows: v)) : null,
            ),
            OptionsSwitchRow(
              title: 'New capsules',
              subtitle: 'From people you follow with notifications on',
              value: n.capsules,
              withDivider: false,
              onChanged: on ? (v) => _save(n.copyWith(capsules: v)) : null,
            ),
          ],
        ),
        OptionsSection(
          title: 'HOW',
          children: [
            OptionsSwitchRow(
              title: 'Show message text',
              subtitle: n.preview ? null : 'Pushes say "New message" only',
              value: n.preview,
              onChanged: on ? (v) => _save(n.copyWith(preview: v)) : null,
            ),
            OptionsSwitchRow(
              title: 'Sound and vibration',
              value: n.sound,
              withDivider: false,
              onChanged: on ? (v) => _save(n.copyWith(sound: v)) : null,
            ),
          ],
        ),
        OptionsSection(
          title: 'QUIET HOURS',
          footer:
              'No pushes during these hours. Messages still arrive in the app.',
          children: [
            OptionsSwitchRow(
              title: 'Quiet hours',
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
                title: 'From',
                trailing: DefaultText(_time(quiet.start)),
                onTap: on ? () => _pickTime(quiet, start: true) : null,
              ),
              OptionsSettingsRow(
                title: 'Until',
                trailing: DefaultText(_time(quiet.end)),
                withDivider: false,
                onTap: on ? () => _pickTime(quiet, start: false) : null,
              ),
            ],
          ],
        ),
        const SettingsNote('Mute a single chat from its menu in Messages.'),
      ],
    );
  }
}
