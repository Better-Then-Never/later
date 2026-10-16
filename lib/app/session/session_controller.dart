import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/logging/app_logger.dart';
import '../../core/session/session_scoped.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/repositories.dart';

export '../../core/session/session_scoped.dart';

enum SessionStatus { unknown, signedOut, signedIn }

/// The single source of truth for "who is signed in".
class SessionController extends ChangeNotifier {
  SessionController({
    required AuthRepository auth,
    required UserRepository users,
    List<SessionScoped> scoped = const [],
  }) : _auth = auth,
       _users = users,
       _scoped = List.unmodifiable(scoped);

  final AuthRepository _auth;
  final UserRepository _users;
  final List<SessionScoped> _scoped;

  StreamSubscription<String?>? _authSub;
  StreamSubscription<UserProfile?>? _profileSub;

  SessionStatus _status = SessionStatus.unknown;
  String? _uid;
  UserProfile? _profile;
  bool _signingOut = false;
  bool _signedOutByUser = false;

  SessionStatus get status => _status;
  String? get uid => _uid;

  /// Live profile of the signed-in user; null until loaded or if missing.
  UserProfile? get profile => _profile;

  /// After an explicit "Log Out" the app shows the login page (not the
  /// welcome page), as it always did.
  bool get signedOutByUser => _signedOutByUser;

  String? get email => _auth.currentEmail;

  void start() {
    _authSub ??= _auth.uidChanges().listen(
      _onUidChanged,
      onError: (Object e, StackTrace st) =>
          AppLogger.error('Auth state stream failed', error: e, stackTrace: st),
    );
  }

  void _onUidChanged(String? uid) {
    if (uid == _uid && _status != SessionStatus.unknown) return;
    _detachUser();
    _uid = uid;
    if (uid == null) {
      _status = SessionStatus.signedOut;
    } else {
      _signedOutByUser = false;
      _status = SessionStatus.signedIn;
      _profileSub = _users.watchProfile(uid).listen(
        (profile) {
          _profile = profile;
          notifyListeners();
        },
        onError: (Object e, StackTrace st) => AppLogger.warning(
          'Profile stream failed',
          error: e,
          stackTrace: st,
        ),
      );
      for (final s in _scoped) {
        s.attach(uid);
      }
    }
    notifyListeners();
  }

  void _detachUser() {
    unawaited(_profileSub?.cancel());
    _profileSub = null;
    _profile = null;
    if (_uid != null) {
      for (final s in _scoped.reversed) {
        s.detach();
      }
    }
  }

  /// Signs out after letting session-scoped parts clean up while the user is
  /// still authenticated.
  Future<void> signOut() async {
    final uid = _uid;
    if (_signingOut || uid == null) return;
    _signingOut = true;
    try {
      for (final s in _scoped.reversed) {
        try {
          await s.beforeSignOut(uid);
        } catch (e, st) {
          AppLogger.warning(
            'Sign-out cleanup failed',
            error: e,
            stackTrace: st,
          );
        }
      }
      _signedOutByUser = true;
      await _auth.signOut();
    } finally {
      _signingOut = false;
    }
  }

  @override
  void dispose() {
    unawaited(_authSub?.cancel());
    _detachUser();
    super.dispose();
  }
}
