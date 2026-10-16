import 'package:flutter/material.dart';

import '../../data/models/capsule.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/signup_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/friends/pages/qr_code_scanner_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/profile/share/share_profile_page.dart';
import '../../features/friends/pages/add_friend_profile_page.dart';
import '../../features/friends/pages/add_friends_page.dart';
import '../../features/friends/pages/friend_requests_page.dart';
import '../../features/friends/pages/my_friends_page.dart';
import '../../features/friends/pages/your_friend_profile_page.dart';
import '../../features/capsules/camera/camera_page.dart';
import '../../features/capsules/creation/capsule_creation_page.dart';
import '../../features/messages/chat_page.dart';
import 'app_link_handler.dart';
import 'app_page_route.dart';

/// Every navigation in the app goes through here. All pages use the same
/// short fade (AppMotion.fast); "Add friends" slides up like a sheet.
abstract final class AppRoutes {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState? get _nav => navigatorKey.currentState;

  /// Pops everything above the root (the auth gate).
  static void backToRoot() => _nav?.popUntil((route) => route.isFirst);

  // Auth
  static Future<void> toLogin(BuildContext context) =>
      Navigator.of(context).push(fadeRoute(const LoginPage()));

  /// From the login page: replaces it when it was pushed (welcome flow),
  /// pushes when it is the root (after a log-out).
  static Future<void> toSignupFromLogin(BuildContext context) {
    final nav = Navigator.of(context);
    final route = fadeRoute<void>(const SignupPage());
    return nav.canPop() ? nav.pushReplacement(route) : nav.push(route);
  }

  // Capsules
  /// Camera for a new capsule; with [recipientId] the capsule is sent to
  /// that friend.
  static Future<void> toCamera(
    BuildContext context, {
    CapsulePrivacy? privacy,
    String? recipientId,
    bool replace = false,
  }) {
    final route = fadeRoute<void>(
      CameraPage(initialPrivacy: privacy, recipientId: recipientId),
    );
    final nav = Navigator.of(context);
    return replace ? nav.pushReplacement(route) : nav.push(route);
  }

  /// Capsule form after taking the photo (replaces the camera route).
  static Future<void> toCapsuleCreation(
    BuildContext context, {
    required String imagePath,
    CapsulePrivacy? privacy,
    String? recipientId,
    bool replace = false,
  }) {
    final route = fadeRoute<void>(
      CapsuleCreationPage(
        imagePath: imagePath,
        initialPrivacy: privacy,
        recipientId: recipientId,
      ),
    );
    final nav = Navigator.of(context);
    return replace ? nav.pushReplacement(route) : nav.push(route);
  }

  // Profile area
  static Future<void> toSettings(BuildContext context) =>
      Navigator.of(context).push(fadeRoute(const SettingsPage()));

  static Future<void> toNotifications(BuildContext context) =>
      Navigator.of(context).push(fadeRoute(const NotificationsPage()));

  static Future<void> toShareProfile(BuildContext context) =>
      Navigator.of(context).push(fadeRoute(const ShareProfilePage()));

  // Friends
  static Future<void> toAddFriends(BuildContext context) =>
      Navigator.of(context).push(slideUpRoute(const AddFriendsPage()));

  static Future<void> toFriendRequests(BuildContext context) =>
      Navigator.of(context).push(fadeRoute(const FriendRequestsPage()));

  static Future<void> toMyFriends(BuildContext context) =>
      Navigator.of(context).push(fadeRoute(const MyFriendsPage()));

  static Future<void> toAddFriendProfile(BuildContext context, String userId) =>
      Navigator.of(
        context,
      ).push(fadeRoute(AddFriendProfilePage(userId: userId)));

  static Future<void> toFriendProfile(BuildContext context, String friendUid) =>
      Navigator.of(
        context,
      ).push(fadeRoute(YourFriendProfilePage(friendUid: friendUid)));

  // Messages
  static Future<void> toChat(BuildContext context, String friendUid) =>
      Navigator.of(context).push(fadeRoute(ChatPage(friendUid: friendUid)));

  static Future<String?> toQrScanner(BuildContext context) =>
      Navigator.of(context).push<String>(fadeRoute(const QRScannerPage()));

  /// Scans a QR code and opens the profile it links to (other codes are
  /// ignored, as before).
  static Future<void> scanProfileQr(BuildContext context) async {
    final result = await toQrScanner(context);
    if (result == null || !AppLinkHandler.isProfileLink(result)) return;
    final userId = AppLinkHandler.profileUserId(result);
    if (userId != null && context.mounted) {
      await toAddFriendProfile(context, userId);
    }
  }

  /// Profile link from outside (deep link, QR): opens the add-friend profile
  /// on top of the current screen.
  static void openProfileFromLink(String userId) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    toAddFriendProfile(context, userId);
  }
}
