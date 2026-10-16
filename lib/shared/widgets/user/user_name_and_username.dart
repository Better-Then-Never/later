import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/users/user_directory.dart';
import '../../../views/widgets/_common/default_elements/default_text.dart';

/// Name above "@username" of any user, from [UserDirectory].
class UserNameAndUsername extends StatelessWidget {
  final String userId;

  final TextAlign textAlign;
  final double nameFontSize;
  final double usernameFontSize;
  final Color nameColor;
  final Color usernameColor;
  final FontWeight nameFontWeight;
  final FontWeight usernameFontWeight;
  final CrossAxisAlignment crossAxisAlignment;

  const UserNameAndUsername({
    super.key,
    required this.userId,
    this.textAlign = TextAlign.center,
    this.nameFontSize = 32,
    this.usernameFontSize = 22,
    this.nameColor = Colors.black,
    this.usernameColor = const Color.fromARGB(255, 94, 94, 94),
    this.nameFontWeight = FontWeight.bold,
    this.usernameFontWeight = FontWeight.bold,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final directory = context.watch<UserDirectory>();
    final profile = directory.profile(userId);
    if (profile == null && !directory.isResolved(userId)) {
      return Column(
        crossAxisAlignment: crossAxisAlignment,
        children: const [Center(), Center()],
      );
    }
    final name = profile?.name ?? 'Unknown User';
    final username = profile?.username ?? 'unknown';

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: crossAxisAlignment == CrossAxisAlignment.start
              ? Alignment.centerLeft
              : Alignment.center,
          child: DefaultText(
            name,
            fontSize: nameFontSize,
            fontWeight: nameFontWeight,
            color: nameColor,
            textAlign: textAlign,
            height: 1.0,
          ),
        ),
        DefaultText(
          '@$username',
          fontSize: usernameFontSize,
          color: usernameColor,
          fontWeight: usernameFontWeight,
          textAlign: textAlign,
        ),
      ],
    );
  }
}
