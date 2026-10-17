import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/session/session_controller.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/l10n/l10n.dart';
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
      title: context.l10n.settingsDeleteConfirm,
      confirmText: context.l10n.commonDelete,
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
    final l10n = context.l10n;
    return SettingsScaffold(
      title: l10n.settingsDeleteAccount,
      description: l10n.settingsDeleteDescription,
      buttonText: l10n.settingsDeleteButton,
      onButton: _confirm,
      busy: _deleting,
      destructive: true,
      children: [
        SettingsNote(l10n.settingsDeleteNote),
        if (hasPassword)
          Center(
            child: OptionsInputField(
              controller: _password,
              hintText: l10n.settingsYourPassword,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
            ),
          )
        else
          SettingsNote(l10n.settingsGoogleConfirmsNote),
      ],
    );
  }
}
