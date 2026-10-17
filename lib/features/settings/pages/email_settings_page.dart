import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/app_failure.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/options/options_input_field.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../account_settings.dart';
import '../widgets/settings_scaffold.dart';

/// Change the sign-in email. Firebase sends a link to the new address; the
/// email changes when the user opens it.
class EmailSettingsPage extends StatefulWidget {
  const EmailSettingsPage({super.key});

  @override
  State<EmailSettingsPage> createState() => _EmailSettingsPageState();
}

class _EmailSettingsPageState extends State<EmailSettingsPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _saving = false;
  String? _sentTo;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final email = _email.text.trim();
    final failure = await AccountSecurity.changeEmail(
      context.read<AuthRepository>(),
      newEmail: email,
      password: _password.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure is CancelledFailure) return;
    if (failure != null) {
      PopupNotificationService.showError(
        context: context,
        message: failure.message,
        position: NotificationPosition.center,
      );
      return;
    }
    _password.clear();
    setState(() => _sentTo = email);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository>();
    final current = auth.currentEmail ?? '';
    if (!auth.hasPassword) {
      return SettingsScaffold(
        title: 'Email',
        description: 'You sign in with Google as $current',
        children: const [
          SettingsNote(
            'Your email comes from your Google account. To use another one, '
            'change it in your Google account.',
          ),
        ],
      );
    }
    final gap = SizedBox(height: MediaQuery.of(context).size.height * 0.015);
    return SettingsScaffold(
      title: 'Email',
      description: 'You sign in to Later with $current',
      buttonText: 'Send confirmation link',
      onButton: _save,
      busy: _saving,
      children: [
        if (_sentTo != null)
          SettingsNote(
            'We sent a link to $_sentTo. Open it to confirm: your email '
            'changes then. Until you do, keep signing in with $current.',
          ),
        Center(
          child: Column(
            children: [
              OptionsInputField(
                controller: _email,
                hintText: 'New email',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
              ),
              gap,
              OptionsInputField(
                controller: _password,
                hintText: 'Your password',
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
              ),
              gap,
            ],
          ),
        ),
        const SettingsNote('Your password confirms it is you.'),
      ],
    );
  }
}
