import 'package:flutter/material.dart';
import 'package:later/views/widgets/add_friend_profile/add_friend_profile_request_handle_button.dart';
import 'package:later/views/widgets/add_friend_profile/add_friend_profile_main_button.dart';

class AddFriendProfileActionButton extends StatelessWidget {
  final bool isLoading;
  final bool isCancelling;
  final VoidCallback onCancel;
  final VoidCallback? onAction;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final String buttonState;

  const AddFriendProfileActionButton({
    super.key,
    required this.isLoading,
    required this.isCancelling,
    required this.onCancel,
    required this.onAction,
    this.onAccept,
    this.onReject,
    required this.buttonState,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double fontSize = screenWidth * 0.045;

    return Stack(
      children: [
        if (buttonState == 'add' ||
            buttonState == 'own_profile' ||
            buttonState == 'friends')
          Positioned(
            left: screenWidth * 0.15,
            right: screenWidth * 0.15,
            bottom: screenHeight * 0.1,
            child: AddProfileMainButton(
              width: screenWidth * 0.73,
              height: screenHeight * 0.06,
              isLoading: isLoading,
              onPressed: onAction,
              buttonState: buttonState,
              fontSize: fontSize,
            ),
          ),

        if (buttonState == 'pending')
          Positioned(
            left: screenWidth * 0.25,
            right: screenWidth * 0.25,
            bottom: screenHeight * 0.1,
            child: AddProfileRequestHandleButton(
              text: 'Cancel',
              isCancelling: isCancelling,
              onPressed: onCancel,
              width: screenWidth * 0.5,
              height: screenHeight * 0.05,
              fontSize: fontSize,
            ),
          ),

        if (buttonState == 'received')
          Positioned(
            left: screenWidth * 0.1,
            right: screenWidth * 0.1,
            bottom: screenHeight * 0.1,
            child: Row(
              children: [
                Expanded(
                  child: AddProfileRequestHandleButton(
                    text: 'Accept',
                    color: const Color.fromARGB(255, 86, 201, 46),
                    isCancelling: isCancelling,
                    onPressed: onAccept ?? () {},
                    width: double.infinity,
                    height: screenHeight * 0.06,
                    fontSize: fontSize,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AddProfileRequestHandleButton(
                    text: 'Reject',
                    isCancelling: isCancelling,
                    onPressed: onReject ?? () {},
                    width: double.infinity,
                    height: screenHeight * 0.06,
                    fontSize: fontSize,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
