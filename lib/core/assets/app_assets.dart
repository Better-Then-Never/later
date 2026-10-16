/// Typed access to every bundled asset. UI code must not use raw asset paths;
/// `test/core/app_assets_test.dart` checks that each path exists and that
/// every bundled file is referenced here.
abstract final class AppImages {
  static const laterLogo = 'assets/images/later_logo.png';

  static const all = [laterLogo];
}

abstract final class AppAnimations {
  static const laterLogoLoading = 'assets/animations/later_logo_loading.gif';

  static const all = [laterLogoLoading];
}

abstract final class AppIcons {
  // Auth
  static const authGoogle = 'assets/icons/auth/google.png';
  static const authFacebook = 'assets/icons/auth/facebook.png';
  static const authPasswordHidden = 'assets/icons/auth/password_hidden.png';
  static const authPasswordShown = 'assets/icons/auth/password_shown.png';

  // Camera
  static const cameraShutter = 'assets/icons/camera/shutter.png';
  static const cameraSwitch = 'assets/icons/camera/switch_camera.png';
  static const cameraFull = 'assets/icons/camera/camera_full.png';
  static const cameraFlashOff = 'assets/icons/camera/flash_off.png';
  static const cameraFlashOn = 'assets/icons/camera/flash_on.png';
  static const cameraBack = 'assets/icons/camera/back_white.png';

  // Capsule creation and history
  static const capsuleClose = 'assets/icons/capsule/close.png';
  static const capsuleLocation = 'assets/icons/capsule/location.png';
  static const capsuleMicrophone = 'assets/icons/capsule/microphone.png';
  static const capsulePinColor = 'assets/icons/capsule/pin_color.png';
  static const capsulePrivacy = 'assets/icons/capsule/privacy.png';
  static const capsuleTimer = 'assets/icons/capsule/timer.png';
  static const _capsulePinColors = {
    'red',
    'blue',
    'green',
    'yellow',
    'orange',
    'purple',
  };

  /// Push-pin icon for a capsule colour name ("red", "blue", ...). Unknown
  /// colours fall back to red, the default capsule colour.
  static String capsulePin(String colorName) {
    final name = colorName.toLowerCase();
    return 'assets/icons/capsule/pin_${_capsulePinColors.contains(name) ? name : 'red'}.png';
  }

  // Friends
  static const friendsDeleteReset = 'assets/icons/friends/delete_reset.png';
  static const friendsBook = 'assets/icons/friends/friend_book.png';
  static const friendsRequest = 'assets/icons/friends/friend_request.png';
  static const friendsRequestPage =
      'assets/icons/friends/friend_request_page.png';
  static const friendsLookFor = 'assets/icons/friends/look_for.png';
  static const friendsPending = 'assets/icons/friends/pending.png';
  static const friendsQrScan = 'assets/icons/friends/qr_scan.png';

  // History
  static const historyFilter = 'assets/icons/history/filter.png';
  static const historySort = 'assets/icons/history/sort.png';

  // Map
  static const mapPinUser = 'assets/icons/map/pin_user.png';

  /// Map marker for a capsule colour name. Unknown colours fall back to red.
  static String mapPin(String colorName) {
    final name = colorName.toLowerCase();
    return 'assets/icons/map/pin_${_capsulePinColors.contains(name) ? name : 'red'}.png';
  }

  // Messages
  static const messagesNew = 'assets/icons/messages/new_message.png';
  static const messagesChatMenu = 'assets/icons/messages/chat_menu.png';
  static const messagesSend = 'assets/icons/messages/send.png';

  // Navbar
  static const navbarAdd = 'assets/icons/navbar/add.png';
  static const navbarHistory = 'assets/icons/navbar/history.png';
  static const navbarMap = 'assets/icons/navbar/map.png';
  static const navbarMessages = 'assets/icons/navbar/messages.png';
  static const navbarProfile = 'assets/icons/navbar/profile.png';

  // Profile and shared chrome
  static const profileAddFriend = 'assets/icons/profile/add_friend.png';
  static const profileBackgroundPlaceholder =
      'assets/icons/profile/background_placeholder.png';
  static const profileChooseBackground =
      'assets/icons/profile/choose_background.png';
  static const profileChoosePhoto = 'assets/icons/profile/choose_photo.png';
  static const profileFriendSearch = 'assets/icons/profile/friend_search.png';
  static const profileMyCapsules = 'assets/icons/profile/my_capsules.png';
  static const profileMyFriends = 'assets/icons/profile/my_friends.png';
  static const profileNoPhoto = 'assets/icons/profile/no_photo.png';
  static const goBack = 'assets/icons/profile/go_back.png';
  static const goBackCircle = 'assets/icons/profile/go_back_circle.png';
  static const goBackWhite = 'assets/icons/profile/go_back_white.png';
  static const goHere = 'assets/icons/profile/go_here.png';
  static const notifications = 'assets/icons/profile/notifications.png';
  static const notificationsBlack =
      'assets/icons/profile/notifications_black.png';
  static const notificationsBlackFull =
      'assets/icons/profile/notifications_black_full.png';
  static const openMenu = 'assets/icons/profile/open_menu.png';
  static const reply = 'assets/icons/profile/reply.png';
  static const sendCapsule = 'assets/icons/profile/send_capsule.png';
  static const sendMessage = 'assets/icons/profile/send_message.png';
  static const settings = 'assets/icons/profile/settings.png';
  static const share = 'assets/icons/profile/share.png';
  static const shareBlack = 'assets/icons/profile/share_black.png';

  /// Every file under assets/icons (used by the asset test).
  static List<String> get all => [
    authGoogle,
    authFacebook,
    authPasswordHidden,
    authPasswordShown,
    cameraShutter,
    cameraSwitch,
    cameraFull,
    cameraFlashOff,
    cameraFlashOn,
    cameraBack,
    capsuleClose,
    capsuleLocation,
    capsuleMicrophone,
    capsulePinColor,
    capsulePrivacy,
    capsuleTimer,
    for (final c in _capsulePinColors) capsulePin(c),
    friendsDeleteReset,
    friendsBook,
    friendsRequest,
    friendsRequestPage,
    friendsLookFor,
    friendsPending,
    friendsQrScan,
    historyFilter,
    historySort,
    mapPinUser,
    for (final c in _capsulePinColors) mapPin(c),
    messagesNew,
    messagesChatMenu,
    messagesSend,
    navbarAdd,
    navbarHistory,
    navbarMap,
    navbarMessages,
    navbarProfile,
    profileAddFriend,
    profileBackgroundPlaceholder,
    profileChooseBackground,
    profileChoosePhoto,
    profileFriendSearch,
    profileMyCapsules,
    profileMyFriends,
    profileNoPhoto,
    goBack,
    goBackCircle,
    goBackWhite,
    goHere,
    notifications,
    notificationsBlack,
    notificationsBlackFull,
    openMenu,
    reply,
    sendCapsule,
    sendMessage,
    settings,
    share,
    shareBlack,
  ];
}
