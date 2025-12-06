import 'package:flutter/material.dart';
import 'package:later/views/pages/friends_pages/add_friend_profile_page.dart';
import 'package:page_transition/page_transition.dart';

class DeepLinkService {
  static void handleDeepLink(BuildContext context, String link) {
    try {
      print('DeepLinkService: Received link: $link');
      final uri = Uri.parse(link);

      String? userId;

      if (uri.scheme == 'later' && uri.host == 'profile') {
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          userId = pathSegments[0];
        }
      } else if (uri.scheme == 'https' && uri.host == 'later-da778.web.app') {
        userId = uri.queryParameters['userId'];
      }
      print(
        'DeepLinkService: Parsed URI Scheme: ${uri.scheme}, Host: ${uri.host}, Path Segments: ${uri.pathSegments}',
      );
      if (userId != null && userId.isNotEmpty) {
        Navigator.of(context).push(
          PageTransition(
            type: PageTransitionType.fade,
            duration: const Duration(milliseconds: 10),
            reverseDuration: const Duration(milliseconds: 10),
            child: AddFriendProfilePage(userId: userId),
          ),
        );
      } else {}
    } catch (e) {}
  }

  static bool isLaterDeepLink(String link) {
    try {
      final uri = Uri.parse(link);
      return (uri.scheme == 'later' && uri.host == 'profile') ||
          (uri.scheme == 'https' &&
              uri.host == 'later-da778.web.app' &&
              uri.queryParameters.containsKey('userId'));
    } catch (e) {
      return false;
    }
  }

  static String? extractUserIdFromLink(String link) {
    try {
      final uri = Uri.parse(link);

      if (uri.scheme == 'later' && uri.host == 'profile') {
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          return pathSegments[0];
        }
      } else if (uri.scheme == 'https' && uri.host == 'later-da778.web.app') {
        return uri.queryParameters['userId'];
      }
    } catch (e) {}
    return null;
  }
}
