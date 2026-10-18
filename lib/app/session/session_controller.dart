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
    this.cleanupTimeout = const Duration(seconds: 5),
    this.missingProfileGrace = const Duration(seconds: 3),
  }) : _auth = auth,
       _users = users,
       _scoped = List.unmodifiable(scoped);

  final AuthRepository _auth;
  final UserRepository _users;
  final List<SessionScoped> _scoped;

  /// Longest wait for each part's sign-out cleanup.
  final Duration cleanupTimeout;

  /// How long the profile may be missing before [profileMissing] says so.
  /// Signup creates it right after the account, so a short gap is normal.
  final Duration missingProfileGrace;

  StreamSubscription<String?>? _authSub;
  StreamSubscription<UserProfile?>? _profileSub;

  SessionStatus _status = SessionStatus.unknown;
  String? _uid;
  UserProfile? _profile;
  bool _profileMissing = false;
  bool _profileFailed = false;
  Timer? _missingTimer;
  bool _signingOut = false;
  bool _signedOutByUser = false;

  SessionStatus get status => _status;
  String? get uid => _uid;

  /// Live profile of the signed-in user; null until loaded or if missing.
  UserProfile? get profile => _profile;

  /// Signed in, but `users/{uid}` does not exist (POL-002: a signup that
  /// failed half-way, a profile removed elsewhere). The app asks for a name
  /// and username instead of showing "Loading..." forever.
  bool get profileMissing => _profileMissing;

  /// Whether it is known yet if the profile exists: it has arrived, or it
  /// is [profileMissing]. Until then the app shows its launch picture, not
  /// the home screen: a first Google sign-in creates the profile after the
  /// sign-in, and the map used to show first, then "Almost there" over it,
  /// then the map again (M-07). A profile stream that fails counts as known,
  /// so the app never waits on it forever.
  bool get profileKnown =>
      _profile != null || _profileMissing || _profileFailed;

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
      _profileSub = _users
          .watchProfile(uid)
          .listen(
            (profile) {
              _profile = profile;
              _profileFailed = false;
              if (profile != null) {
                _missingTimer?.cancel();
                _missingTimer = null;
                _profileMissing = false;
              } else {
                _missingTimer ??= Timer(missingProfileGrace, () {
                  _missingTimer = null;
                  if (_profile != null || _uid != uid) return;
                  _profileMissing = true;
                  notifyListeners();
                });
              }
              notifyListeners();
            },
            onError: (Object e, StackTrace st) {
              AppLogger.warning(
                'Profile stream failed',
                error: e,
                stackTrace: st,
              );
              if (_uid != uid) return;
              _profileFailed = true;
              notifyListeners();
            },
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
    _missingTimer?.cancel();
    _missingTimer = null;
    _profileMissing = false;
    _profileFailed = false;
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
          // A cleanup that cannot finish (e.g. a Firestore write while the
          // backend is unreachable, which waits forever) must not keep the
          // user signed in (POL-003).
          await s.beforeSignOut(uid).timeout(cleanupTimeout);
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

  /// Deletes the signed-in account for good (after
  /// [AuthRepository.reauthenticate]). No client cleanup first: the server
  /// removes everything the account owned, push tokens included
  /// (functions/lib/account.js), and a failed delete leaves the user
  /// signed in with nothing removed. Throws an AppFailure on failure.
  Future<void> deleteAccount() async {
    if (_uid == null || _signingOut) return;
    _signingOut = true;
    try {
      // The welcome page follows, not the login page.
      await _auth.deleteAccount();
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
