import 'package:flutter/material.dart';
import 'package:later/data/models/friend_request.dart';
import 'package:later/shared/styles/elevated_button_styles.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/core/theme/app_colors.dart';

class AddProfileMainButton extends StatelessWidget {
  final double width;
  final double height;
  final double fontSize;
  final bool isLoading;
  final VoidCallback? onPressed;

  final FriendRelation relation;

  const AddProfileMainButton({
    super.key,
    required this.width,
    required this.height,
    required this.isLoading,
    required this.onPressed,
    required this.relation,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 1,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
        borderRadius: BorderRadius.circular(25),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          style: ElevatedButtonStyles.roundedButtonStyle(
            color: _getButtonColor(),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : DefaultText(
                  _getButtonText(),
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }

  String _getButtonText() => switch (relation) {
    FriendRelation.self => 'My Profile',
    FriendRelation.requestSent => 'Pending',
    FriendRelation.friends => 'View Profile',
    _ => 'Add',
  };

  Color _getButtonColor() => switch (relation) {
    FriendRelation.self => AppColors.neutralButton,
    FriendRelation.requestSent => AppColors.pendingYellow,
    FriendRelation.friends => AppColors.viewProfileBlue,
    _ => AppColors.brandGreen,
  };
}
