import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_buttons/default_green_button.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/my_profile_page/profile_pinned_friends_row/on_pinned_friend_tap/pinned_friends_selection_header.dart';
import 'package:later/views/widgets/user/user_round_avatar.dart';
import 'package:later/services/popup_notification_service.dart';

class ChoosePinnedFriendsDialog extends StatefulWidget {
  final List<String> pinnedUids;
  final List<String> allFriends;
  final Map<String, Map<String, String>> friendInfoMap;
  final Future<void> Function(List<String> newPinned) onSave;

  const ChoosePinnedFriendsDialog({
    super.key,
    required this.pinnedUids,
    required this.allFriends,
    required this.friendInfoMap,
    required this.onSave,
  });

  @override
  State<ChoosePinnedFriendsDialog> createState() =>
      _ChoosePinnedFriendsDialogState();
}

class _ChoosePinnedFriendsDialogState extends State<ChoosePinnedFriendsDialog> {
  late List<String> tempPinned;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tempPinned = List.from(widget.pinnedUids);
  }

  @override
  Widget build(BuildContext context) {
    final filteredFriends = widget.allFriends.where((uid) {
      final info = widget.friendInfoMap[uid];
      if (info == null) return false;
      final name = info['name']?.toLowerCase() ?? '';
      final username = info['username']?.toLowerCase() ?? '';
      return name.contains(searchQuery) || username.contains(searchQuery);
    }).toList();

    filteredFriends.sort((a, b) {
      final aPinned = tempPinned.contains(a) ? 0 : 1;
      final bPinned = tempPinned.contains(b) ? 0 : 1;
      return aPinned.compareTo(bPinned);
    });

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            PinnedFriendSelectionHeader(
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
                  final info = widget.friendInfoMap[uid] ?? {};
                  final name = info['name'] ?? '';
                  final username = info['username'] ?? '';
                  final isPinned = tempPinned.contains(uid);

                  return ListTile(
                    leading: UserRoundAvatar(userId: uid, radius: 24),
                    title: DefaultText(
                      name,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    subtitle: DefaultText(
                      '@$username',
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
              onTap: () async {
                Navigator.pop(context);
                await widget.onSave(tempPinned);
                await Future.delayed(const Duration(milliseconds: 300));
                if (mounted) {
                  PopupNotificationService.showSuccess(
                    context: context,
                    message: 'Pinned friends updated successfully!',
                    position: NotificationPosition.top,
                  );
                }
              },
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
        setState(() {
          tempPinned.add(uid);
        });
      }
    } else {
      setState(() {
        tempPinned.remove(uid);
      });
    }
  }
}
