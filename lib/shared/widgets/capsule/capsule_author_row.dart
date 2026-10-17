import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/session/session_controller.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../features/friends/friends_store.dart';
import '../../../features/users/user_directory.dart';
import '../user/user_round_avatar.dart';

/// Who left a capsule (and with whom), under its title: a small picture and
/// the names; a tap opens the profile of the one pictured. Others see it
/// unless the author chose not to be shown (`showAuthor`); the owner and the
/// co-authors always see who made it with them.
class CapsuleAuthorRow extends StatelessWidget {
  const CapsuleAuthorRow({super.key, required this.capsule});

  final Capsule capsule;

  /// Whether [capsule] shows its author to [viewer].
  static bool shows(Capsule capsule, String? viewer) =>
      capsule.ownerId.isNotEmpty &&
      capsule.ownerId != viewer &&
      (capsule.showAuthor || capsule.coAuthors.contains(viewer));

  /// The co-authors [viewer] sees named on [capsule] (never themselves).
  static List<String> coAuthorsShown(Capsule capsule, String? viewer) {
    final insider =
        capsule.ownerId == viewer || capsule.coAuthors.contains(viewer);
    if (!capsule.showAuthor && !insider) return const [];
    return [
      for (final id in capsule.coAuthors)
        if (id != viewer) id,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<SessionController>().uid;
    final owner = capsule.ownerId;
    final showOwner = shows(capsule, me);
    final others = coAuthorsShown(capsule, me);
    if (!showOwner && others.isEmpty) return const SizedBox.shrink();
    final (name, withNames) = context.select<UserDirectory, (String, String)>(
      (d) => (
        showOwner ? d.profile(owner)?.name ?? '' : '',
        [
          for (final id in others) d.profile(id)?.name ?? '',
        ].where((n) => n.isNotEmpty).join(', '),
      ),
    );
    final l10n = context.l10n;
    final String text;
    final String label;
    if (showOwner) {
      text = withNames.isEmpty ? name : l10n.capsulesByWith(name, withNames);
      label = withNames.isEmpty ? l10n.capsulesBy(name) : text;
    } else {
      text = withNames.isEmpty ? '' : l10n.capsulesWith(withNames);
      label = text;
    }
    if (text.isEmpty || (showOwner && name.isEmpty)) {
      return const SizedBox(height: 24);
    }
    final pictured = showOwner ? owner : others.first;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final isFriend = context.read<FriendsStore>().friendIds.contains(
            pictured,
          );
          isFriend
              ? AppRoutes.toFriendProfile(context, pictured)
              : AppRoutes.toAddFriendProfile(context, pictured);
        },
        child: ExcludeSemantics(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32),
            child: Row(
              children: [
                UserRoundAvatar(userId: pictured, radius: 11),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    text,
                    // Names of friends who made it too get a second line.
                    maxLines: withNames.isEmpty ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: context.palette.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
