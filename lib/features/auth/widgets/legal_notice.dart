import 'package:flutter/material.dart';

import '../../../core/config/app_links.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../settings/app_info.dart';

/// "By signing up you agree to the Terms of Use and Privacy Policy", with
/// both opening in the browser.
class LegalNotice extends StatelessWidget {
  const LegalNotice({super.key});

  static const _style = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 13,
    color: AppColors.textSecondary,
  );

  Future<void> _open(BuildContext context, String url) async {
    if (await AppInfo.openUrl(url) || !context.mounted) return;
    PopupNotificationService.showError(
      context: context,
      message: 'Could not open the page.',
      position: NotificationPosition.bottom,
    );
  }

  Widget _link(BuildContext context, String text, String url) => Semantics(
    link: true,
    child: GestureDetector(
      onTap: () => _open(context, url),
      child: Text(
        text,
        style: _style.copyWith(
          color: AppColors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          const Text('By signing up you agree to the ', style: _style),
          _link(context, 'Terms of Use', AppLinks.termsOfService),
          const Text(' and ', style: _style),
          _link(context, 'Privacy Policy', AppLinks.privacyPolicy),
        ],
      ),
    );
  }
}
