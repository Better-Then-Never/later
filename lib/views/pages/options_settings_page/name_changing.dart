import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:later/services/cache_firebase/user_services.dart';
import 'package:later/services/appearance/notification_system.dart';
import 'package:later/views/widgets/common/premade_buttons/go_back_button.dart';
import 'package:provider/provider.dart';
import 'package:later/views/widgets/common/page_header.dart';

class NameChangingWidget extends StatefulWidget {
  const NameChangingWidget({super.key});

  @override
  State<NameChangingWidget> createState() => _NameChangingWidgetState();
}

class _NameChangingWidgetState extends State<NameChangingWidget> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;
  String? _error;

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
      _error = null;
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: screenHeight * 0.68),
            child: Column(
              children: [
                PageHeader(
                  mainText: 'Name',
                  description:
                      'This is how you will be shown on Later, pick a name wisely, so your friends know you by',
                  leadingButton: GoBackButton(context: context),
                ),
                SizedBox(height: screenHeight * 0.02),
                Center(
                  child: Container(
                    width: screenWidth * 0.92,
                    height: 50,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.01,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          spreadRadius: 1,
                          blurRadius: 9,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: "Enter new name",
                        errorText: _error,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.001,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: screenWidth * 0.15,
            right: screenWidth * 0.15,
            bottom: screenHeight * 0.05,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    spreadRadius: 1,
                    blurRadius: 9,
                    offset: Offset(0, 4),
                  ),
                ],
                borderRadius: BorderRadius.circular(25),
              ),
              child: SizedBox(
                width: screenWidth * 0.45,
                height: screenHeight * 0.06,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 86, 201, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isSaving ? null : _saveName,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Save",
                          style: TextStyle(
                            fontSize: screenWidth * 0.065,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Irina',
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
