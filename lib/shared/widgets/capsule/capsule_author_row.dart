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

/// Who left a capsule (and with whom), under its title (Figma "Author"): a
/// 24 dp picture, the name in bold and "with …" after it; a tap opens the
/// profile of the one pictured. Others see it unless the author chose not to
/// be shown (`showAuthor`); the owner and the co-authors always see who
/// made it with them.
class CapsuleAuthorRow extends StatelessWidget {
  const CapsuleAuthorRow({super.key, required this.capsule, this.top = 0});

  final Capsule capsule;

  /// Space above it, only when it shows.
  final double top;

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

  /// The names [capsule] shows to the viewer ("Bob Stone", "Bob Stone with
  /// Carol", "With Carol"), or null when it shows nobody or the names are
  /// still loading. It listens to [UserDirectory]: call it from a build.
  static String? namesOf(BuildContext context, Capsule capsule) {
    final me = context.read<SessionController>().uid;
    final showOwner = shows(capsule, me);
    final others = coAuthorsShown(capsule, me);
    if (!showOwner && others.isEmpty) return null;
    final (name, withNames) = _names(context, capsule, showOwner, others);
    final l10n = context.l10n;
    if (showOwner) {
      if (name.isEmpty) return null;
      return withNames.isEmpty ? name : l10n.capsulesByWith(name, withNames);
    }
    return withNames.isEmpty ? null : l10n.capsulesWith(withNames);
  }

  /// The author's name when [capsule] shows it to the viewer, else null (also
  /// while it is loading). It listens to [UserDirectory]: call it from a
  /// build.
  static String? ownerNameOf(BuildContext context, Capsule capsule) {
    final me = context.read<SessionController>().uid;
    if (!shows(capsule, me)) return null;
    final name = context.select<UserDirectory, String>(
      (d) => d.profile(capsule.ownerId)?.name ?? '',
    );
    return name.isEmpty ? null : name;
  }

  /// The first word of [ownerNameOf], for short buttons ("Reply to Jonas").
  static String? ownerFirstNameOf(BuildContext context, Capsule capsule) =>
      ownerNameOf(context, capsule)?.split(' ').first;

  static (String, String) _names(
    BuildContext context,
    Capsule capsule,
    bool showOwner,
    List<String> others,
  ) => context.select<UserDirectory, (String, String)>(
    (d) => (
      showOwner ? d.profile(capsule.ownerId)?.name ?? '' : '',
      [
        for (final id in others) d.profile(id)?.name ?? '',
      ].where((n) => n.isNotEmpty).join(', '),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final me = context.read<SessionController>().uid;
    final owner = capsule.ownerId;
    final showOwner = shows(capsule, me);
    final others = coAuthorsShown(capsule, me);
    if (!showOwner && others.isEmpty) return const SizedBox.shrink();
    final (name, withNames) = _names(context, capsule, showOwner, others);
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
      return SizedBox(height: 24 + top);
    }
    final pictured = showOwner ? owner : others.first;
    final palette = context.palette;
    // The name in bold, the rest ("with Carol") regular and grey.
    final at = showOwner ? text.indexOf(name) : -1;
    final regular = TextStyle(
      fontFamily: kAppFontFamily,
      fontSize: 14,
      height: 1.3,
      color: palette.textSecondary,
    );
    final bold = regular.copyWith(
      fontWeight: FontWeight.bold,
      color: palette.textPrimary,
    );
    final words = at < 0
        ? TextSpan(text: text, style: regular)
        : TextSpan(
            children: [
              TextSpan(text: text.substring(0, at), style: regular),
              TextSpan(text: name, style: bold),
              TextSpan(text: text.substring(at + name.length), style: regular),
            ],
          );
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Semantics(
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
            child: Row(
              children: [
                UserRoundAvatar(userId: pictured, radius: 12),
                const SizedBox(width: 8),
                Flexible(
                  child: Text.rich(
                    words,
                    // Names of friends who made it too get a second line.
                    maxLines: withNames.isEmpty ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
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
