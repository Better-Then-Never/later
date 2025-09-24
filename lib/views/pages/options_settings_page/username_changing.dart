import 'package:flutter/material.dart';
import 'package:later/services/appearance/notification_system.dart';
import 'package:provider/provider.dart';
import 'package:later/views/widgets/common/page_header.dart';
import 'package:later/views/widgets/common/premade_buttons/go_back_button.dart';
import 'package:later/views/widgets/common/options_elements/options_input_field.dart';
import 'package:later/views/widgets/common/default_green_button.dart';
import 'package:later/services/user_profile_data_service.dart';
import 'package:later/services/cache_firebase/firebase_user_services.dart';

class UsernameChangingPage extends StatefulWidget {
  const UsernameChangingPage({super.key});

  @override
  State<UsernameChangingPage> createState() => _UsernameChangingPageState();
}

class _UsernameChangingPageState extends State<UsernameChangingPage> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    UnifiedNotification.hide();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) {
      UnifiedNotification.showError(
        context: context,
        message: 'Please enter a new username!',
        position: NotificationPosition.center,
      );
      return;
    }

    final uid = Provider.of<FirebaseUserService>(context, listen: false).uid;
    if (uid == null) {
      UnifiedNotification.showError(
        context: context,
        message: 'User not logged in.',
        position: NotificationPosition.center,
      );
      return;
    }

    setState(() => _isSaving = true);

    final profileService = Provider.of<UserProfileService>(
      context,
      listen: false,
    );

    final success = await profileService.updateUsername(uid, newUsername);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      UnifiedNotification.showSuccess(
        context: context,
        message: 'Username updated successfully!',
        position: NotificationPosition.center,
      );
    } else {
      UnifiedNotification.showError(
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
