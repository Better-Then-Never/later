import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/user/user_placeholder.dart';

/// A group's round picture: its own gradient (from its id, like people
/// without a photo) with the first letter of its name.
class GroupAvatar extends StatelessWidget {
  const GroupAvatar({
    super.key,
    required this.groupId,
    required this.name,
    required this.radius,
  });

  final String groupId;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter = trimmed.isEmpty
        ? ''
        : String.fromCharCodes(trimmed.runes.take(1)).toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: UserGradient.of(groupId),
        ),
        child: Text(
          letter,
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.9,
            color: AppColors.onMedia,
          ),
        ),
      ),
    );
  }
}
