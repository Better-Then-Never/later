import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:later/services/cache_firebase/user_services.dart';
import 'package:later/services/appearance/notification_system.dart';
import 'package:later/views/widgets/common/premade_buttons/go_back_button.dart';
import 'package:provider/provider.dart';
import 'package:later/views/widgets/common/page_header.dart';
import 'package:later/views/widgets/common/options_elements/options_input_field.dart';
import 'package:later/views/widgets/common/default_green_button.dart';

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
    UnifiedNotification.hide();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _isSaving = false;
      });
      UnifiedNotification.showError(
        context: context,
        message: 'Please enter a new name!',
        position: NotificationPosition.center,
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });
    final userService = Provider.of<UserService>(context, listen: false);
    final uid = userService.uid;
    if (uid == null) {
      setState(() {
        _isSaving = false;
      });
      UnifiedNotification.showError(
        context: context,
        message: 'User not logged in.',
        position: NotificationPosition.center,
      );
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': name,
      });

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
      UnifiedNotification.showSuccess(
        context: context,
        message: 'Name updated successfully!',
        position: NotificationPosition.center,
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
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
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                PageHeader(
                  mainText: 'Name',
                  description:
                      'This is how you will be shown on Later, pick a name wisely, so your friends know you by',
                  leadingButton: GoBackButton(context: context),
                ),
                SizedBox(height: screenHeight * 0.02),
                Center(
                  child: OptionsInputField(
                    controller: _nameController,
                    hintText: 'Enter new name',
                  ),
                ),
              ],
            ),
            Positioned(
              left: screenWidth * 0.15,
              right: screenWidth * 0.15,
              bottom: screenHeight * 0.03,

              child: DefaultGreenButton(
                isLoading: _isSaving,
                onTap: _saveName,
                text: 'Save',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
