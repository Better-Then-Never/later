import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/buttons/default_green_button.dart';
import '../../../shared/widgets/options/options_input_field.dart';
import '../../../shared/widgets/options/options_section.dart';
import '../../../shared/widgets/options/options_settings_row.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../account_settings.dart';
import '../widgets/settings_scaffold.dart';

/// Shown instead of the app when the signed-in account has no profile
/// (POL-002): pick a name and username, or log out.
class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final session = context.read<SessionController>();
    final uid = session.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    final failure = await AccountSettings.completeProfile(
      context.read<UserRepository>(),
      context.read<AuthRepository>(),
      uid,
      name: _name.text,
      username: _username.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    // On success the profile arrives and the gate shows the app.
    if (failure != null) {
      PopupNotificationService.showError(
        context: context,
        message: failure.message,
        position: NotificationPosition.center,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final gap = SizedBox(height: screenHeight * 0.015);
    final email = context.select<SessionController, String?>((s) => s.email);
    return Scaffold(
      backgroundColor: AppColors.pageBackgroundAlt,
      body: Column(
        children: [
          const PageHeader(
            mainText: 'Almost there',
            description: 'Choose how your friends will see you',
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(top: screenHeight * 0.02),
              children: [
                if (email != null)
                  SettingsNote('Your account $email has no profile yet.'),
                Center(
                  child: Column(
                    children: [
                      OptionsInputField(
                        controller: _name,
                        hintText: 'Name',
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.next,
                      ),
                      gap,
                      OptionsInputField(
                        controller: _username,
                        hintText: 'Username',
                        autofillHints: const [AutofillHints.newUsername],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _save(),
                      ),
                      gap,
                    ],
                  ),
                ),
                OptionsSection(
                  children: [
                    OptionsSettingsRow(
                      title: 'Log Out',
                      isLast: true,
                      onTap: () => context.read<SessionController>().signOut(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.15,
          vertical: screenWidth * 0.08,
        ),
        child: DefaultGreenButton(
          onTap: _save,
          text: 'Continue',
          isLoading: _saving,
        ),
      ),
    );
  }
}
