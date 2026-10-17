import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      message: 'Password changed',
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
        message: 'We sent a reset link to $email',
        position: NotificationPosition.center,
      );
    } catch (e) {
      if (!mounted) return;
      PopupNotificationService.showError(
        context: context,
        message: 'Could not send the link. Please try again.',
        position: NotificationPosition.center,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository>();
    if (!auth.hasPassword) {
      return const SettingsScaffold(
        title: 'Password',
        description: 'You sign in with Google',
        children: [
          SettingsNote(
            'Your account has no Later password: Google confirms it is you. '
            'Change your password in your Google account.',
          ),
        ],
      );
    }
    final gap = SizedBox(height: MediaQuery.of(context).size.height * 0.015);
    return SettingsScaffold(
      title: 'Password',
      description: 'Choose a password you do not use anywhere else',
      buttonText: 'Save',
      onButton: _save,
      busy: _saving,
      children: [
        Center(
          child: AutofillGroup(
            child: Column(
              children: [
                OptionsInputField(
                  controller: _current,
                  hintText: 'Current password',
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.next,
                ),
                gap,
                OptionsInputField(
                  controller: _next,
                  hintText:
                      'New password (${AccountSecurity.minPasswordLength}+ characters)',
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                ),
                gap,
                OptionsInputField(
                  controller: _confirm,
                  hintText: 'Repeat new password',
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
              title: 'Forgot your password?',
              withDivider: false,
              onTap: _sendReset,
            ),
          ],
        ),
      ],
    );
  }
}
