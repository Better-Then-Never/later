import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/config/app_links.dart';
import '../../../core/l10n/l10n.dart';
import '../../../shared/widgets/default_text.dart';
import '../../../shared/widgets/options/options_section.dart';
import '../../../shared/widgets/options/options_settings_row.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../map/widgets/map_credits_control.dart';
import '../app_info.dart';
import '../widgets/settings_scaffold.dart';

/// Version, legal documents and the licenses of the code Later uses.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _open(BuildContext context, String url) async {
    if (await AppInfo.openUrl(url) || !context.mounted) return;
    PopupNotificationService.showError(
      context: context,
      message: context.l10n.settingsAboutOpenFailed,
      position: NotificationPosition.bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<AppInfo>(
      future: AppInfo.load(),
      builder: (context, snapshot) {
        final version = snapshot.data?.label ?? '...';
        return SettingsScaffold(
          title: l10n.settingsAbout,
          description: '${l10n.appName} $version',
          children: [
            OptionsSection(
              children: [
                OptionsSettingsRow(
                  title: l10n.settingsAboutVersion,
                  trailing: DefaultText(version),
                ),
                OptionsSettingsRow(
                  title: l10n.settingsAboutPrivacy,
                  onTap: () => _open(context, AppLinks.privacyPolicy),
                ),
                OptionsSettingsRow(
                  title: l10n.settingsAboutTerms,
                  onTap: () => _open(context, AppLinks.termsOfService),
                ),
                OptionsSettingsRow(
                  title: l10n.settingsAboutMapData,
                  onTap: () => showMapCredits(context),
                ),
                OptionsSettingsRow(
                  title: l10n.settingsAboutLicenses,
                  withDivider: false,
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: l10n.appName,
                    applicationVersion: version,
                    applicationIcon: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        AppImages.laterLogo,
                        width: 64,
                        height: 64,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
