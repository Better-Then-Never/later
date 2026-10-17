import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/session/session_controller.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/buttons/default_green_button.dart';
import '../../../shared/widgets/buttons/go_back_button.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../account_settings.dart';

/// "About me": a few words under the name on the user's profile, for
/// everyone who opens it (F-59, F-85).
class AboutSettingsPage extends StatefulWidget {
  const AboutSettingsPage({super.key});

  @override
  State<AboutSettingsPage> createState() => _AboutSettingsPageState();
}

class _AboutSettingsPageState extends State<AboutSettingsPage> {
  late final TextEditingController _text = TextEditingController(
    text: context.read<SessionController>().profile?.about ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final users = context.read<UserRepository>();
    final uid = context.read<SessionController>().uid!;
    setState(() => _saving = true);
    final failure = await AccountSettings.saveAbout(users, uid, _text.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure == null) {
      PopupNotificationService.showSuccess(
        context: context,
        message: context.l10n.settingsAboutUpdated,
        position: NotificationPosition.center,
      );
    } else {
      PopupNotificationService.showError(
        context: context,
        message: failure.message,
        position: NotificationPosition.center,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: palette.backgroundAlt,
      body: Column(
        children: [
          PageHeader(
            mainText: l10n.settingsAbout,
            description: l10n.settingsAboutDescription,
            leadingButton: GoBackButton(context: context),
          ),
          const SizedBox(height: 16),
          Container(
            width: screenWidth * 0.92,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: palette.shadowCard,
                  spreadRadius: 1,
                  blurRadius: 9,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
            child: TextField(
              controller: _text,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              maxLength: UserProfile.maxAbout,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [
                LengthLimitingTextInputFormatter(UserProfile.maxAbout),
              ],
              style: AppTextStyles.body.copyWith(
                fontSize: 17,
                color: palette.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: l10n.settingsAboutHint,
                hintStyle: AppTextStyles.body.copyWith(
                  fontSize: 17,
                  color: palette.textMuted,
                ),
                border: InputBorder.none,
                counterStyle: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: palette.textMuted,
                ),
              ),
            ),
          ),
          // Under the field, not in a bottom bar: the keyboard stays open
          // for a few lines and would cover it.
          Padding(
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.15,
              20,
              screenWidth * 0.15,
              0,
            ),
            child: DefaultGreenButton(
              onTap: _save,
              text: l10n.commonSave,
              isLoading: _saving,
            ),
          ),
        ],
      ),
    );
  }
}
