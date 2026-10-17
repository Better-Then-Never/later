// "Download my data" (B3): what goes into the file.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/chat.dart';
import 'package:later/data/models/geo_position.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/models/user_settings.dart';
import 'package:later/features/settings/data_export.dart';

void main() {
  test('profile, settings, capsules, friends, blocks and chats', () {
    final data = DataExport.build(
      profile: const UserProfile(
        uid: 'me',
        name: 'Alice',
        username: 'alice',
        about: 'Sunsets',
        favorites: {'c2'},
      ),
      email: 'alice@later.test',
      settings: const UserSettings(pinnedFriends: ['bob'], language: 'ru'),
      capsules: [
        Capsule(
          id: 'c1',
          ownerId: 'me',
          title: 'Beach',
          privacy: CapsulePrivacy.friends,
          color: CapsuleColor.blue,
          location: const GeoPosition(52.2, 21.0),
          imageUrl: 'https://example.test/c1.jpg',
          createdAt: DateTime.utc(2026, 10, 1),
          coAuthors: const ['bob'],
        ),
        const Capsule(
          id: 'c2',
          ownerId: 'bob',
          title: 'Together',
          privacy: CapsulePrivacy.private,
          color: CapsuleColor.red,
        ),
      ],
      friends: {'bob': 'Bob'},
      blocked: {'eve'},
      chats: [
        Chat(
          id: 'bob_me',
          participants: const ['bob', 'me'],
          lastMessage: 'hi',
          lastUpdated: DateTime.utc(2026, 10, 2),
        ),
      ],
      now: DateTime.utc(2026, 10, 17),
    );
    // It is valid JSON as written to the file.
    final round = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    expect(round['exportedAt'], '2026-10-17T00:00:00.000Z');
    expect(round['profile']['email'], 'alice@later.test');
    expect(round['profile']['about'], 'Sunsets');
    expect(round['settings']['pinnedFriends'], ['bob']);
    expect(round['settings']['privacy']['findByName'], isTrue);
    final capsules = round['capsules'] as List;
    expect(capsules.first['photo'], 'https://example.test/c1.jpg');
    expect(capsules.first['location'], {'latitude': 52.2, 'longitude': 21.0});
    expect(capsules.first['coAuthors'], ['bob']);
    expect(capsules.last['owner'], 'bob', reason: 'made with a friend');
    expect(round['friends'], [
      {'uid': 'bob', 'name': 'Bob'},
    ]);
    expect(round['blocked'], ['eve']);
    expect(round['chats'].single['with'], ['bob']);
  });
}
