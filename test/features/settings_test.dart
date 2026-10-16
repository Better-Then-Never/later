import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/errors/app_failure.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/features/settings/account_settings.dart';

import '../fakes/fake_repositories.dart';

void main() {
  late FakeUserRepository users;

  setUp(() {
    users = FakeUserRepository()
      ..put(const UserProfile(uid: 'me', name: 'Me', username: 'me'))
      ..takenUsernames.addAll(['me', 'dave']);
  });

  group('username (BUG-083)', () {
    test('is lower-cased and trimmed before saving', () async {
      expect(
        await AccountSettings.saveUsername(users, 'me', ' NewName '),
        isNull,
      );
      expect(users.profiles['me']!.username, 'newname');
      expect(users.takenUsernames, contains('newname'));
      expect(users.takenUsernames, isNot(contains('me')));
    });

    test('invalid usernames are rejected without a write', () async {
      final failure = await AccountSettings.saveUsername(users, 'me', 'a b!');
      expect(failure, isA<ValidationFailure>());
      expect(users.profiles['me']!.username, 'me');
    });

    test('a taken username is reported', () async {
      final failure = await AccountSettings.saveUsername(users, 'me', 'Dave');
      expect(failure!.message, 'Username already taken');
    });

    test('empty input keeps the old message', () async {
      final failure = await AccountSettings.saveUsername(users, 'me', '  ');
      expect(failure!.message, 'Please enter a new username!');
    });
  });

  group('name', () {
    test('is trimmed and saved', () async {
      expect(await AccountSettings.saveName(users, 'me', '  Alice '), isNull);
      expect(users.profiles['me']!.name, 'Alice');
    });

    test('empty input keeps the old message', () async {
      final failure = await AccountSettings.saveName(users, 'me', ' ');
      expect(failure!.message, 'Please enter a new name!');
    });
  });
}
