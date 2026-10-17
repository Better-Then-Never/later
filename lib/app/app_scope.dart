import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/firebase/firebase_auth_repository.dart';
import '../data/firebase/firebase_capsule_repository.dart';
import '../data/firebase/firebase_chat_repository.dart';
import '../data/firebase/firebase_friends_repository.dart';
import '../data/firebase/firebase_image_storage_repository.dart';
import '../data/firebase/firebase_notification_repository.dart';
import '../data/firebase/firebase_push_token_repository.dart';
import '../data/firebase/firebase_settings_repository.dart';
import '../data/firebase/firebase_user_repository.dart';
import '../data/repositories/repositories.dart';
import '../data/services/geocoding_service.dart';
import '../data/services/location_service.dart';
import '../data/services/preferences_store.dart';
import '../data/services/profile_image_cache.dart';
import '../data/services/push_messaging_service.dart';
import '../features/history/favorites_store.dart';
import '../features/history/own_capsules_store.dart';
import '../features/friends/friends_store.dart';
import '../features/users/user_directory.dart';
import '../features/map/current_location.dart';
import '../features/map/map_focus.dart';
import '../features/messages/chats_store.dart';
import '../features/notifications/notification_router.dart';
import '../features/notifications/notifications_store.dart';
import '../features/notifications/push_registration.dart';
import '../features/settings/device_settings_store.dart';
import '../features/settings/settings_store.dart';
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
  final ChatRepository _chats = FirebaseChatRepository();
  final NotificationRepository _notifications =
      FirebaseNotificationRepository();
  final PushTokenRepository _pushTokens = FirebasePushTokenRepository();
  final ImageStorageRepository _images = FirebaseImageStorageRepository();
  final SettingsRepository _settings = FirebaseSettingsRepository();
  final _location = const LocationService();
  final _geocoding = GeocodingService();
  final _prefs = PreferencesStore();
  final _links = AppLinkHandler(onOpenProfile: AppRoutes.openProfileFromLink);
  final _push = PushMessagingService();
  final _mapFocus = MapFocus();
  final _currentLocation = CurrentLocation();
  late final _imageCache = ProfileImageCache(_images);
  late final _notificationsStore = NotificationsStore(_notifications);
  late final _ownCapsules = OwnCapsulesStore(_capsules);
  late final _favorites = FavoritesStore(_users);
  late final _directory = UserDirectory(_users);
  late final _chatsStore = ChatsStore(_chats);
  late final _settingsStore = SettingsStore(_settings);
  late final _deviceSettings = DeviceSettingsStore(_prefs);
  late final _friendsStore = FriendsStore(
    friends: _friends,
    users: _users,
    notifications: _notifications,
  );
  late final NotificationRouter _notificationRouter;

  late final SessionController _session;

  @override
  void initState() {
    super.initState();
    _session = SessionController(
      auth: _auth,
      users: _users,
      scoped: [
        _imageCache,
        _notificationsStore,
        _ownCapsules,
        _favorites,
        _directory,
        _friendsStore,
        _chatsStore,
        _settingsStore,
        _deviceSettings,
        PushRegistration(push: _push, tokens: _pushTokens),
      ],
    )..start();
    _links.init();
    // Muted chats leave the unread badge.
    _settingsStore.addListener(_syncMutedChats);
    _notificationRouter = NotificationRouter(
      push: _push,
      session: _session,
      capsules: _capsules,
      mapFocus: _mapFocus,
    )..start();
    // Push setup never blocks or breaks startup (BUG-001).
    WidgetsBinding.instance.addPostFrameCallback((_) => _push.initialize());
    _prefs.purgeLegacyGlobalKeys();
  }

  void _syncMutedChats() => _chatsStore.muted = _settingsStore.mutedChats;

  @override
  void dispose() {
    _settingsStore.removeListener(_syncMutedChats);
    _session.dispose();
    _notificationRouter.dispose();
    _push.dispose();
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
        Provider<ChatRepository>.value(value: _chats),
        Provider<NotificationRepository>.value(value: _notifications),
        Provider<PushTokenRepository>.value(value: _pushTokens),
        Provider<ImageStorageRepository>.value(value: _images),
        Provider<SettingsRepository>.value(value: _settings),
        Provider<LocationService>.value(value: _location),
        Provider<GeocodingService>.value(value: _geocoding),
        Provider<PreferencesStore>.value(value: _prefs),
        Provider<AppLinkHandler>.value(value: _links),
        ChangeNotifierProvider<SessionController>.value(value: _session),
        ChangeNotifierProvider<CurrentLocation>.value(value: _currentLocation),
        Provider<PushMessagingService>.value(value: _push),
        Provider<NotificationRouter>.value(value: _notificationRouter),
        ChangeNotifierProvider<ProfileImageCache>.value(value: _imageCache),
        ChangeNotifierProvider<NotificationsStore>.value(
          value: _notificationsStore,
        ),
        ChangeNotifierProvider<MapFocus>.value(value: _mapFocus),
        ChangeNotifierProvider<OwnCapsulesStore>.value(value: _ownCapsules),
        ChangeNotifierProvider<FavoritesStore>.value(value: _favorites),
        ChangeNotifierProvider<UserDirectory>.value(value: _directory),
        ChangeNotifierProvider<FriendsStore>.value(value: _friendsStore),
        ChangeNotifierProvider<ChatsStore>.value(value: _chatsStore),
        ChangeNotifierProvider<SettingsStore>.value(value: _settingsStore),
        ChangeNotifierProvider<DeviceSettingsStore>.value(
          value: _deviceSettings,
        ),
      ],
      child: widget.child,
    );
  }
}
