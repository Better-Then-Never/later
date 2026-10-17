import 'package:flutter/material.dart';

import '../../../core/config/app_links.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../settings/app_info.dart';

/// "By signing up you agree to the Terms of Use and Privacy Policy", with
/// both opening in the browser.
class LegalNotice extends StatelessWidget {
  const LegalNotice({super.key});

  /// Stand-ins for the two links in the translated sentence, so each
  /// language can put them where its grammar wants them.
  static const _termsMark = '\u0001';
  static const _privacyMark = '\u0002';

  TextStyle _style(BuildContext context) => TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 13,
    color: context.palette.textSecondary,
  );

  Future<void> _open(BuildContext context, String url) async {
    if (await AppInfo.openUrl(url) || !context.mounted) return;
    PopupNotificationService.showError(
      context: context,
      message: context.l10n.authLinkOpenFailed,
      position: NotificationPosition.bottom,
    );
  }

  Widget _link(BuildContext context, String text, String url) => Semantics(
    link: true,
    child: GestureDetector(
      onTap: () => _open(context, url),
      child: Text(
        text,
        style: _style(context).copyWith(
          color: context.palette.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = _style(context);
    final sentence = l10n.authLegalNotice(_termsMark, _privacyMark);
    final children = <Widget>[];
    var start = 0;
    for (final mark in RegExp(
      '[$_termsMark$_privacyMark]',
    ).allMatches(sentence)) {
      if (mark.start > start) {
        children.add(Text(sentence.substring(start, mark.start), style: style));
      }
      children.add(
        mark[0] == _termsMark
            ? _link(context, l10n.authTermsOfUse, AppLinks.termsOfService)
            : _link(context, l10n.authPrivacyPolicy, AppLinks.privacyPolicy),
      );
      start = mark.end;
    }
    if (start < sentence.length) {
      children.add(Text(sentence.substring(start), style: style));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Wrap(alignment: WrapAlignment.center, children: children),
    );
  }
}
