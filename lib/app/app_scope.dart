import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/firebase/firebase_auth_repository.dart';
import '../data/firebase/firebase_capsule_repository.dart';
import '../data/firebase/firebase_friends_repository.dart';
import '../data/firebase/firebase_image_storage_repository.dart';
import '../data/firebase/firebase_notification_repository.dart';
import '../data/firebase/firebase_push_token_repository.dart';
import '../data/firebase/firebase_user_repository.dart';
import '../data/repositories/repositories.dart';
import '../data/services/geocoding_service.dart';
import '../data/services/location_service.dart';
import '../data/services/preferences_store.dart';
import '../services/capsule_data_service.dart';
import '../services/map_capsule_jump_service.dart';
import '../services/push_notification_service.dart';
import '../services/user_data_service.dart';
import '../services/user_favorite_capsules_service.dart';
import '../services/user_friends_service.dart';
import '../services/user_image_service.dart';
import 'router/app_link_handler.dart';
import 'router/app_routes.dart';
import 'session/session_controller.dart';

/// Composition root: creates every repository, service and session-scoped
/// store once and provides them to the widget tree.
class AppScope extends StatefulWidget {
  const AppScope({super.key, required this.child});

  final Widget child;

  @override
  State<AppScope> createState() => _AppScopeState();
}

class _AppScopeState extends State<AppScope> {
  // Repositories and services.
  final AuthRepository _auth = FirebaseAuthRepository();
  final UserRepository _users = FirebaseUserRepository();
  final FriendsRepository _friends = FirebaseFriendsRepository();
  final CapsuleRepository _capsules = FirebaseCapsuleRepository();
  final NotificationRepository _notifications =
      FirebaseNotificationRepository();
  final PushTokenRepository _pushTokens = FirebasePushTokenRepository();
  final ImageStorageRepository _images = FirebaseImageStorageRepository();
  final _location = const LocationService();
  final _geocoding = GeocodingService();
  final _prefs = PreferencesStore();
  final _links = AppLinkHandler(onOpenProfile: AppRoutes.openProfileFromLink);

  // Legacy per-user services, reset by the session until they are replaced.
  final _legacyUserData = UserDataService();
  final _legacyFriends = UserFriendsService();
  final _legacyCapsules = CapsuleDataService();
  final _legacyFavorites = FavoriteCapsuleService();
  final _legacyImages = UserImageService();
  final _jump = CapsuleJumpService();

  late final SessionController _session;

  @override
  void initState() {
    super.initState();
    _session = SessionController(
      auth: _auth,
      users: _users,
      scoped: [
        _LegacyServicesScope(
          userData: _legacyUserData,
          friends: _legacyFriends,
          capsules: _legacyCapsules,
          favorites: _legacyFavorites,
          images: _legacyImages,
        ),
      ],
    )..start();
    _links.init();
    _prefs.purgeLegacyGlobalKeys();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: _auth),
        Provider<UserRepository>.value(value: _users),
        Provider<FriendsRepository>.value(value: _friends),
        Provider<CapsuleRepository>.value(value: _capsules),
        Provider<NotificationRepository>.value(value: _notifications),
        Provider<PushTokenRepository>.value(value: _pushTokens),
        Provider<ImageStorageRepository>.value(value: _images),
        Provider<LocationService>.value(value: _location),
        Provider<GeocodingService>.value(value: _geocoding),
        Provider<PreferencesStore>.value(value: _prefs),
        Provider<AppLinkHandler>.value(value: _links),
        ChangeNotifierProvider<SessionController>.value(value: _session),
        // Legacy services (removed feature by feature).
        ChangeNotifierProvider.value(value: _legacyUserData),
        ChangeNotifierProvider.value(value: _legacyFriends),
        ChangeNotifierProvider.value(value: _legacyCapsules),
        ChangeNotifierProvider.value(value: _legacyFavorites),
        ChangeNotifierProvider.value(value: _legacyImages),
        ChangeNotifierProvider.value(value: _jump),
        ChangeNotifierProvider.value(value: PushNotificationService()),
      ],
      child: widget.child,
    );
  }
}

/// Resets the pre-refactor singletons when the user changes.
class _LegacyServicesScope extends SessionScoped {
  _LegacyServicesScope({
    required this.userData,
    required this.friends,
    required this.capsules,
    required this.favorites,
    required this.images,
  });

  final UserDataService userData;
  final UserFriendsService friends;
  final CapsuleDataService capsules;
  final FavoriteCapsuleService favorites;
  final UserImageService images;

  @override
  void attach(String uid) {
    friends.init();
  }

  @override
  void detach() {
    userData.onLogout();
    friends.onLogout();
    capsules.onLogout();
    favorites.onLogout();
    images.onLogout();
  }
}
