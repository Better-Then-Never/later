import 'package:flutter/material.dart';
import 'package:later/services/popup_notification_service.dart';
import 'package:provider/provider.dart';
import 'package:later/views/widgets/_common/default_elements/page_header.dart';
import 'package:later/views/widgets/_common/premade_buttons/go_back_button.dart';
import 'package:later/views/widgets/_common/options_elements/options_input_field.dart';
import 'package:later/views/widgets/_common/default_buttons/default_green_button.dart';
import 'package:later/services/user_data_service.dart';

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
    super.dispose();
  }

  Future<void> _saveUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) {
      PopupNotificationService.showError(
        context: context,
        message: 'Please enter a new username!',
        position: NotificationPosition.center,
      );
      return;
    }

    final uid = Provider.of<UserDataService>(
      context,
      listen: false,
    ).currentLoggedInUid;

    setState(() => _isSaving = true);

    final profileService = Provider.of<UserDataService>(context, listen: false);

    final success = await profileService.updateUsername(uid, newUsername);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      PopupNotificationService.showSuccess(
        context: context,
        message: 'Username updated successfully!',
        position: NotificationPosition.center,
      );
    } else {
      PopupNotificationService.showError(
        context: context,
        message: 'Failed to update username!',
        position: NotificationPosition.center,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          PageHeader(
            mainText: 'Username',
            description: 'This is how your friends find and add you on Later',
            leadingButton: GoBackButton(context: context),
          ),
          SizedBox(height: screenHeight * 0.02),
          OptionsInputField(
            controller: _usernameController,
            hintText: 'Enter new username',
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.all(screenWidth * 0.15),
        child: DefaultGreenButton(
          onTap: _saveUsername,
          text: 'Save',
          isLoading: _isSaving,
        ),
      ),
    );
  }
}
