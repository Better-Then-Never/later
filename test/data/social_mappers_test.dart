import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/firebase/firestore_mappers.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/geo_position.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/models/user_settings.dart';

/// The fields added for reactions, comments, achievements, privacy and loop
/// capsules: read tolerantly, written only when they differ from the default.
void main() {
  group('settings', () {
    test('a missing document is all defaults (as functions/lib/prefs.js)', () {
      final s = FirestoreMappers.userSettings(null);
      expect(s.notifications.friendRequests, isTrue);
      expect(s.notifications.news, isTrue);
      expect(s.notifications.streakReminder, isFalse);
      expect(s.privacy, const PrivacySettings());
      expect(s.privacy.defaultVisibility, CapsulePrivacy.public);
      expect(s.language, isNull);
    });

    test('reads the added categories, privacy and language', () {
      final s = FirestoreMappers.userSettings({
        'notifications': {
          'reactions': false,
          'comments': false,
          'streakReminder': true,
          'news': 'yes', // wrong type: default
        },
        'privacy': {
          'defaultVisibility': 'friends',
          'readReceipts': false,
          'locationPrecision': 'approximate',
          'contactSuggestions': true,
        },
        'language': 'pl',
      });
      expect(s.notifications.reactions, isFalse);
      expect(s.notifications.comments, isFalse);
      expect(s.notifications.streakReminder, isTrue);
      expect(s.notifications.news, isTrue);
      expect(s.privacy.defaultVisibility, CapsulePrivacy.friends);
      expect(s.privacy.readReceipts, isFalse);
      expect(s.privacy.locationPrecision, LocationPrecision.approximate);
      expect(s.privacy.contactSuggestions, isTrue);
      expect(s.language, 'pl');
    });

    test('round-trips notifications and privacy', () {
      const n = NotificationSettings(
        friendRequests: false,
        achievements: false,
        streakReminder: true,
      );
      const p = PrivacySettings(
        defaultVisibility: CapsulePrivacy.private,
        locationPrecision: LocationPrecision.approximate,
      );
      final back = FirestoreMappers.userSettings({
        'notifications': FirestoreMappers.notificationSettings(n),
        'privacy': FirestoreMappers.privacySettings(p),
      });
      expect(back.notifications, n);
      expect(back.privacy, p);
    });

    test('the legacy key list matches what was added', () {
      final keys = FirestoreMappers.notificationSettings(
        const NotificationSettings(),
      ).keys.toSet();
      expect(keys.containsAll(FirestoreMappers.notificationKeysAdded), isTrue);
    });
  });

  group('profile', () {
    test('reads counters, badge and stats; never negative', () {
      final p = FirestoreMappers.userProfile('u1', {
        'name': 'Ann',
        'username': 'ann',
        'verified': true,
        'followerCount': 12,
        'followingCount': -1,
        'showAchievements': false,
        'stats': {
          'capsules': 40,
          'places': 7,
          'distanceKm': 123.4,
          'streakCurrent': 3,
          'streakLongest': 9,
          'streakLastDay': '2026-10-16',
        },
      });
      expect(p.verified, isTrue);
      expect(p.followerCount, 12);
      expect(p.followingCount, 0);
      expect(p.showAchievements, isFalse);
      expect(p.stats.capsules, 40);
      expect(p.stats.places, 7);
      expect(p.stats.distanceKm, 123.4);
      expect(p.stats.streakLongest, 9);
    });

    test('old documents get zeros and visible achievements', () {
      final p = FirestoreMappers.userProfile('u1', {'name': 'A'});
      expect(p.verified, isFalse);
      expect(p.followerCount, 0);
      expect(p.showAchievements, isTrue);
      expect(p.stats, const UserStats());
    });

    test('a streak counts until a whole day passes without a capsule', () {
      const s = UserStats(streakCurrent: 4, streakLastDay: '2026-10-16');
      expect(s.streakAt(DateTime(2026, 10, 16, 23)), 4);
      expect(s.extendedToday(DateTime(2026, 10, 16, 23)), isTrue);
      expect(s.streakAt(DateTime(2026, 10, 17, 9)), 4);
      expect(s.extendedToday(DateTime(2026, 10, 17, 9)), isFalse);
      expect(s.streakAt(DateTime(2026, 10, 18, 0, 1)), 0);
    });
  });

  group('capsule', () {
    test('reads the added fields', () {
      final taken = DateTime(2026, 10, 1, 7, 30);
      final c = FirestoreMappers.capsule('c1', {
        'ownerId': 'u1',
        'title': 'Loop',
        'location': const GeoPoint(52.2, 21.0),
        'privacy': 'public',
        'color': 'blue',
        'capturedAt': Timestamp.fromDate(taken),
        'utcOffsetMinutes': 120,
        'showAuthor': false,
        'allowComments': false,
        'locationPrecision': 'approximate',
        'frames': ['https://a/1.jpg', 'https://a/2.jpg', 'file:///local.jpg'],
        'frameDelayMs': 5000,
        'thumbUrl': 'https://a/t.jpg',
        'placeName': 'Old Town',
        'reactionCounts': {'heart': 3, 'fire': 1, 'unknown': 9, 'sad': 0},
        'reactionTotal': 4,
        'commentCount': 2,
      });
      expect(c.capturedAt, taken);
      expect(c.takenAt, taken);
      expect(c.utcOffsetMinutes, 120);
      expect(c.showAuthor, isFalse);
      expect(c.allowComments, isFalse);
      expect(c.allowReactions, isTrue);
      expect(c.locationPrecision, LocationPrecision.approximate);
      expect(c.frames, ['https://a/1.jpg', 'https://a/2.jpg']);
      expect(c.isLoop, isTrue);
      expect(c.frameDelayMs, 2000);
      expect(c.reactionCounts, {ReactionType.heart: 3, ReactionType.fire: 1});
      expect(c.reactionTotal, 4);
      expect(c.commentCount, 2);
      expect(c.placeName, 'Old Town');
    });

    test('invalid places are not placed (F-18)', () {
      for (final bad in const [GeoPoint(0, 0), GeoPoint(0.00001, 0)]) {
        final c = FirestoreMappers.capsule('c', {
          'ownerId': 'u',
          'location': bad,
        });
        expect(c.location, isNull);
      }
    });

    test('older capsules keep the defaults', () {
      final c = FirestoreMappers.capsule('c2', {'ownerId': 'u1'});
      expect(c.capturedAt, isNull);
      expect(c.showAuthor, isTrue);
      expect(c.allowReactions, isTrue);
      expect(c.frames, isEmpty);
      expect(c.isLoop, isFalse);
      expect(c.frameDelayMs, Capsule.defaultFrameDelayMs);
      expect(c.reactionCounts, isEmpty);
    });

    CapsuleDraft draft({
      bool allowComments = true,
      LocationPrecision precision = LocationPrecision.exact,
    }) => CapsuleDraft(
      ownerId: 'u1',
      title: 'T',
      privacy: CapsulePrivacy.public,
      color: CapsuleColor.red,
      location: const GeoPosition(1, 2),
      imagePath: '/tmp/x.jpg',
      capturedAt: DateTime(2026, 10, 1),
      utcOffsetMinutes: 2000,
      allowComments: allowComments,
      locationPrecision: precision,
      placeName: '  ',
    );

    test('a new capsule writes only non-default added fields', () {
      final m = FirestoreMappers.newCapsule(draft(), imageUrl: 'https://i');
      expect(m['capturedAt'], Timestamp.fromDate(DateTime(2026, 10, 1)));
      expect(m['utcOffsetMinutes'], 840);
      expect(m.containsKey('showAuthor'), isFalse);
      expect(m.containsKey('allowComments'), isFalse);
      expect(m.containsKey('locationPrecision'), isFalse);
      expect(m.containsKey('frames'), isFalse);
      expect(m.containsKey('placeName'), isFalse);

      final off = FirestoreMappers.newCapsule(
        draft(allowComments: false, precision: LocationPrecision.approximate),
        imageUrl: 'https://i',
        frameUrls: ['https://1', 'https://2'],
      );
      expect(off['allowComments'], isFalse);
      expect(off['locationPrecision'], 'approximate');
      expect(off['frames'], ['https://1', 'https://2']);
      expect(off['frameDelayMs'], Capsule.defaultFrameDelayMs);
    });

    test('the legacy shape drops every added field', () {
      final m = FirestoreMappers.newCapsule(
        draft(allowComments: false),
        imageUrl: 'https://i',
        frameUrls: ['https://1', 'https://2'],
      );
      final legacy = FirestoreMappers.legacyCapsule(m);
      expect(
        legacy.keys.toSet().intersection(FirestoreMappers.capsuleFieldsAdded),
        isEmpty,
      );
      expect(legacy['title'], 'T');
      expect(legacy['imageUrl'], 'https://i');
      // First only the newest go; the frames stay.
      final latest = FirestoreMappers.withoutLatest(m);
      expect(latest['frames'], ['https://1', 'https://2']);
      expect(
        latest.keys.toSet().intersection(
          FirestoreMappers.capsuleFieldsAddedLatest,
        ),
        isEmpty,
      );
    });
  });

  group('social', () {
    test('reactions with an unknown type are skipped', () {
      expect(
        FirestoreMappers.reaction('u1', {'type': 'heart'})?.type,
        ReactionType.heart,
      );
      expect(FirestoreMappers.reaction('u1', {'type': 'poop'}), isNull);
    });

    test('comments and replies', () {
      final c = FirestoreMappers.comment('cap', 'c1', {
        'authorId': 'u2',
        'text': 'Nice',
        'replyTo': 'c0',
      });
      expect(c.capsuleId, 'cap');
      expect(c.authorId, 'u2');
      expect(c.replyTo, 'c0');
      expect(c.createdAt, isNull);
      final m = FirestoreMappers.newComment(authorId: 'u2', text: 'Hi');
      expect(m.containsKey('replyTo'), isFalse);
      expect(m['createdAt'], isA<FieldValue>());
    });

    test('achievements and announcements', () {
      final a = FirestoreMappers.achievement('streak', {
        'tier': 2,
        'tiers': 5,
        'value': 14,
      });
      expect(a.tier, 2);
      expect(a.tiers, 5);
      final n = FirestoreMappers.announcement('a1', {
        'title': {'en': 'Hello', 'de': 'Hallo', 'pl': ''},
        'body': {'en': 'Body'},
      });
      expect(n.titleIn('de'), 'Hallo');
      expect(n.titleIn('pl'), 'Hello');
      expect(n.bodyIn('ru'), 'Body');
    });
  });
}
