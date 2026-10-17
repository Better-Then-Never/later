import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/users/user_directory.dart';

/// The few words someone wrote about themselves, under their profile's
/// header; nothing when they wrote none.
class UserAboutLine extends StatelessWidget {
  const UserAboutLine({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final about = context.select<UserDirectory, String>(
      (d) => d.profile(userId)?.about.trim() ?? '',
    );
    if (about.isEmpty) return const SizedBox.shrink();
    return AboutText(about);
  }
}

/// The "about me" text as profiles show it.
class AboutText extends StatelessWidget {
  const AboutText(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: AppTextStyles.body.copyWith(
        fontSize: 15,
        height: 1.3,
        color: color ?? context.palette.textSecondary,
      ),
    ),
  );
}
