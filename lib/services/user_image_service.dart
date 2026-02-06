import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

enum ProfilePlaceholderType { friendsList, pinnedFriend }

class UserImageService extends ChangeNotifier {
  final Map<String, bool> userHasAvatar = {};

  final Map<String, ValueNotifier<ImageProvider>> _profileNotifiers = {};
  final Map<String, bool> _profileLoading = {};

  final Map<String, ValueNotifier<ImageProvider>> _backgroundNotifiers = {};
  final Map<String, bool> _backgroundLoading = {};

  final Map<ProfilePlaceholderType, ImageProvider> _profilePlaceholders = {
    ProfilePlaceholderType.friendsList: const AssetImage(
      'assets/images/icons/prof_page/no_photo.png',
    ),
    ProfilePlaceholderType.pinnedFriend: const AssetImage(
      'assets/images/icons/prof_page/no_photo.png',
    ),
  };

  final ImageProvider backgroundPlaceholder = const AssetImage(
    'assets/images/icons/prof_page/background_image_placeholder.png',
  );

  ValueNotifier<ImageProvider> getProfileNotifier(
    String userId, {
    ProfilePlaceholderType placeholderType = ProfilePlaceholderType.friendsList,
  }) {
    if (_profileNotifiers.containsKey(userId)) {
      return _profileNotifiers[userId]!;
    }

    final notifier = ValueNotifier<ImageProvider>(
      _profilePlaceholders[placeholderType]!,
    );
    _profileNotifiers[userId] = notifier;

    if (!(_profileLoading[userId] ?? false)) {
      _profileLoading[userId] = true;
      _loadProfileImage(userId, notifier, placeholderType);
    }

    return notifier;
  }

  ValueNotifier<bool> getProfileLoadedNotifier(String userId) {
    final notifier = ValueNotifier<bool>(false);

    final profileNotifier = getProfileNotifier(userId);
    void listener() {
      if (profileNotifier.value is NetworkImage) {
        notifier.value = true;
        profileNotifier.removeListener(listener);
      }
    }

    profileNotifier.addListener(listener);

    listener();

    return notifier;
  }

  Future<void> _loadProfileImage(
    String userId,
    ValueNotifier<ImageProvider> notifier,
    ProfilePlaceholderType placeholderType,
  ) async {
    try {
      final ref = FirebaseStorage.instance.ref(
        'userdata/$userId/assets/images/profile_image',
      );
      final url = await ref.getDownloadURL();

      userHasAvatar[userId] = true;
      notifier.value = NetworkImage(url);
    } catch (e) {
      userHasAvatar[userId] = false;
      userHasAvatar[userId] = false;
      notifier.value = _profilePlaceholders[placeholderType]!;

      notifier.notifyListeners();
    } finally {
      _profileLoading[userId] = false;
    }
  }

  ValueNotifier<ImageProvider> getBackgroundNotifier(String userId) {
    if (_backgroundNotifiers.containsKey(userId)) {
      return _backgroundNotifiers[userId]!;
    }

    final notifier = ValueNotifier<ImageProvider>(backgroundPlaceholder);
    _backgroundNotifiers[userId] = notifier;

    if (!(_backgroundLoading[userId] ?? false)) {
      _backgroundLoading[userId] = true;
      _loadBackgroundImage(userId, notifier);
    }

    return notifier;
  }

  Future<void> _loadBackgroundImage(
    String userId,
    ValueNotifier<ImageProvider> notifier,
  ) async {
    try {
      final ref = FirebaseStorage.instance.ref(
        'userdata/$userId/assets/images/background_image',
      );
      final url = await ref.getDownloadURL();
      notifier.value = NetworkImage(url);
    } catch (e) {
      notifier.value = backgroundPlaceholder;
    } finally {
      _backgroundLoading[userId] = false;
    }
  }

  Future<void> preloadProfileImageForUser(
    String userId,
    BuildContext context,
  ) async {
    final notifier = getProfileNotifier(userId);
    if (!(notifier.value is NetworkImage)) {
      await precacheImage(notifier.value, context);
    }
  }

  Future<void> preloadBackgroundImageForUser(
    String userId,
    BuildContext context,
  ) async {
    final notifier = getBackgroundNotifier(userId);
    if (!(notifier.value is NetworkImage)) {
      await precacheImage(notifier.value, context);
    }
  }

  void onLogout() {
    for (final notifier in _profileNotifiers.values) {
      notifier.dispose();
    }
    for (final notifier in _backgroundNotifiers.values) {
      notifier.dispose();
    }

    _profileNotifiers.clear();
    _backgroundNotifiers.clear();
    _profileLoading.clear();
    _backgroundLoading.clear();

    notifyListeners();
  }
}
