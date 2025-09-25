import 'package:flutter/material.dart';
import 'package:later/services/popup_notification_service.dart';
import 'package:later/views/widgets/_common/premade_buttons/go_back_button.dart';
import 'package:provider/provider.dart';
import 'package:later/views/widgets/_common/default_elements/page_header.dart';
import 'package:later/views/widgets/_common/options_elements/options_input_field.dart';
import 'package:later/views/widgets/_common/default_buttons/default_green_button.dart';
import 'package:later/services/user_data_service.dart';

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
    final userProfile = context.read<UserDataService>();
    final uid = userProfile.currentLoggedInUid;
    final newName = _nameController.text.trim();

    if (newName.isEmpty) {
      PopupNotificationService.showError(
        context: context,
        message: 'Please enter a new name!',
        position: NotificationPosition.center,
      );
      return;
    }

    setState(() => _isSaving = true);
    final success = await userProfile.updateName(uid, newName);
    setState(() => _isSaving = false);

    if (success) {
      PopupNotificationService.showSuccess(
        context: context,
        message: 'Name updated successfully!',
        position: NotificationPosition.center,
      );
    } else {
      PopupNotificationService.showError(
        context: context,
        message: 'Failed to update name!',
        position: NotificationPosition.center,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
