import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/session/session_controller.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/default_text.dart';
import '../../shared/widgets/options/options_section.dart';
import '../../shared/widgets/options/options_settings_row.dart';
import '../friends/friends_store.dart';
import 'device_settings_store.dart';
import 'pages/about_page.dart';
import 'pages/blocked_users_page.dart';
import 'pages/delete_account_page.dart';
import 'pages/device_settings_page.dart';
import 'pages/email_settings_page.dart';
import 'pages/help_page.dart';
import 'pages/name_settings_page.dart';
import 'pages/notification_settings_page.dart';
import 'pages/password_settings_page.dart';
import 'pages/permissions_settings_page.dart';
import 'pages/profile_customization_settings_page.dart';
import 'pages/storage_settings_page.dart';
import 'pages/username_settings_page.dart';
import 'settings_store.dart';
import 'widgets/settings_scaffold.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static Widget _value(String text) => DefaultText(
    text,
    textAlign: TextAlign.left,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final profile = session.profile;
    final hasPassword = context.read<AuthRepository>().hasPassword;
    final notificationsOn = context.select<SettingsStore, bool>(
      (s) => s.notifications.enabled,
    );
    final blockedCount = context.select<FriendsStore, int>(
      (s) => s.blocked.length,
    );
    final mapLook = context.select<DeviceSettingsStore, String>(
      (s) => s.mapLook.label,
    );

    return SettingsScaffold(
      title: 'Settings',
      children: [
        OptionsSection(
          title: 'MY ACCOUNT',
          children: [
            OptionsSettingsRow(
              title: 'Name',
              subtitle: _value(profile?.name ?? 'Loading...'),
              navigateTo: const NameSettingsPage(),
            ),
            OptionsSettingsRow(
              title: 'Username',
              subtitle: _value('@${profile?.username ?? 'Loading...'}'),
              navigateTo: const UsernameSettingsPage(),
            ),
            OptionsSettingsRow(
              title: 'Email',
              // From Auth: the copy in users/{uid} is to be removed
              // (MIGRATIONS_NEEDED.md).
              subtitle: _value(session.email ?? 'Loading...'),
              navigateTo: const EmailSettingsPage(),
            ),
            OptionsSettingsRow(
              title: 'Password',
              subtitle: hasPassword ? null : _value('Signed in with Google'),
              navigateTo: const PasswordSettingsPage(),
            ),
            const OptionsSettingsRow(
              title: 'Customize profile',
              withDivider: false,
              navigateTo: ProfileCustomizationSettingsPage(),
            ),
          ],
        ),
        OptionsSection(
          title: 'NOTIFICATIONS AND PRIVACY',
          children: [
            OptionsSettingsRow(
              title: 'Notifications',
              subtitle: _value(notificationsOn ? 'On' : 'Off'),
              navigateTo: const NotificationSettingsPage(),
            ),
            OptionsSettingsRow(
              title: 'Blocked users',
              subtitle: _value(
                blockedCount == 0 ? 'Nobody' : '$blockedCount blocked',
              ),
              navigateTo: const BlockedUsersPage(),
            ),
            const OptionsSettingsRow(
              title: 'App permissions',
              withDivider: false,
              navigateTo: PermissionsSettingsPage(),
            ),
          ],
        ),
        OptionsSection(
          title: 'THIS PHONE',
          children: [
            OptionsSettingsRow(
              title: 'Map and camera',
              subtitle: _value(mapLook),
              navigateTo: const DeviceSettingsPage(),
            ),
            const OptionsSettingsRow(
              title: 'Data and storage',
              withDivider: false,
              navigateTo: StorageSettingsPage(),
            ),
          ],
        ),
        const OptionsSection(
          title: 'SUPPORT',
          children: [
            OptionsSettingsRow(title: 'Help', navigateTo: HelpPage()),
            OptionsSettingsRow(
              title: 'About',
              withDivider: false,
              navigateTo: AboutPage(),
            ),
          ],
        ),
        OptionsSection(
          children: [
            OptionsSettingsRow(
              title: 'Log Out',
              isLast: true,
              onTap: () {
                ConfirmDialog.show(
                  context: context,
                  title: 'Are you sure you want to log out?',
                  // The session resets every per-user store and the auth
                  // gate shows the login page.
                  onConfirm: () => context.read<SessionController>().signOut(),
                );
              },
            ),
          ],
        ),
        const OptionsSection(
          children: [
            OptionsSettingsRow(
              title: 'Delete account',
              isLast: true,
              navigateTo: DeleteAccountPage(),
            ),
          ],
        ),
      ],
    );
  }
}
