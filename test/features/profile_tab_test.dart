// The profile tab (B3): capsules in numbers, "about me", the name search.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/core/errors/app_failure.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/geo_position.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/models/user_settings.dart';
import 'package:later/features/profile/widgets/profile_capsules_card.dart';
import 'package:later/features/settings/account_settings.dart';
import 'package:later/features/settings/settings_store.dart';
import 'package:later/features/users/search_name_sync.dart';
import 'package:later/features/users/user_directory.dart';
import 'package:later/shared/widgets/user/user_about_line.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';

class _Session extends ChangeNotifier implements SessionController {
  _Session(this._profile);

  UserProfile? _profile;

  set profile(UserProfile? p) {
    _profile = p;
    notifyListeners();
  }

  @override
  UserProfile? get profile => _profile;

  @override
  String? get uid => 'me';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Capsule _c(
  String id, {
  String owner = 'me',
  GeoPosition? at,
  List<String> coAuthors = const [],
}) => Capsule(
  id: id,
  ownerId: owner,
  title: id,
  privacy: CapsulePrivacy.public,
  color: CapsuleColor.red,
  location: at,
  coAuthors: coAuthors,
);

void main() {
  test('capsules, places (about 5 km apart) and those made with friends', () {
    final counts = ProfileCapsulesCard.countsFor([
      _c('a', at: const GeoPosition(52.2297, 21.0122)),
      _c('b', at: const GeoPosition(52.2301, 21.0130)), // same place
      _c('c', at: const GeoPosition(50.0647, 19.9450), coAuthors: ['bob']),
      _c('d'),
      _c('theirs', owner: 'bob', coAuthors: ['me']),
    ], 'me');
    expect(counts, (4, 2, 2));
  });

  test('"about me" is trimmed and short', () async {
    final users = FakeUserRepository()
      ..put(const UserProfile(uid: 'me', name: 'Me', username: 'me'));
    expect(await AccountSettings.saveAbout(users, 'me', '  Sunsets  '), isNull);
    expect(users.profiles['me']!.about, 'Sunsets');
    expect(
      await AccountSettings.saveAbout(users, 'me', 'x' * 101),
      isA<ValidationFailure>(),
    );
  });

  testWidgets('others see the "about me" line; nothing when there is none', (
    tester,
  ) async {
    final users = FakeUserRepository()
      ..put(
        const UserProfile(
          uid: 'zoe',
          name: 'Zoe',
          username: 'zoe',
          about: 'Collecting sunsets',
        ),
      )
      ..put(const UserProfile(uid: 'leo', name: 'Leo', username: 'leo'));
    final directory = UserDirectory(users)..attach('me');
    await directory.resolveAll(['zoe', 'leo']);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: directory,
        child: testApp(
          home: const Column(
            children: [
              UserAboutLine(userId: 'zoe'),
              UserAboutLine(userId: 'leo'),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Collecting sunsets'), findsOneWidget);
    expect(find.byType(AboutText), findsOneWidget);
  });

  group('SearchNameSync', () {
    test(
      'writes the lower-case name once, follows renames and the switch',
      () async {
        final users = FakeUserRepository()
          ..put(
            const UserProfile(
              uid: 'me',
              name: 'Anna Fischer',
              username: 'anna',
            ),
          );
        final settingsRepo = FakeSettingsRepository();
        final settings = SettingsStore(settingsRepo, utcOffsetMinutes: () => 0)
          ..attach('me');
        final session = _Session(users.profiles['me']);
        final sync = SearchNameSync(
          session: session,
          settings: settings,
          users: users,
        )..start();
        await pumpEventQueue();
        expect(users.searchNames['me'], 'anna fischer');
        expect(await users.searchByName('anna f'), hasLength(1));

        // The session sees the written profile: nothing more to do.
        session.profile = users.profiles['me'];
        await pumpEventQueue();
        expect(users.searchNames['me'], 'anna fischer');

        // Off: taken out of the name search.
        await settings.updatePrivacy(
          settings.privacy.copyWith(findByName: false),
        );
        await pumpEventQueue();
        expect(users.searchNames.containsKey('me'), isFalse);
        expect(await users.searchByName('anna'), isEmpty);
        expect(settingsRepo.docs['me']!.privacy.findByName, isFalse);
        sync.dispose();
      },
    );

    test('never indexes the loading placeholder', () async {
      final users = FakeUserRepository()
        ..put(const UserProfile(uid: 'me', name: 'Me', username: 'me'));
      final settings = SettingsStore(
        FakeSettingsRepository()..docs['me'] = const UserSettings(),
        utcOffsetMinutes: () => 0,
      )..attach('me');
      final sync = SearchNameSync(
        session: _Session(UserProfile.unknown('me')),
        settings: settings,
        users: users,
      )..start();
      await pumpEventQueue();
      expect(users.searchNames, isEmpty);
      sync.dispose();
    });
  });
}
