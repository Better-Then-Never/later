import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/users/user_directory.dart';

/// A user's name in a list row, followed by the verified badge when the
/// Later team verified the account (F-58).
class VerifiedName extends StatelessWidget {
  const VerifiedName({
    super.key,
    required this.uid,
    required this.name,
    required this.style,
    this.maxLines = 1,
  });

  final String uid;
  final String name;
  final TextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final verified = context.select<UserDirectory, bool>(
      (d) => d.profile(uid)?.verified ?? false,
    );
    final size = (style.fontSize ?? 16) * 0.85;
    return Text.rich(
      TextSpan(
        text: name,
        children: [
          if (verified)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsets.only(left: size * 0.25),
                child: Semantics(
                  label: context.l10n.profileVerified,
                  child: Icon(
                    Icons.verified,
                    size: size,
                    color: AppColors.infoBlue,
                  ),
                ),
              ),
            ),
        ],
      ),
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
