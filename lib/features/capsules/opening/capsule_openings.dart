import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/models/capsule.dart';
import '../../../data/services/preferences_store.dart';

/// Which capsules an account has unwrapped on this phone (D1, D4): the first
/// open of a capsule arrives wrapped, every later one is instant.
///
/// Remembered on the phone, per account. A capsule that could already be
/// opened before this phone first asked counts as seen, so an update does
/// not wrap every capsule the user has looked at before. Your own capsule
/// arrives wrapped only when it waited for a date: one you can open at once
/// holds no surprise.
class CapsuleOpenings extends ChangeNotifier {
  CapsuleOpenings(this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final PreferencesStore _prefs;
  final DateTime Function() _clock;

  static const _openedName = 'unwrapped_capsules';
  static const _sinceName = 'unwrapped_since';

  /// How many unwrapped capsules are remembered (the oldest go first).
  static const keep = 2000;

  final Map<String, List<String>> _opened = {};
  final Map<String, DateTime> _since = {};

  /// Whether [capsule] arrives wrapped for [uid] at [now].
  bool isWrapped(Capsule capsule, String? uid, DateTime now) {
    if (uid == null || !capsule.isOpen(now)) return false;
    final mine = capsule.ownerId == uid || capsule.coAuthors.contains(uid);
    final left = capsule.createdAt;
    final openAt = capsule.openAt;
    if (mine && (left == null || openAt == null || !openAt.isAfter(left))) {
      return false;
    }
    // The moment it could first be opened.
    final ready = openAt ?? left;
    if (ready == null || !ready.isAfter(_sinceOf(uid))) return false;
    return !_openedOf(uid).contains(capsule.id);
  }

  /// [capsuleId] was unwrapped by [uid]: from now on it opens at once.
  Future<void> markOpened(String uid, String capsuleId) async {
    final opened = _openedOf(uid);
    if (opened.contains(capsuleId)) return;
    opened.add(capsuleId);
    if (opened.length > keep) opened.removeRange(0, opened.length - keep);
    notifyListeners();
    await _prefs.setString(uid, _openedName, opened.join('\n'));
  }

  List<String> _openedOf(String uid) => _opened.putIfAbsent(uid, () {
    final saved = _prefs.stringSync(uid, _openedName);
    return saved == null || saved.isEmpty ? <String>[] : saved.split('\n');
  });

  DateTime _sinceOf(String uid) => _since.putIfAbsent(uid, () {
    final saved = DateTime.tryParse(_prefs.stringSync(uid, _sinceName) ?? '');
    if (saved != null) return saved;
    final now = _clock();
    unawaited(_prefs.setString(uid, _sinceName, now.toIso8601String()));
    return now;
  });
}
