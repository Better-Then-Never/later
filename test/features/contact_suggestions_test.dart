// Friend suggestions from contacts (B3, behind a flag): the app's side.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/errors/app_failure.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/data/services/contacts_service.dart';
import 'package:later/features/friends/contact_suggestions_controller.dart';
import 'package:later/features/users/user_directory.dart';

import '../fakes/fake_repositories.dart';

class _Contacts extends ContactsService {
  _Contacts({this.granted = true, this.hashes = const ['h1', 'h2']})
    : super(channel: const MethodChannel('test/contacts'));

  final bool granted;
  final List<String> hashes;

  @override
  Future<bool> requestAccess() async => granted;

  @override
  Future<List<String>> emailHashes({int limit = 1000}) async => hashes;
}

class _Matches implements ContactMatchRepository {
  final sent = <List<String>>[];
  final _answers = StreamController<ContactMatches?>.broadcast();
  ContactMatches? _current;
  bool tooSoon = false;
  List<String> answer = const ['anna'];

  @override
  Future<void> requestMatches(String uid, List<String> hashes) async {
    if (tooSoon) throw const PermissionFailure('denied');
    sent.add(hashes);
    // Pending first, then the function answers a moment later.
    _current = null;
    scheduleMicrotask(
      () =>
          _answers.add(_current = ContactMatches(done: true, matches: answer)),
    );
  }

  @override
  Stream<ContactMatches?> watchMatches(String uid) =>
      seeded(() => _current, _answers.stream);
}

void main() {
  late FakeUserRepository users;

  setUp(() {
    users = FakeUserRepository()
      ..put(const UserProfile(uid: 'anna', name: 'Anna', username: 'anna'));
  });

  ContactSuggestionsController controller(
    _Contacts contacts,
    _Matches matches,
  ) => ContactSuggestionsController(
    uid: 'me',
    contacts: contacts,
    matches: matches,
    directory: UserDirectory(users),
  );

  test('sends the hashes once and shows the people found', () async {
    final matches = _Matches();
    final c = controller(_Contacts(), matches);
    await c.search();
    expect(matches.sent, [
      ['h1', 'h2'],
    ]);
    expect(c.state, ContactSearch.found);
    expect(c.found.single.name, 'Anna');
    c.dispose();
  });

  test('no access, no contacts, nobody found, too soon', () async {
    final matches = _Matches();
    final denied = controller(_Contacts(granted: false), matches);
    await denied.search();
    expect(denied.state, ContactSearch.denied);
    expect(matches.sent, isEmpty, reason: 'nothing read without access');

    final empty = controller(_Contacts(hashes: const []), matches);
    await empty.search();
    expect(empty.state, ContactSearch.none);

    final nobody = controller(_Contacts(), matches..answer = const []);
    await nobody.search();
    expect(nobody.state, ContactSearch.none);

    final again = controller(_Contacts(), matches..tooSoon = true);
    await again.search();
    expect(again.state, ContactSearch.tooSoon);
  });
}
