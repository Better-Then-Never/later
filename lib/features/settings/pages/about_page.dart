import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/config/app_links.dart';
import '../../../shared/widgets/default_text.dart';
import '../../../shared/widgets/options/options_section.dart';
import '../../../shared/widgets/options/options_settings_row.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../app_info.dart';
import '../widgets/settings_scaffold.dart';

/// Version, legal documents and the licenses of the code Later uses.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _open(BuildContext context, String url) async {
    if (await AppInfo.openUrl(url) || !context.mounted) return;
    PopupNotificationService.showError(
      context: context,
      message: 'Could not open the page.',
      position: NotificationPosition.bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppInfo>(
      future: AppInfo.load(),
      builder: (context, snapshot) {
        final version = snapshot.data?.label ?? '...';
        return SettingsScaffold(
          title: 'About',
          description: 'Later $version',
          children: [
            OptionsSection(
              children: [
                OptionsSettingsRow(
                  title: 'Version',
                  trailing: DefaultText(version),
                ),
                OptionsSettingsRow(
                  title: 'Privacy policy',
                  onTap: () => _open(context, AppLinks.privacyPolicy),
                ),
                OptionsSettingsRow(
                  title: 'Terms of use',
                  onTap: () => _open(context, AppLinks.termsOfService),
                ),
                OptionsSettingsRow(
                  title: 'Open-source licenses',
                  withDivider: false,
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Later',
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
