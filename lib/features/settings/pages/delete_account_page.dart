import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/session/session_controller.dart';
import '../../../core/errors/app_failure.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/options/options_input_field.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../account_settings.dart';
import '../widgets/settings_scaffold.dart';

/// Deletes the account for good, after a last confirmation and the
/// password (or Google) check.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _password = TextEditingController();
  bool _deleting = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_deleting) return;
    ConfirmDialog.show(
      context: context,
      title: 'Delete your account? This cannot be undone.',
      confirmText: 'Delete',
      onConfirm: _delete,
    );
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    final session = context.read<SessionController>();
    final failure = await AccountSecurity.deleteAccount(
      context.read<AuthRepository>(),
      session.deleteAccount,
      password: _password.text,
    );
    if (!mounted) return;
    setState(() => _deleting = false);
    if (failure == null) {
      // Signed out: the auth gate shows the welcome page.
      AppRoutes.backToRoot();
      return;
    }
    if (failure is CancelledFailure) return;
    PopupNotificationService.showError(
      context: context,
      message: failure.message,
      position: NotificationPosition.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPassword = context.read<AuthRepository>().hasPassword;
    return SettingsScaffold(
      title: 'Delete account',
      description: 'This removes your account and everything in it',
      buttonText: 'Delete my account',
      onButton: _confirm,
      busy: _deleting,
      destructive: true,
      children: [
        const SettingsNote(
          'Deleting your account removes your profile, pictures, capsules, '
          'chats, friends and followers. Your friends will no longer see you '
          'or your messages. This cannot be undone.',
        ),
        if (hasPassword)
          Center(
            child: OptionsInputField(
              controller: _password,
              hintText: 'Your password',
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
            ),
          )
        else
          const SettingsNote(
            'Google confirms it is you: pick your account when asked.',
          ),
      ],
    );
  }
}
