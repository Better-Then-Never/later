import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/session/session_controller.dart';
import '../../../../core/assets/app_assets.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/friend_request.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../data/services/contacts_service.dart';
import '../../../../shared/widgets/app_sheets.dart';
import '../../../../shared/widgets/buttons/default_button_with_icon.dart';
import '../../../../shared/widgets/buttons/default_green_button.dart';
import '../../../../shared/widgets/popup/popup_notification_service.dart';
import '../../../users/user_directory.dart';
import '../../contact_suggestions_controller.dart';
import '../../friend_actions.dart';
import '../../friends_store.dart';
import 'suggested_friend_row.dart';

/// "From your contacts" on Add friends (behind [FeatureFlags]): a card that
/// says what is sent and kept, then the people found.
class FromContactsButton extends StatelessWidget {
  const FromContactsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.fromLTRB(width * 0.05, 0, width * 0.05, 12),
      child: DefaultButtonWithIcon(
        onTap: () =>
            showEdgeSheet<void>(context, (_) => const _FromContactsSheet()),
        assetPath: AppIcons.friendsBook,
        text: context.l10n.friendsFromContacts,
      ),
    );
  }
}

class _FromContactsSheet extends StatefulWidget {
  const _FromContactsSheet();

  @override
  State<_FromContactsSheet> createState() => _FromContactsSheetState();
}

class _FromContactsSheetState extends State<_FromContactsSheet> {
  late final ContactSuggestionsController _controller =
      ContactSuggestionsController(
        uid: context.read<SessionController>().uid!,
        contacts: ContactsService(),
        matches: context.read<ContactMatchRepository>(),
        directory: context.read<UserDirectory>(),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSheets.radius),
        ),
      ),
      child: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final state = _controller.state;
            final message = switch (state) {
              ContactSearch.none => l10n.friendsFromContactsNone,
              ContactSearch.tooSoon => l10n.friendsFromContactsTooSoon,
              ContactSearch.denied => l10n.friendsFromContactsDenied,
              ContactSearch.failed => l10n.friendsFromContactsFailed,
              _ => null,
            };
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: SheetHandle()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: Text(
                    l10n.friendsFromContacts,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.pageTitle(context),
                  ),
                ),
                if (state == ContactSearch.found)
                  Flexible(child: _Found(people: _controller.found))
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Text(
                      message ?? l10n.friendsFromContactsExplain,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 15,
                        height: 1.35,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                  if (state == ContactSearch.idle ||
                      state == ContactSearch.working)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        width * 0.15,
                        0,
                        width * 0.15,
                        16,
                      ),
                      child: DefaultGreenButton(
                        onTap: _controller.search,
                        text: l10n.friendsFromContactsGo,
                        isLoading: state == ContactSearch.working,
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Found extends StatelessWidget {
  const _Found({required this.people});

  final List<UserProfile> people;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final store = context.watch<FriendsStore>();
    final actions = FriendActions(
      context,
      position: NotificationPosition.bottom,
    );
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      children: [
        for (final p in people)
          SuggestedFriendRow(
            userId: p.uid,
            name: p.name,
            username: p.username,
            relation: store.relationTo(p.uid),
            onTapProfile: () =>
                store.relationTo(p.uid) == FriendRelation.friends
                ? AppRoutes.toFriendProfile(context, p.uid)
                : AppRoutes.toAddFriendProfile(context, p.uid),
            onSendRequest: () => actions.sendRequest(p.uid),
            onRemove: () => store.dismissSuggestion(p.uid),
            screenWidth: width,
          ),
      ],
    );
  }
}
