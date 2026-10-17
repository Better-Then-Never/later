import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../data/models/friend_request.dart';
import '../../../../shared/widgets/default_text.dart';
import '../../friend_actions.dart';
import '../../friend_suggestions_controller.dart';
import '../../friends_store.dart';
import '../../../../shared/widgets/user/user_row_skeleton.dart';
import 'suggested_friend_row.dart';
import '../../../../shared/motion/app_motion_widgets.dart';

/// Search results minus the user, their friends and dismissed suggestions.
class SuggestedFriendsList extends StatelessWidget {
  const SuggestedFriendsList({
    super.key,
    required this.controller,
    required this.actions,
  });

  final FriendSuggestionsController controller;
  final FriendActions actions;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final store = context.watch<FriendsStore>();

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final error = controller.error;
        if (error != null) {
          return Center(
            child: GestureDetector(
              onTap: controller.retry,
              child: DefaultText(error.message),
            ),
          );
        }
        if (controller.isLoading && controller.results.isEmpty) {
          return ListView(
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
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
              child: DefaultText(
                controller.isSuggesting
                    ? context.l10n.friendsFindByUsernameHint
                    : context.l10n.friendsNoSuggestions,
                color: context.palette.textSecondary,
              ),
            ),
          );
        }

        // Built lazily: only the rows on screen during the page transition
        // (F-38).
        return AppStaggerScope(
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return AppStaggerItem(
                key: ValueKey(user.uid),
                index: index,
                child: SuggestedFriendRow(
                  userId: user.uid,
                  name: user.name,
                  username: user.username,
                  mutualFriends: controller.mutualCount(user.uid),
                  relation: store.relationTo(user.uid),
                  screenWidth: screenWidth,
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
              );
            },
          ),
        );
      },
    );
  }
}
