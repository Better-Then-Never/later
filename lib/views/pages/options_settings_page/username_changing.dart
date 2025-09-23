import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:later/services/cache_firebase/user_services.dart';
import 'package:later/services/appearance/notification_system.dart';
import 'package:provider/provider.dart';
import 'package:later/views/widgets/common/page_header.dart';
import 'package:later/views/widgets/common/premade_buttons/go_back_button.dart';
import 'package:later/views/widgets/common/options_elements/options_input_field.dart';
import 'package:later/views/widgets/common/default_green_button.dart';

class UsernameChangingWidget extends StatefulWidget {
  const UsernameChangingWidget({super.key});

  @override
  State<UsernameChangingWidget> createState() => _UsernameChangingWidgetState();
}

class _UsernameChangingWidgetState extends State<UsernameChangingWidget> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    UnifiedNotification.hide();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    final newUsername = _usernameController.text.trim();
    final normalizedUsername = newUsername.toLowerCase();

    if (newUsername.isEmpty) {
      setState(() {
        _isSaving = false;
      });
      UnifiedNotification.showError(
        context: context,
        message: 'Please enter a new username!',
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
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: normalizedUsername)
          .get();

      if (query.docs.isNotEmpty && query.docs.first.id != uid) {
        if (!mounted) return;
        setState(() {
          _isSaving = false;
        });
        UnifiedNotification.showError(
          context: context,
          message: 'Username already taken.',
          position: NotificationPosition.center,
        );
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'username': newUsername,
      });
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      UnifiedNotification.showSuccess(
        context: context,
        message: 'Username updated successfully!',
        position: NotificationPosition.center,
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      UnifiedNotification.showError(
        context: context,
        message: 'Failed to update username.',
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: screenHeight * 0.68),
            child: Column(
              children: [
                PageHeader(
                  mainText: 'Username',
                  description:
                      'This is how your friends find and add you on Later',
                  leadingButton: GoBackButton(context: context),
                ),

                SizedBox(height: screenHeight * 0.02),
                Center(
                  child: OptionsInputField(
                    controller: _usernameController,
                    hintText: 'Enter new username',
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: screenWidth * 0.15,
            right: screenWidth * 0.15,
            bottom: screenHeight * 0.03,
            child: DefaultGreenButton(
              onTap: _saveUsername,
              text: 'Save',
              isLoading: _isSaving,
            ),
          ),
        ],
      ),
    );
  }
}
