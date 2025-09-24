import 'package:flutter/material.dart';
import 'package:later/views/pages/friends_pages/add_friend_profile_page.dart';

class DeepLinkHandler {
  static void handleDeepLink(BuildContext context, String link) {
    try {
      final uri = Uri.parse(link);

      String? userId;

      // Handle app deep link
      if (uri.scheme == 'later' && uri.host == 'profile') {
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          userId = pathSegments[0];
        }
      }
      // Handle web URL
      else if (uri.scheme == 'https' && uri.host == 'later-da778.web.app') {
        userId = uri.queryParameters['userId'];
      }

      if (userId != null && userId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddFriendProfilePage(userId: userId!),
          ),
        );
      } else {}
    } catch (e) {
      // Handle error
    }
  }

  static bool isLaterDeepLink(String link) {
    try {
      final uri = Uri.parse(link);
      return (uri.scheme == 'later' && uri.host == 'profile') ||
          (uri.scheme == 'https' &&
              uri.host == 'later-da778.web.app' &&
              uri.queryParameters.containsKey('userId'));
    } catch (e) {
      // Handle error
      return false;
    }
  }

  static String? extractUserIdFromLink(String link) {
    try {
      final uri = Uri.parse(link);

      // App deep link format
      if (uri.scheme == 'later' && uri.host == 'profile') {
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          return pathSegments[0];
        }
      }
      // Web URL format
      else if (uri.scheme == 'https' && uri.host == 'later-da778.web.app') {
        return uri.queryParameters['userId'];
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }
}
