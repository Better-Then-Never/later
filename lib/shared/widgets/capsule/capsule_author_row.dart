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
/// the name, which opens their profile. Not shown on the user's own capsules
/// or when the author chose not to be shown (`showAuthor`).
class CapsuleAuthorRow extends StatelessWidget {
  const CapsuleAuthorRow({super.key, required this.capsule});

  final Capsule capsule;

  /// Whether [capsule] shows its author to [viewer].
  static bool shows(Capsule capsule, String? viewer) =>
      capsule.ownerId.isNotEmpty &&
      capsule.ownerId != viewer &&
      capsule.showAuthor;

  @override
  Widget build(BuildContext context) {
    final me = context.read<SessionController>().uid;
    if (!shows(capsule, me)) return const SizedBox.shrink();
    final owner = capsule.ownerId;
    final name = context.select<UserDirectory, String>(
      (d) => d.profile(owner)?.name ?? '',
    );
    if (name.isEmpty) return const SizedBox(height: 24);
    return Semantics(
      button: true,
      label: context.l10n.capsulesBy(name),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final isFriend = context.read<FriendsStore>().friendIds.contains(
            owner,
          );
          isFriend
              ? AppRoutes.toFriendProfile(context, owner)
              : AppRoutes.toAddFriendProfile(context, owner);
        },
        child: ExcludeSemantics(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32),
            child: Row(
              children: [
                UserRoundAvatar(userId: owner, radius: 11),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
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
