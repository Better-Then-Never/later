import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/friend_request.dart';
import '../../../../shared/widgets/user/user_row_skeleton.dart';
import '../../../../shared/widgets/v2/card_v2.dart';
import '../../friend_actions.dart';
import '../../friend_suggestions_controller.dart';
import '../../friends_store.dart';
import '../friend_stamp.dart';
import 'suggested_friend_row.dart';

/// Suggestions (friends of friends) or search results, minus the user,
/// their friends and dismissed suggestions: a label and a card of rows,
/// laid out in the page's own scroll view.
class SuggestedFriendsList extends StatelessWidget {
  const SuggestedFriendsList({
    super.key,
    required this.controller,
    required this.actions,
    required this.label,
  });

  final FriendSuggestionsController controller;
  final FriendActions actions;

  /// Above the card ("People you may know", "Found").
  final String label;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final store = context.watch<FriendsStore>();
    final palette = context.palette;

    Widget note(String text, {VoidCallback? onTap}) => GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            fontSize: 15,
            height: 1.35,
            color: palette.textSecondary,
          ),
        ),
      ),
    );

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final error = controller.error;
        if (error != null) {
          return note(error.message, onTap: controller.retry);
        }
        if (controller.isLoading && controller.results.isEmpty) {
          return Column(
            children: [
              for (var i = 0; i < 3; i++)
                UserRowSkeleton(screenWidth: screenWidth),
            ],
          );
        }

        final users = controller.results.where((u) {
          final relation = store.relationTo(u.uid);
          return relation != FriendRelation.self &&
              relation != FriendRelation.friends &&
              !store.dismissed.contains(u.uid);
        }).toList();

        if (users.isEmpty) {
          return note(
            controller.isSuggesting
                ? context.l10n.friendsFindByUsernameHint
                : context.l10n.friendsNoSuggestions,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GroupLabelV2(label),
            CardV2Rows(
              indent: PersonRowV2.indentFor(46),
              children: [
                for (final user in users)
                  SuggestedFriendRow(
                    key: ValueKey(user.uid),
                    userId: user.uid,
                    name: user.name,
                    username: user.username,
                    mutualFriends: controller.mutualCount(user.uid),
                    relation: store.relationTo(user.uid),
                    onTapProfile: () =>
                        AppRoutes.toAddFriendProfile(context, user.uid),
                    // A received request is accepted from here (BUG-070).
                    onSendRequest: () =>
                        store.relationTo(user.uid) ==
                            FriendRelation.requestReceived
                        ? actions.acceptRequest(user.uid)
                        : actions.sendRequest(user.uid),
                    onRemove: () => actions.dismissSuggestion(user.uid),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
