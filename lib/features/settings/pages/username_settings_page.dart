import 'package:flutter/material.dart';
import 'package:later/shared/widgets/popup/popup_notification_service.dart';
import 'package:provider/provider.dart';
import 'package:later/shared/widgets/page_header.dart';
import 'package:later/shared/widgets/buttons/go_back_button.dart';
import 'package:later/shared/widgets/options/options_input_field.dart';
import 'package:later/shared/widgets/buttons/default_green_button.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/features/settings/account_settings.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/core/theme/app_palette.dart';

class UsernameSettingsPage extends StatefulWidget {
  const UsernameSettingsPage({super.key});

  @override
  State<UsernameSettingsPage> createState() => _UsernameSettingsPageState();
}

class _UsernameSettingsPageState extends State<UsernameSettingsPage> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    PopupNotificationService.hide();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    if (_isSaving) return;
    final users = context.read<UserRepository>();
    final uid = context.read<SessionController>().uid!;

    setState(() => _isSaving = true);
    final failure = await AccountSettings.saveUsername(
      users,
      uid,
      _usernameController.text,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (failure == null) {
      PopupNotificationService.showSuccess(
        context: context,
        message: context.l10n.settingsUsernameUpdated,
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: context.palette.backgroundAlt,
      body: Column(
        children: [
          PageHeader(
            mainText: l10n.settingsUsername,
            description: l10n.settingsUsernameDescription,
            leadingButton: GoBackButton(context: context),
          ),
          SizedBox(height: screenHeight * 0.02),
          OptionsInputField(
            controller: _usernameController,
            hintText: l10n.settingsUsernameHint,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.all(screenWidth * 0.15),
        child: DefaultGreenButton(
          onTap: _saveUsername,
          text: l10n.commonSave,
          isLoading: _isSaving,
        ),
      ),
    );
  }
}
