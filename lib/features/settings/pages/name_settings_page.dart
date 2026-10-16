import 'package:flutter/material.dart';
import 'package:later/shared/widgets/popup/popup_notification_service.dart';
import 'package:later/shared/widgets/buttons/go_back_button.dart';
import 'package:provider/provider.dart';
import 'package:later/shared/widgets/page_header.dart';
import 'package:later/shared/widgets/options/options_input_field.dart';
import 'package:later/shared/widgets/buttons/default_green_button.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/features/settings/account_settings.dart';
import 'package:later/core/theme/app_colors.dart';

class NameSettingsPage extends StatefulWidget {
  const NameSettingsPage({super.key});

  @override
  State<NameSettingsPage> createState() => _NameSettingsPageState();
}

class _NameSettingsPageState extends State<NameSettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_isSaving) return;
    final users = context.read<UserRepository>();
    final uid = context.read<SessionController>().uid!;

    setState(() => _isSaving = true);
    final failure = await AccountSettings.saveName(
      users,
      uid,
      _nameController.text,
    );
    // The page may have been closed while saving (BUG-090).
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (failure == null) {
      PopupNotificationService.showSuccess(
        context: context,
        message: 'Name updated successfully!',
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.pageBackgroundAlt,
      body: Column(
        children: [
          PageHeader(
            mainText: 'Name',
            description:
                'This is how you will be shown on Later, pick a name wisely, so your friends know you by',
            leadingButton: GoBackButton(context: context),
          ),
          Column(
            children: [
              SizedBox(height: screenHeight * 0.02),
              OptionsInputField(
                controller: _nameController,
                hintText: 'Enter new name',
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.all(screenWidth * 0.15),
        child: DefaultGreenButton(
          onTap: _saveName,
          text: 'Save',
          isLoading: _isSaving,
        ),
      ),
    );
  }
}
