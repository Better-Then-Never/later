import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/options/options_input_field.dart';
import '../../../shared/widgets/options/options_section.dart';
import '../../../shared/widgets/options/options_settings_row.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../account_settings.dart';
import '../widgets/settings_scaffold.dart';

/// Change the password: the current one confirms it is the user.
class PasswordSettingsPage extends StatefulWidget {
  const PasswordSettingsPage({super.key});

  @override
  State<PasswordSettingsPage> createState() => _PasswordSettingsPageState();
}

class _PasswordSettingsPageState extends State<PasswordSettingsPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final failure = await AccountSecurity.changePassword(
      context.read<AuthRepository>(),
      current: _current.text,
      next: _next.text,
      confirm: _confirm.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure != null) {
      PopupNotificationService.showError(
        context: context,
        message: failure.message,
        position: NotificationPosition.center,
      );
      return;
    }
    _current.clear();
    _next.clear();
    _confirm.clear();
    PopupNotificationService.showSuccess(
      context: context,
      message: context.l10n.settingsPasswordChanged,
      position: NotificationPosition.center,
    );
  }

  Future<void> _sendReset() async {
    final auth = context.read<AuthRepository>();
    final email = auth.currentEmail;
    if (email == null) return;
    try {
      await auth.sendPasswordReset(email);
      if (!mounted) return;
      PopupNotificationService.showSuccess(
        context: context,
        message: context.l10n.settingsPasswordResetSent(email),
        position: NotificationPosition.center,
      );
    } catch (e) {
      if (!mounted) return;
      PopupNotificationService.showError(
        context: context,
        message: context.l10n.settingsPasswordResetFailed,
        position: NotificationPosition.center,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository>();
    final l10n = context.l10n;
    if (!auth.hasPassword) {
      return SettingsScaffold(
        title: l10n.settingsPassword,
        description: l10n.settingsPasswordGoogleDescription,
        children: [SettingsNote(l10n.settingsPasswordGoogleNote)],
      );
    }
    final gap = SizedBox(height: MediaQuery.of(context).size.height * 0.015);
    return SettingsScaffold(
      title: l10n.settingsPassword,
      description: l10n.settingsPasswordDescription,
      buttonText: l10n.commonSave,
      onButton: _save,
      busy: _saving,
      children: [
        Center(
          child: AutofillGroup(
            child: Column(
              children: [
                OptionsInputField(
                  controller: _current,
                  hintText: l10n.settingsPasswordCurrent,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.next,
                ),
                gap,
                OptionsInputField(
                  controller: _next,
                  hintText: l10n.settingsPasswordNew(
                    AccountSecurity.minPasswordLength,
                  ),
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                ),
                gap,
                OptionsInputField(
                  controller: _confirm,
                  hintText: l10n.settingsPasswordRepeat,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                ),
                gap,
              ],
            ),
          ),
        ),
        OptionsSection(
          children: [
            OptionsSettingsRow(
              title: l10n.settingsPasswordForgot,
              withDivider: false,
              onTap: _sendReset,
            ),
          ],
        ),
      ],
    );
  }
}
