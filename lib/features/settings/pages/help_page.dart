import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/session/session_controller.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/config/app_links.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../shared/widgets/default_text.dart';
import '../../../shared/widgets/options/options_section.dart';
import '../../../shared/widgets/options/options_settings_row.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../app_info.dart';
import '../widgets/settings_scaffold.dart';

/// Answers to common questions and ways to reach the team.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _faq = [
    (
      'What is a capsule?',
      'A photo with a title and a note, pinned on the map where you made it. '
          'You can set a date: until then the capsule stays locked.',
    ),
    (
      'Who can see my capsules?',
      'You choose when you create one: only you (Private), your friends '
          '(Friends) or everyone (Public).',
    ),
    (
      'How do I add friends?',
      'Search by username in Friends, scan their QR code, or share your '
          'profile link from your profile.',
    ),
    (
      'I do not get notifications',
      'Check Settings > Notifications: the phone must allow Later to notify '
          'you, and push notifications must be on. Quiet hours and muted chats '
          'also keep pushes silent.',
    ),
    (
      'How do I stop someone contacting me?',
      'Block them from their profile or from the chat menu. You can unblock '
          'them in Settings > Blocked users.',
    ),
    (
      'How do I delete my account?',
      'Settings > Delete account. Everything you made is removed and cannot '
          'be brought back.',
    ),
  ];

  Future<void> _copyInfo(BuildContext context) async {
    final uid = context.read<SessionController>().uid;
    final info = await AppInfo.load();
    await Clipboard.setData(ClipboardData(text: info.supportText(uid: uid)));
    if (!context.mounted) return;
    PopupNotificationService.showSuccess(
      context: context,
      message: 'Copied. Paste it into your message to us.',
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
        message: 'No email app found. Write to ${AppLinks.supportEmail}',
        position: NotificationPosition.bottom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Help',
      description: 'Answers and ways to reach us',
      children: [
        OptionsSection(
          title: 'QUESTIONS',
          children: [
            for (final (i, (q, a)) in _faq.indexed)
              _FaqRow(question: q, answer: a, last: i == _faq.length - 1),
          ],
        ),
        OptionsSection(
          title: 'CONTACT',
          footer:
              'Emails from the app include your app version and phone. '
              'You can also write to ${AppLinks.supportEmail}.',
          children: [
            OptionsSettingsRow(
              title: 'Contact support',
              onTap: () => _write(context, 'Later: question'),
            ),
            OptionsSettingsRow(
              title: 'Report a problem',
              onTap: () => _write(context, 'Later: problem report'),
            ),
            OptionsSettingsRow(
              title: 'Copy app information',
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
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.only(
                    left: screenWidth * 0.05,
                    right: screenWidth * 0.05,
                    bottom: screenWidth * 0.03,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        if (!widget.last)
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
      ],
    );
  }
}
