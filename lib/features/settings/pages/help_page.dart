import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/session/session_controller.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/config/app_links.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/default_text.dart';
import '../../../shared/widgets/options/options_section.dart';
import '../../../shared/widgets/options/options_settings_row.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../app_info.dart';
import '../widgets/settings_scaffold.dart';

/// Answers to common questions and ways to reach the team.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static List<(String, String)> _faq(AppLocalizations l10n) => [
    (l10n.settingsFaqCapsuleQuestion, l10n.settingsFaqCapsuleAnswer),
    (l10n.settingsFaqVisibilityQuestion, l10n.settingsFaqVisibilityAnswer),
    (l10n.settingsFaqFriendsQuestion, l10n.settingsFaqFriendsAnswer),
    (
      l10n.settingsFaqNotificationsQuestion,
      l10n.settingsFaqNotificationsAnswer,
    ),
    (l10n.settingsFaqBlockQuestion, l10n.settingsFaqBlockAnswer),
    (l10n.settingsFaqDeleteQuestion, l10n.settingsFaqDeleteAnswer),
  ];

  Future<void> _copyInfo(BuildContext context) async {
    final uid = context.read<SessionController>().uid;
    final info = await AppInfo.load();
    await Clipboard.setData(ClipboardData(text: info.supportText(uid: uid)));
    if (!context.mounted) return;
    PopupNotificationService.showSuccess(
      context: context,
      message: context.l10n.settingsHelpCopied,
      position: NotificationPosition.bottom,
    );
  }

  Future<void> _write(BuildContext context, String subject) async {
    final uid = context.read<SessionController>().uid;
    final info = await AppInfo.load();
    final opened = await AppInfo.openEmail(
      AppLinks.supportEmail,
      subject: subject,
      body: '\n\n---\n${info.supportText(uid: uid)}',
    );
    if (!opened && context.mounted) {
      PopupNotificationService.showError(
        context: context,
        message: context.l10n.settingsHelpNoEmailApp(AppLinks.supportEmail),
        position: NotificationPosition.bottom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final faq = _faq(l10n);
    return SettingsScaffold(
      title: l10n.settingsHelp,
      description: l10n.settingsHelpDescription,
      children: [
        OptionsSection(
          title: l10n.settingsSectionQuestions,
          children: [
            for (final (i, (q, a)) in faq.indexed)
              _FaqRow(question: q, answer: a, last: i == faq.length - 1),
          ],
        ),
        OptionsSection(
          title: l10n.settingsSectionContact,
          footer: l10n.settingsHelpContactFooter(AppLinks.supportEmail),
          children: [
            OptionsSettingsRow(
              title: l10n.settingsHelpContactSupport,
              onTap: () => _write(context, l10n.settingsHelpSubjectQuestion),
            ),
            OptionsSettingsRow(
              title: l10n.settingsHelpReportProblem,
              onTap: () => _write(context, l10n.settingsHelpSubjectProblem),
            ),
            OptionsSettingsRow(
              title: l10n.settingsHelpCopyInfo,
              withDivider: false,
              onTap: () => _copyInfo(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _FaqRow extends StatefulWidget {
  const _FaqRow({
    required this.question,
    required this.answer,
    required this.last,
  });

  final String question;
  final String answer;
  final bool last;

  @override
  State<_FaqRow> createState() => _FaqRowState();
}

class _FaqRowState extends State<_FaqRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        OptionsSettingsRow(
          title: widget.question,
          withDivider: false,
          trailing: AnimatedRotation(
            turns: _open ? 0.25 : 0,
            duration: AppMotion.of(context, AppMotion.fast),
            curve: AppMotion.standardCurve,
            // The same arrow as every settings row, turned down when open.
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                AppIcons.goHere,
                width: screenWidth * 0.09,
                height: screenWidth * 0.09,
              ),
            ),
          ),
          onTap: () => setState(() => _open = !_open),
        ),
        AnimatedSize(
          duration: AppMotion.of(context, AppMotion.standard),
          curve: AppMotion.standardCurve,
          alignment: Alignment.topCenter,
          child: _open
              ? DefaultText(
                  widget.answer,
                  textAlign: TextAlign.left,
                  color: context.palette.textSecondary,
                  padding: EdgeInsets.only(
                    left: screenWidth * 0.05,
                    right: screenWidth * 0.05,
                    bottom: screenWidth * 0.03,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        if (!widget.last)
          Divider(height: 1, thickness: 1, color: context.palette.divider),
      ],
    );
  }
}
