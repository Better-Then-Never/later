import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/firebase/firestore_mappers.dart';
import 'package:later/data/models/app_notification.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/friend_request.dart';
import 'package:later/data/models/geo_position.dart';
import 'package:later/data/models/user_profile.dart';

void main() {
  group('capsule', () {
    test('maps a complete document', () {
      final created = DateTime(2026, 1, 2, 3, 4);
      final opens = DateTime(2027, 1, 1);
      final c = FirestoreMappers.capsule('c1', {
        'ownerId': 'u1',
        'imageUrl': 'https://x/y.jpg',
        'title': 'Hello',
        'description': 'World',
        'location': const GeoPoint(1.5, 2.5),
        'privacy': 'public',
        'createdAt': Timestamp.fromDate(created),
        'isScheduled': true,
        'openAt': Timestamp.fromDate(opens),
        'color': 'purple',
      });
      expect(c.id, 'c1');
      expect(c.ownerId, 'u1');
      expect(c.location, const GeoPosition(1.5, 2.5));
      expect(c.privacy, CapsulePrivacy.public);
      expect(c.color, CapsuleColor.purple);
      expect(c.createdAt, created);
      expect(c.openAt, opens);
      expect(c.isOpen(DateTime(2026, 6, 1)), isFalse);
      expect(c.isOpen(DateTime(2027, 6, 1)), isTrue);
    });

    test('tolerates missing and unknown fields (legacy documents)', () {
      final c = FirestoreMappers.capsule('c2', {
        'creatorId': 'legacy-owner',
        'privacy': 'everyone',
        'color': 'pink',
        'description': '',
        'location': 'not a geopoint',
      });
      expect(c.ownerId, 'legacy-owner');
      expect(c.title, 'Untitled');
      expect(c.privacy, CapsulePrivacy.friends);
      expect(c.color, CapsuleColor.red);
      expect(c.description, isNull);
      expect(c.location, isNull);
      expect(c.createdAt, isNull);
      expect(c.isOpen(DateTime.now()), isTrue, reason: 'no openAt = opened');
    });

    test('new capsule map uses a server timestamp and enum names', () {
      final map = FirestoreMappers.newCapsule(
        const CapsuleDraft(
          ownerId: 'u1',
          title: 'T',
          privacy: CapsulePrivacy.friends,
          color: CapsuleColor.green,
          location: GeoPosition(10, 20),
          imagePath: '/tmp/a.jpg',
        ),
        imageUrl: 'https://img',
      );
      expect(map['privacy'], 'friends');
      expect(map['color'], 'green');
      expect(map['createdAt'], isA<FieldValue>());
      expect(map['location'], const GeoPoint(10, 20));
      expect(map['openAt'], isNull);
      expect(map['isScheduled'], isFalse, reason: 'no open date (BUG-057)');
      expect(map.containsKey('creatorId'), isFalse);
    });
  });

  group('notification', () {
    test('keeps only network avatar URLs', () {
      final legacyAsset = FirestoreMappers.notification('n1', {
        'type': 'follow',
        'fromUserAvatar': 'assets/images/icons/prof_page/no_photo.png',
      });
      final empty = FirestoreMappers.notification('n2', {
        'type': 'capsule',
        'fromUserAvatar': '',
      });
      final url = FirestoreMappers.notification('n3', {
        'fromUserAvatar': 'https://a/b.png',
      });
      expect(legacyAsset.fromUserAvatarUrl, isNull);
      expect(empty.fromUserAvatarUrl, isNull);
      expect(url.fromUserAvatarUrl, 'https://a/b.png');
    });

    test('maps types; pending timestamp is null', () {
      final n = FirestoreMappers.notification('n1', {
        'type': 'follow',
        'fromUserName': 'bob',
        'message': 'started following you',
        'isRead': false,
      });
      expect(n.type, NotificationType.follow);
      expect(n.timestamp, isNull);
      expect(
        FirestoreMappers.notification('x', {}).type,
        NotificationType.other,
      );
      expect(FirestoreMappers.notification('x', {}).fromUserName, 'Later');
    });
  });

  test('user profile defaults and initial', () {
    final p = FirestoreMappers.userProfile('u1', {
      'name': '',
      'friends': ['a', 3, 'b'],
    });
    expect(p.username, 'unknown');
    expect(p.friends, ['a', 'b']);
    expect(p.initial, '#', reason: 'empty names must not crash grouping');
    expect(FirestoreMappers.userProfile('u2', null).name, 'Unknown user');
  });

  test('friend request ids and status', () {
    final r = FirestoreMappers.friendRequest({
      'fromUserId': 'a',
      'toUserId': 'b',
      'status': 'accepted',
    });
    expect(r.id, 'a_b');
    expect(r.status, FriendRequestStatus.accepted);
  });

  group('usernames', () {
    test('normalize, validate, sanitize', () {
      expect(Usernames.normalize('  Alice.W '), 'alice.w');
      expect(Usernames.validate('alice.w'), isNull);
      expect(Usernames.validate('al'), isNotNull);
      expect(Usernames.validate('with space'), isNotNull);
      expect(Usernames.sanitize('John+Doe@x'), 'johndoex');
      expect(Usernames.sanitize('a'), 'a00');
    });
  });
}
