import 'package:flutter/widgets.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/services/user_image_service.dart';

class SuggestedFriendsListController {
  final UserDataService userService;
  final UserImageService imageService;
  final BuildContext context;

  SuggestedFriendsListController({
    required this.userService,
    required this.imageService,
    required this.context,
  });

  final Map<String, Map<String, dynamic>> readyUsers = {};
  final Set<String> loadingUserIds = {};

  Future<void> loadUser(String userId, VoidCallback onUpdate) async {
    if (loadingUserIds.contains(userId)) return;
    loadingUserIds.add(userId);

    try {
      final userData = await userService.getUserData(userId);
      final profileNotifier = imageService.getProfileNotifier(userId);

      Future<void> markReady() async {
        final provider = profileNotifier.value;
        if (provider is NetworkImage) {
          await precacheImage(provider, context);
        }
        readyUsers[userId] = userData;
        loadingUserIds.remove(userId);
        onUpdate();
      }

      // Always listen to the notifier
      void listener() async {
        final provider = profileNotifier.value;
        final avatarExists = imageService.userHasAvatar[userId];

        // ✅ If network image loaded OR placeholder for no avatar → ready
        if (provider is NetworkImage || (avatarExists == false)) {
          profileNotifier.removeListener(listener);
          await markReady();
        }
      }

      profileNotifier.addListener(listener);

      // Call listener immediately in case value was already updated
      listener();
    } catch (_) {
      loadingUserIds.remove(userId);
      onUpdate();
    }
  }
}