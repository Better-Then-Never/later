import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/session/session_controller.dart';
import '../../core/config/feature_flags.dart';
import '../../core/l10n/l10n.dart';
import '../../data/models/capsule.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/default_text.dart';
import '../../shared/widgets/options/options_section.dart';
import '../../shared/widgets/options/options_settings_row.dart';
import '../../app/appearance/appearance_controller.dart';
import '../friends/friends_store.dart';
import 'device_settings_store.dart';
import 'pages/about_page.dart';
import 'pages/appearance_settings_page.dart';
import 'pages/blocked_users_page.dart';
import 'pages/delete_account_page.dart';
import 'pages/device_settings_page.dart';
import 'pages/email_settings_page.dart';
import 'pages/help_page.dart';
import 'pages/name_settings_page.dart';
import 'pages/notification_settings_page.dart';
import 'pages/password_settings_page.dart';
import 'pages/permissions_settings_page.dart';
import 'pages/privacy_settings_page.dart';
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
    final l10n = context.l10n;
    final session = context.watch<SessionController>();
    final profile = session.profile;
    final hasPassword = context.read<AuthRepository>().hasPassword;
    final notificationsOn = context.select<SettingsStore, bool>(
      (s) => s.notifications.enabled,
    );
    final blockedCount = context.select<FriendsStore, int>(
      (s) => s.blocked.length,
    );
    final mapLook = context.select<DeviceSettingsStore, MapLook>(
      (s) => s.mapLook,
    );
    final themeMode = context.select<AppearanceController, ThemeMode>(
      (a) => a.themeMode,
    );
    // Rebuilds when the language changes (the row shows its name).
    context.select<AppearanceController, String?>((a) => a.language);
    final defaultVisibility = context.select<SettingsStore, CapsulePrivacy>(
      (s) => s.privacy.defaultVisibility,
    );

    return SettingsScaffold(
      title: l10n.settingsTitle,
      children: [
        OptionsSection(
          title: l10n.settingsSectionAccount,
          children: [
            OptionsSettingsRow(
              title: l10n.settingsName,
              subtitle: _value(profile?.name ?? l10n.commonLoading),
              navigateTo: const NameSettingsPage(),
            ),
            OptionsSettingsRow(
              title: l10n.settingsUsername,
              subtitle: _value('@${profile?.username ?? l10n.commonLoading}'),
              navigateTo: const UsernameSettingsPage(),
            ),
            OptionsSettingsRow(
              title: l10n.settingsEmail,
              // From Auth: the copy in users/{uid} is to be removed
              // (MIGRATIONS_NEEDED.md).
              subtitle: _value(session.email ?? l10n.commonLoading),
              navigateTo: const EmailSettingsPage(),
            ),
            OptionsSettingsRow(
              title: l10n.settingsPassword,
              subtitle: hasPassword
                  ? null
                  : _value(l10n.settingsSignedInWithGoogle),
              navigateTo: const PasswordSettingsPage(),
            ),
            OptionsSettingsRow(
              title: l10n.settingsSignInMethods,
              subtitle: _value(
                [
                  if (hasPassword) l10n.settingsSignInEmail,
                  if (context.read<AuthRepository>().hasGoogle) 'Google',
                ].join(' · '),
              ),
              trailing: const SizedBox.shrink(),
            ),
            OptionsSettingsRow(
              title: l10n.settingsCustomizeProfile,
              withDivider: false,
              navigateTo: const ProfileCustomizationSettingsPage(),
            ),
          ],
        ),
        OptionsSection(
          title: l10n.settingsSectionNotificationsPrivacy,
          children: [
            OptionsSettingsRow(
              title: l10n.settingsNotifications,
              subtitle: _value(
                notificationsOn
                    ? l10n.settingsNotificationsOn
                    : l10n.settingsNotificationsOff,
              ),
              navigateTo: const NotificationSettingsPage(),
            ),
            OptionsSettingsRow(
              title: l10n.settingsPrivacy,
              subtitle: _value(
                PrivacySettingsPage.visibilityName(l10n, defaultVisibility),
              ),
              navigateTo: const PrivacySettingsPage(),
            ),
            OptionsSettingsRow(
              title: l10n.settingsBlockedUsers,
              subtitle: _value(
                blockedCount == 0
                    ? l10n.settingsBlockedNobody
                    : l10n.settingsBlockedCount(blockedCount),
              ),
              navigateTo: const BlockedUsersPage(),
            ),
            OptionsSettingsRow(
              title: l10n.settingsAppPermissions,
              withDivider: false,
              navigateTo: const PermissionsSettingsPage(),
            ),
          ],
        ),
        OptionsSection(
          title: l10n.settingsSectionThisPhone,
          children: [
            OptionsSettingsRow(
              title: l10n.settingsAppearance,
              subtitle: _value(
                AppearanceSettingsPage.themeName(l10n, themeMode),
              ),
              navigateTo: const AppearanceSettingsPage(),
            ),
            OptionsSettingsRow(
              title: l10n.settingsLanguage,
              subtitle: _value(LanguageSettingsPage.currentName(context)),
              navigateTo: const LanguageSettingsPage(),
            ),
            OptionsSettingsRow(
              title: l10n.settingsMapAndCamera,
              // MapLibre's tiles have no satellite look: no map look to show.
              subtitle: FeatureFlags.mapLibre ? null : _value(mapLook.label),
              navigateTo: const DeviceSettingsPage(),
            ),
            OptionsSettingsRow(
              title: l10n.settingsDataAndStorage,
              withDivider: false,
              navigateTo: const StorageSettingsPage(),
            ),
          ],
        ),
        OptionsSection(
          title: l10n.settingsSectionSupport,
          children: [
            OptionsSettingsRow(
              title: l10n.settingsHelp,
              navigateTo: const HelpPage(),
            ),
            OptionsSettingsRow(
              title: l10n.settingsAbout,
              withDivider: false,
              navigateTo: const AboutPage(),
            ),
          ],
        ),
        OptionsSection(
          children: [
            OptionsSettingsRow(
              title: l10n.settingsLogOut,
              isLast: true,
              onTap: () {
                ConfirmDialog.show(
                  context: context,
                  title: l10n.settingsLogOutConfirm,
                  // The session resets every per-user store and the auth
                  // gate shows the login page.
                  onConfirm: () => context.read<SessionController>().signOut(),
                );
              },
            ),
          ],
        ),
        OptionsSection(
          children: [
            OptionsSettingsRow(
              title: l10n.settingsDeleteAccount,
              isLast: true,
              navigateTo: const DeleteAccountPage(),
            ),
          ],
        ),
      ],
    );
  }
}
