import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/contacts_service.dart';
import '../users/user_directory.dart';

/// Where "From your contacts" is.
enum ContactSearch { idle, working, found, none, denied, tooSoon, failed }

/// Friends from the phone's contacts (opt-in, behind a flag): asks for
/// access, sends the hashes of the contacts' emails once, waits for the
/// server's answer and shows the people found.
class ContactSuggestionsController extends ChangeNotifier {
  ContactSuggestionsController({
    required this.uid,
    required ContactsService contacts,
    required ContactMatchRepository matches,
    required UserDirectory directory,
    this.timeout = const Duration(seconds: 30),
  }) : _contacts = contacts,
       _matches = matches,
       _directory = directory;

  final String uid;
  final ContactsService _contacts;
  final ContactMatchRepository _matches;
  final UserDirectory _directory;
  final Duration timeout;

  ContactSearch _state = ContactSearch.idle;
  List<UserProfile> _found = const [];
  bool _disposed = false;

  ContactSearch get state => _state;
  List<UserProfile> get found => _found;

  void _set(ContactSearch state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  Future<void> search() async {
    if (_state == ContactSearch.working) return;
    _set(ContactSearch.working);
    try {
      if (!await _contacts.requestAccess()) return _set(ContactSearch.denied);
      final hashes = await _contacts.emailHashes();
      if (hashes.isEmpty) return _set(ContactSearch.none);
      try {
        await _matches.requestMatches(uid, hashes);
      } on PermissionFailure {
        // The rules allow one look-up an hour.
        return _set(ContactSearch.tooSoon);
      }
      final answer = await _matches
          .watchMatches(uid)
          .firstWhere((m) => m != null && m.done)
          .timeout(timeout);
      final ids = answer!.matches;
      final profiles = await _directory.resolveAll(ids);
      _found = [
        for (final id in ids)
          if (profiles[id] case final UserProfile p) p,
      ];
      _set(_found.isEmpty ? ContactSearch.none : ContactSearch.found);
    } catch (e, st) {
      AppLogger.warning('Contact suggestions failed', error: e, stackTrace: st);
      _set(ContactSearch.failed);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
