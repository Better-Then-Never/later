import 'package:flutter/material.dart';
import 'package:later/views/widgets/add_friend_profile/add_friend_profile_cancel_button.dart';
import 'package:later/views/widgets/add_friend_profile/add_friend_profile_main_button.dart';

class AddFriendProfileActionButton extends StatefulWidget {
  final bool isLoading;
  final bool isCancelling;
  final VoidCallback onCancel;
  final VoidCallback? onAction;
  final String buttonState;

  const AddFriendProfileActionButton({
    super.key,
    required this.isLoading,
    required this.isCancelling,
    required this.onCancel,
    required this.onAction,
    required this.buttonState,
  });

  @override
  State<AddFriendProfileActionButton> createState() =>
      _AddFriendProfileActionButtonState();
}

class _AddFriendProfileActionButtonState
    extends State<AddFriendProfileActionButton> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double fontSize = screenWidth * 0.045;

    return Stack(
      children: [
        if (widget.buttonState != 'pending')
          Positioned(
            left: screenWidth * 0.15,
            right: screenWidth * 0.15,
            bottom: screenHeight * 0.1,
            child: AddProfileMainButton(
              width: screenWidth * 0.73,
              height: screenHeight * 0.06,
              isLoading: widget.isLoading,
              onPressed: widget.onAction,
              buttonState: widget.buttonState,
              fontSize: fontSize,
            ),
          ),
        if (widget.buttonState == 'pending')
          Positioned(
            left: screenWidth * 0.25,
            right: screenWidth * 0.25,
            bottom: screenHeight * 0.1,
            child: AddProfileCancelButton(
              isCancelling: widget.isCancelling,
              onPressed: widget.onCancel,
              width: screenWidth * 0.5,
              height: screenHeight * 0.05,
              fontSize: fontSize,
            ),
          ),
      ],
    );
  }
}
