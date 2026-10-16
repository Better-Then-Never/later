import 'dart:async';

import 'package:flutter/services.dart';

import '../../core/logging/app_logger.dart';

/// Parses and queues incoming links (Android intent channel, QR codes) and
/// runs them once the signed-in home screen is ready, instead of guessing
/// with fixed delays.
class AppLinkHandler {
  AppLinkHandler({required this.onOpenProfile});

  /// Opens the profile of [userId]; provided by the router.
  final void Function(String userId) onOpenProfile;

  static const _channel = MethodChannel('later.app/deeplink');
  static const _webHost = 'later-da778.web.app';

  String? _pendingUserId;
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

  void handleLink(String link) {
    final id = profileUserId(link);
    if (id == null) return;
    _pendingUserId = id;
    _flush();
  }

  void onHomeReady() {
    _homeReady = true;
    _flush();
  }

  void onHomeGone() => _homeReady = false;

  void _flush() {
    final id = _pendingUserId;
    if (!_homeReady || id == null) return;
    _pendingUserId = null;
    onOpenProfile(id);
  }
}
