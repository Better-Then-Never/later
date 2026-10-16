import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/login_page.dart';
import '../../features/auth/permission_gate_page.dart';
import '../../features/auth/welcome_page.dart';
import '../shell/widget_tree_wrapper_page.dart';
import '../router/app_routes.dart';
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
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case SessionStatus.signedOut:
        _permissionsGrantedFor = null;
        return session.signedOutByUser
            ? const LoginPage()
            : const WelcomePage();
      case SessionStatus.signedIn:
        final uid = session.uid!;
        if (_permissionsGrantedFor != uid) {
          return PermissionGatePage(
            key: ValueKey('gate-$uid'),
            onAllGranted: () => setState(() => _permissionsGrantedFor = uid),
          );
        }
        return WidgetTreeWrapper(key: ValueKey('home-$uid'));
    }
  }
}
