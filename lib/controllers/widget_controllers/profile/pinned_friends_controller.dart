import 'package:flutter/material.dart';
import 'package:later/views/pages/friends_pages/your_friend_profile_page.dart';
import 'package:later/views/widgets/my_profile_page/my_friends_panel/profile_pinned_friends_row/on_pinned_friend_tap/pinned_friends_selection_dialog.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:later/services/firebase_storage_service.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/services/user_friends_service.dart';

class PinnedFriendsController extends ChangeNotifier {
  final UserFriendsService friendsService;
  final UserDataService userDataService;

  Set<String> pinnedUids = {};
  Set<String> allFriends = {};
  Map<String, Map<String, String>> friendInfoMap = {};
  Map<String, String?> pinnedImages = {};
  bool isLoading = true;

  PinnedFriendsController({
    required this.friendsService,
    required this.userDataService,
  }) {
    friendsService.addListener(_loadFriends);
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    isLoading = true;
    notifyListeners();

    allFriends = friendsService.friends.toSet();

    Map<String, Map<String, String>> infoMap = {};
    for (var uid in allFriends) {
      final data = await userDataService.getUserData(uid);
      infoMap[uid] = {
        'name': data['name'] ?? '',
        'username': data['username'] ?? '',
      };
    }
    friendInfoMap = infoMap;

    final prefs = await SharedPreferences.getInstance();
    final pinnedList = prefs.getStringList('pinned_friend_uids') ?? [];
    pinnedUids = pinnedList.toSet();

    Map<String, String?> images = {};
    for (var uid in pinnedUids) {
      images[uid] = await FirebaseStorageService.getProfileImageUrl(uid);
    }
    pinnedImages = images;

    isLoading = false;
    notifyListeners();
  }

  Future<void> setPinnedFriends(List<String> uids) async {
    pinnedUids = uids.take(3).toSet();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pinned_friend_uids', pinnedUids.toList());

    for (var uid in pinnedUids) {
      if (!pinnedImages.containsKey(uid)) {
        pinnedImages[uid] = await FirebaseStorageService.getProfileImageUrl(
          uid,
        );
      }
    }
    notifyListeners();
  }

  Future<List<Map<String, String>>> getDisplayFriends() async {
    if (allFriends.isEmpty) return [];

    List<Map<String, String>> widgets = [];

    for (var uid in pinnedUids) {
      if (allFriends.contains(uid)) {
        widgets.add({'uid': uid, 'imageUrl': pinnedImages[uid] ?? ''});
      }
    }

    final slotsLeft = 3 - widgets.length;
    if (slotsLeft > 0) {
      final nonPinned = allFriends.difference(pinnedUids).toList();
      nonPinned.shuffle();

      for (var uid in nonPinned.take(slotsLeft)) {
        final imageUrl = await FirebaseStorageService.getProfileImageUrl(uid);
        widgets.add({'uid': uid, 'imageUrl': imageUrl ?? ''});
      }
    }

    print('allFriends: $allFriends');
    print('pinnedUids: $pinnedUids');
    print('getDisplayFriends output: $widgets');

    return widgets;
  }

  Future<void> showChoosePinnedFriendsDialog(BuildContext context) async {
    Navigator.pop(context);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withAlpha(128),
      builder: (_) => PinnedFriendsSelectionDialog(
        pinnedUids: pinnedUids.toList(),
        allFriends: allFriends.toList(),
        friendInfoMap: friendInfoMap,
        onSave: (newPinned) async {
          await setPinnedFriends(newPinned);
        },
      ),
    );
  }

  void openFriendPage(BuildContext context, String friendUid) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.fade,
        duration: const Duration(milliseconds: 10),
        reverseDuration: const Duration(milliseconds: 10),
        child: YourFriendProfilePage(friendUid: friendUid),
      ),
    );
  }

  @override
  void dispose() {
    friendsService.removeListener(_loadFriends);
    super.dispose();
  }
}
