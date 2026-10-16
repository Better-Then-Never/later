import 'package:flutter/material.dart';

import '../../../../data/models/friend_request.dart';
import 'add_friend_profile_main_button.dart';
import 'add_friend_profile_request_handle_button.dart';

/// The bottom button(s) of a not-yet-friend's profile for each relation.
class AddFriendProfileActionButton extends StatelessWidget {
  final FriendRelation relation;
  final bool isBusy;
  final VoidCallback onAction;
  final VoidCallback onCancel;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const AddFriendProfileActionButton({
    super.key,
    required this.relation,
    required this.isBusy,
    required this.onAction,
    required this.onCancel,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final screenWidth = screen.width;
    final screenHeight = screen.height;
    final double fontSize = screenWidth * 0.045;

    return Stack(
      children: [
        if (relation == FriendRelation.none ||
            relation == FriendRelation.self ||
            relation == FriendRelation.friends)
          Positioned(
            left: screenWidth * 0.15,
            right: screenWidth * 0.15,
            bottom: screenHeight * 0.1,
            child: AddProfileMainButton(
              width: screenWidth * 0.73,
              height: screenHeight * 0.06,
              isLoading: isBusy,
              onPressed: onAction,
              relation: relation,
              fontSize: fontSize,
            ),
          ),
        if (relation == FriendRelation.requestSent)
          Positioned(
            left: screenWidth * 0.25,
            right: screenWidth * 0.25,
            bottom: screenHeight * 0.1,
            child: AddProfileRequestHandleButton(
              text: 'Cancel',
              isCancelling: isBusy,
              onPressed: onCancel,
              width: screenWidth * 0.5,
              height: screenHeight * 0.05,
              fontSize: fontSize,
            ),
          ),
        if (relation == FriendRelation.requestReceived)
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
                    isCancelling: isBusy,
                    onPressed: onAccept,
                    width: double.infinity,
                    height: screenHeight * 0.06,
                    fontSize: fontSize,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AddProfileRequestHandleButton(
                    text: 'Reject',
                    isCancelling: isBusy,
                    onPressed: onReject,
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
