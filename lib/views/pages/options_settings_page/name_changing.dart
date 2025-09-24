import 'package:flutter/material.dart';
import 'package:later/services/cache_firebase/firebase_user_services.dart';
import 'package:later/services/appearance/notification_system.dart';
import 'package:later/views/widgets/common/premade_buttons/go_back_button.dart';
import 'package:provider/provider.dart';
import 'package:later/views/widgets/common/page_header.dart';
import 'package:later/views/widgets/common/options_elements/options_input_field.dart';
import 'package:later/views/widgets/common/default_green_button.dart';
import 'package:later/services/user_profile_data_service.dart';

class NameChangingPage extends StatefulWidget {
  const NameChangingPage({super.key});

  @override
  State<NameChangingPage> createState() => _NameChangingPageState();
}

class _NameChangingPageState extends State<NameChangingPage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final userProfile = context.read<UserProfileService>();
    final uid = context.read<FirebaseUserService>().uid;
    final newName = _nameController.text.trim();

    if (uid == null) return;
    if (newName.isEmpty) {
      UnifiedNotification.showError(
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
      UnifiedNotification.showSuccess(
        context: context,
        message: 'Name updated successfully!',
        position: NotificationPosition.center,
      );
    } else {
      UnifiedNotification.showError(
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
