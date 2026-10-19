import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/login_page.dart';
import '../../features/auth/permission_gate_page.dart';
import '../../features/auth/welcome_page.dart';
import '../../features/settings/pages/complete_profile_page.dart';
import '../../core/assets/app_assets.dart';
import '../shell/navbar_widget.dart';
import '../shell/startup_report.dart';
import '../shell/widget_tree_wrapper_page.dart';
import '../router/app_routes.dart';
import '../../shared/widgets/splash_logo.dart';
import 'session_controller.dart';

/// Root of the navigator. Shows the right top-level screen for the session:
/// welcome/login when signed out, the permission gate, then the home shell.
/// Because it is driven by the session, sign-in, sign-out and token expiry
/// always land on the correct screen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _permissionsGrantedFor;
  SessionStatus? _lastStatus;

  /// The pictures of home's first screen: the tab bar's and the map
  /// buttons'. Decoded while the splash shows, so home's first frame has
  /// them all (the bar's white pill and the buttons drew a frame before
  /// their icons, docs/map/COLD_START.md).
  static const _firstScreen = [
    ...NavbarWidget.icons,
    AppIcons.historyFilter,
    AppIcons.mapPinUser,
  ];

  /// Home waits for them at most this long after the first frame.
  static const _imagesAtLatest = Duration(milliseconds: 150);
  bool _imagesStarted = false;
  bool _imagesDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Again for the other theme's icons (ThemedAssetBundle), never waited
    // for then.
    final images = Future.wait([
      for (final image in _firstScreen)
        precacheImage(AssetImage(image), context),
    ]);
    if (_imagesStarted) return;
    _imagesStarted = true;
    unawaited(
      images.timeout(_imagesAtLatest, onTimeout: () => const []).whenComplete(
        () {
          StartupReport.mark('shell_images');
          if (mounted) setState(() => _imagesDone = true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final status = session.status;

    if (_lastStatus == SessionStatus.signedIn &&
        status == SessionStatus.signedOut) {
      // Signed out from anywhere (log-out button, revoked token): drop every
      // screen of the previous session.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRoutes.backToRoot();
      });
    }
    _lastStatus = status;

    switch (status) {
      case SessionStatus.unknown:
        // Same picture as the native launch screen: no flash at start-up.
        return const SplashLogo();
      case SessionStatus.signedOut:
        _permissionsGrantedFor = null;
        return session.signedOutByUser
            ? const LoginPage()
            : const WelcomePage();
      case SessionStatus.signedIn:
        final uid = session.uid!;
        if (session.profileMissing) {
          return CompleteProfilePage(key: ValueKey('complete-$uid'));
        }
        // Not yet known whether the profile exists: never the home screen
        // first and "Almost there" after it (M-07).
        if (!session.profileKnown) return const SplashLogo();
        if (_permissionsGrantedFor != uid) {
          return PermissionGatePage(
            key: ValueKey('gate-$uid'),
            uid: uid,
            onAllGranted: () => setState(() => _permissionsGrantedFor = uid),
          );
        }
        if (!_imagesDone) return const SplashLogo();
        return WidgetTreeWrapper(key: ValueKey('home-$uid'));
    }
  }
}
