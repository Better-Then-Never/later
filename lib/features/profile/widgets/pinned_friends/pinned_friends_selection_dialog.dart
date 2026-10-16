import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../users/user_directory.dart';
import '../../../../shared/widgets/popup/popup_notification_service.dart';
import '../../../../shared/widgets/user/user_round_avatar.dart';
import '../../../../shared/widgets/buttons/default_green_button.dart';
import '../../../../shared/widgets/default_text.dart';
import 'pinned_friends_selection_dialog_header.dart';

/// Lets the user pick up to three pinned friends. Pops with the chosen
/// uids on "Save" (null when dismissed).
class PinnedFriendsSelectionDialog extends StatefulWidget {
  final List<String> pinnedUids;
  final List<String> allFriends;

  const PinnedFriendsSelectionDialog({
    super.key,
    required this.pinnedUids,
    required this.allFriends,
  });

  @override
  State<PinnedFriendsSelectionDialog> createState() =>
      _PinnedFriendsSelectionDialogState();
}

class _PinnedFriendsSelectionDialogState
    extends State<PinnedFriendsSelectionDialog> {
  late final List<String> tempPinned = List.of(widget.pinnedUids);
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final directory = context.watch<UserDirectory>();
    final filteredFriends = widget.allFriends.where((uid) {
      final info = directory.profile(uid);
      if (info == null) return false;
      return info.name.toLowerCase().contains(searchQuery) ||
          info.username.toLowerCase().contains(searchQuery);
    }).toList();

    filteredFriends.sort((a, b) {
      final aPinned = tempPinned.contains(a) ? 0 : 1;
      final bPinned = tempPinned.contains(b) ? 0 : 1;
      return aPinned.compareTo(bPinned);
    });

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            PinnedFriendSelectionDialogHeader(
              searchController: searchController,
              onSearchControllerChanged: (query) {
                setState(() {
                  searchQuery = query.trim().toLowerCase();
                });
              },
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredFriends.length,
                itemBuilder: (context, index) {
                  final uid = filteredFriends[index];
                  final info = directory.profile(uid);
                  final isPinned = tempPinned.contains(uid);

                  return ListTile(
                    leading: UserRoundAvatar(userId: uid, radius: 24),
                    title: DefaultText(
                      info?.name ?? '',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    subtitle: DefaultText(
                      '@${info?.username ?? ''}',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    trailing: Checkbox(
                      value: isPinned,
                      activeColor: const Color.fromARGB(255, 86, 201, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      onChanged: (val) => _handleCheckboxChange(val, uid),
                    ),
                  );
                },
              ),
            ),
            DefaultGreenButton(
              padding: const EdgeInsets.all(16.0),
              onTap: () => Navigator.pop(context, List.of(tempPinned)),
              text: 'Save',
            ),
          ],
        ),
      ),
    );
  }

  void _handleCheckboxChange(bool? val, String uid) {
    if (val == true) {
      if (tempPinned.length >= 3) {
        PopupNotificationService.showError(
          context: context,
          message: 'You can only pin up to 3 friends',
          position: NotificationPosition.top,
        );
        return;
      }
      if (!tempPinned.contains(uid)) {
        setState(() => tempPinned.add(uid));
      }
    } else {
      setState(() => tempPinned.remove(uid));
    }
  }
}
