import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/users/user_directory.dart';

/// The colours that belong to a person (F-40): a pair of the app's own
/// colours and a diagonal, picked by their user id, so the same person
/// always looks the same and two people rarely do. Used for a missing
/// profile picture and a missing profile background.
abstract final class UserGradient {
  static const _pairs = [
    (AppColors.brandGreen, AppColors.infoBlue),
    (AppColors.viewProfileBlue, AppColors.brandGreen),
    (AppColors.warningOrange, AppColors.materialRed),
    (AppColors.placeYellow, AppColors.warningOrange),
    (AppColors.brandGreen, AppColors.placeYellow),
    (AppColors.infoBlue700, AppColors.brandGreen),
    (AppColors.redAccent, AppColors.warningOrange),
    (AppColors.infoBlue, AppColors.infoBlue700),
  ];

  static const _corners = [
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomRight,
    Alignment.bottomLeft,
  ];

  static LinearGradient of(String userId) {
    final hash = _fnv1a(userId);
    final (from, to) = _pairs[hash % _pairs.length];
    final turn = (hash >> 8) % _corners.length;
    return LinearGradient(
      begin: _corners[turn],
      end: _corners[(turn + 2) % _corners.length],
      colors: [from, to],
    );
  }

  /// FNV-1a, 32 bits: stable across runs and platforms (unlike hashCode).
  static int _fnv1a(String text) {
    var hash = 0x811c9dc5;
    for (final unit in text.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}

/// A person's picture when they have none: their gradient and the first
/// letter of their name (once the name is known).
class UserPlaceholder extends StatelessWidget {
  const UserPlaceholder({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final name = context.select<UserDirectory?, String?>(
      (directory) => directory?.profile(userId)?.name,
    );
    final initial = name == null || name.trim().isEmpty
        ? null
        : name.trim().characters.first.toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(gradient: UserGradient.of(userId)),
      child: initial == null
          ? const SizedBox.expand()
          : LayoutBuilder(
              builder: (context, box) => Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: box.biggest.shortestSide * 0.42,
                    color: AppColors.onAccent,
                    height: 1,
                  ),
                ),
              ),
            ),
    );
  }
}
