import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/count_badge.dart';
import '../../../shared/widgets/user/user_stamp.dart';
import '../../../shared/widgets/v2/card_v2.dart';
import '../../friends/friends_store.dart';
import '../../users/user_directory.dart';
import '../notification_groups.dart';

/// The waiting friend requests in one card on top of the notifications
/// (Profile v4): the first requesters' stamps, "2 friend requests", who
/// asked, a count; a tap opens the friend requests page. Nothing when no
/// request waits.
class FriendRequestsCard extends StatelessWidget {
  const FriendRequestsCard({super.key, this.onTap});

  /// Instead of opening the friend requests page (tests).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // The store replaces the set when the requests change.
    final from = context.select<FriendsStore, Set<String>>(
      (s) => s.receivedFrom,
    );
    if (from.isEmpty) return const SizedBox.shrink();
    return _Card(from: from.toList(), onTap: onTap);
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.from, this.onTap});

  final List<String> from;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final directory = context.watch<UserDirectory>();
    final names = [for (final uid in from) directory.profile(uid)?.name ?? ''];
    final who = friendRequestNames(names, l10n);
    final title = l10n.notificationsFriendRequests(from.length);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CardV2(
        child: Semantics(
          button: true,
          label: who == null ? title : '$title. $who',
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap ?? () => AppRoutes.toFriendRequests(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              child: Row(
                children: [
                  _Stamps(from: from),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 16,
                            height: 1.25,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                        if (who != null)
                          Text(
                            who,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 13,
                              height: 1.25,
                              color: palette.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  CountBadge(count: from.length, size: 22),
                  const SizedBox(width: 10),
                  Image.asset(AppIcons.goHere, width: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The first two requesters' stamps, overlapping, tilted apart.
class _Stamps extends StatelessWidget {
  const _Stamps({required this.from});

  final List<String> from;

  static const _size = 40.0;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 68,
    height: 52,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        if (from.length > 1)
          Positioned(
            right: 0,
            top: 0,
            child: UserStamp(userId: from[1], size: _size, tilt: 5),
          ),
        Positioned(
          left: 0,
          bottom: 0,
          child: UserStamp(userId: from[0], size: _size, tilt: -6),
        ),
      ],
    ),
  );
}
