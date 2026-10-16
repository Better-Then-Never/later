import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/users/user_directory.dart';
import '../default_text.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/l10n/l10n.dart';

/// Name above "@username" of any user, from [UserDirectory].
class UserNameAndUsername extends StatelessWidget {
  final String userId;

  final TextAlign textAlign;
  final double nameFontSize;
  final double usernameFontSize;

  /// Theme text colours when null.
  final Color? nameColor;
  final Color? usernameColor;
  final FontWeight nameFontWeight;
  final FontWeight usernameFontWeight;
  final CrossAxisAlignment crossAxisAlignment;

  const UserNameAndUsername({
    super.key,
    required this.userId,
    this.textAlign = TextAlign.center,
    this.nameFontSize = 32,
    this.usernameFontSize = 22,
    this.nameColor,
    this.usernameColor,
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
    final name = profile?.name ?? context.l10n.commonUnknownUser;
    final username = profile?.username ?? context.l10n.commonUnknownUsername;

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
            color: nameColor ?? context.palette.textPrimary,
            textAlign: textAlign,
            height: 1.0,
          ),
        ),
        DefaultText(
          '@$username',
          fontSize: usernameFontSize,
          color: usernameColor ?? context.palette.textSecondary,
          fontWeight: usernameFontWeight,
          textAlign: textAlign,
        ),
      ],
    );
  }
}
