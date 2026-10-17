import 'dart:async';

import 'package:flutter/services.dart';

import '../../core/logging/app_logger.dart';

/// Parses and queues incoming links (Android intent channel, QR codes) and
/// runs them once the signed-in home screen is ready, instead of guessing
/// with fixed delays. Links are to profiles or to capsules.
class AppLinkHandler {
  AppLinkHandler({required this.onOpenProfile, this.onOpenCapsule});

  /// Opens the profile of [userId]; provided by the router.
  final void Function(String userId) onOpenProfile;

  /// Opens capsule [capsuleId] (if the user may see it); provided by the
  /// router.
  final void Function(String capsuleId)? onOpenCapsule;

  static const _channel = MethodChannel('later.app/deeplink');
  static const _webHost = 'later-da778.web.app';

  /// The link waiting for the home screen: a profile or a capsule.
  ({String? userId, String? capsuleId})? _pending;
  bool _homeReady = false;

  void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'handleDeepLink' && call.arguments is String) {
        handleLink(call.arguments as String);
      }
    });
    unawaited(_fetchInitialLink());
  }

  Future<void> _fetchInitialLink() async {
    try {
      final link = await _channel.invokeMethod<String>('getInitialLink');
      if (link != null) handleLink(link);
    } on PlatformException catch (e) {
      AppLogger.warning('Could not read the initial link', error: e);
    } on MissingPluginException {
      // Platforms without the channel (tests, iOS without the handler).
    }
  }

  /// Accepts `later://profile/<uid>` and `https://later-da778.web.app/?userId=<uid>`.
  static String? profileUserId(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null) return null;
    String? id;
    if (uri.scheme == 'later' && uri.host == 'profile') {
      id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else if (uri.scheme == 'https' && uri.host == _webHost) {
      id = uri.queryParameters['userId'];
    }
    return id == null || id.isEmpty ? null : id;
  }

  static bool isProfileLink(String link) => profileUserId(link) != null;

  static String profileWebLink(String userId) =>
      'https://$_webHost/?userId=$userId';

  /// Accepts `later://capsule/<id>` and
  /// `https://later-da778.web.app/?capsuleId=<id>`.
  static String? capsuleId(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null) return null;
    String? id;
    if (uri.scheme == 'later' && uri.host == 'capsule') {
      id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else if (uri.scheme == 'https' && uri.host == _webHost) {
      id = uri.queryParameters['capsuleId'];
    }
    return id == null || !RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(id)
        ? null
        : id;
  }

  /// The link to share for capsule [id]: a web page that opens the app.
  static String capsuleWebLink(String id) => 'https://$_webHost/?capsuleId=$id';

  void handleLink(String link) {
    final capsule = capsuleId(link);
    final user = capsule == null ? profileUserId(link) : null;
    if (capsule == null && user == null) return;
    _pending = (userId: user, capsuleId: capsule);
    _flush();
  }

  void onHomeReady() {
    _homeReady = true;
    _flush();
  }

  void onHomeGone() => _homeReady = false;

  void _flush() {
    final link = _pending;
    if (!_homeReady || link == null) return;
    _pending = null;
    if (link.capsuleId case final id?) {
      onOpenCapsule?.call(id);
    } else if (link.userId case final id?) {
      onOpenProfile(id);
    }
  }
}
