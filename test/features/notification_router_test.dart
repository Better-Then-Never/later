// Where notification taps lead (B6), and taps held until the home screen.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/data/models/app_notification.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/services/push_messaging_service.dart';
import 'package:later/features/map/map_focus.dart';
import 'package:later/features/notifications/notification_router.dart';

import '../fakes/fake_repositories.dart';

class _Push implements PushMessagingService {
  final _taps = StreamController<NotificationTap>.broadcast();
  NotificationTap? initial;

  void tap(NotificationTap t) => _taps.add(t);

  @override
  Stream<NotificationTap> get taps => _taps.stream;

  @override
  NotificationTap? takeInitialTap() {
    final t = initial;
    initial = null;
    return t;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Session extends ChangeNotifier implements SessionController {
  @override
  UserProfile? get profile => const UserProfile(
    uid: 'me',
    name: 'Me',
    username: 'me',
    friends: ['ann'],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

NotificationTap _t(
  NotificationType type, {
  String? userId,
  String? capsuleId,
  String? chatId,
}) => NotificationTap(
  type: type,
  userId: userId,
  capsuleId: capsuleId,
  chatId: chatId,
);

void main() {
  NotificationDestination? to(NotificationTap tap) =>
      NotificationRouter.destinationFor(tap, friends: {'ann'});

  test('profiles: a friend\'s page for friends, add-friend otherwise', () {
    final friend = to(_t(NotificationType.follow, userId: 'ann'));
    expect(friend, isA<ProfileDestination>());
    expect((friend! as ProfileDestination).isFriend, isTrue);
    final other = to(_t(NotificationType.friendAccepted, userId: 'bo'));
    expect((other! as ProfileDestination).isFriend, isFalse);
    expect(to(_t(NotificationType.follow)), isNull, reason: 'no user id');
    expect(
      to(_t(NotificationType.friendRequest)),
      isA<FriendRequestsDestination>(),
    );
  });

  test('capsules: a new one on the map; the others open, comments too', () {
    CapsuleDestination of(NotificationType type) =>
        to(_t(type, capsuleId: 'c1'))! as CapsuleDestination;
    expect(of(NotificationType.capsule).open, isFalse);
    expect(of(NotificationType.coAuthor).open, isTrue);
    expect(of(NotificationType.reaction).comments, isFalse);
    expect(of(NotificationType.comment).comments, isTrue);
    expect(of(NotificationType.reply).comments, isTrue);
    expect(to(_t(NotificationType.reaction)), isNull, reason: 'no capsule');
  });

  test('messages: the group, or the friend\'s chat; others go nowhere', () {
    final group = to(_t(NotificationType.message, chatId: 'g_trip1234567'));
    expect((group! as ChatDestination).groupId, 'g_trip1234567');
    final chat = to(
      _t(NotificationType.message, chatId: 'ann_me', userId: 'ann'),
    );
    expect((chat! as ChatDestination).userId, 'ann');
    expect(
      to(_t(NotificationType.achievement)),
      isA<AchievementsDestination>(),
    );
    expect(to(_t(NotificationType.other)), isNull);
  });

  test(
    'taps before the home screen wait for it; later ones go at once',
    () async {
      final push = _Push()..initial = _t(NotificationType.friendRequest);
      final went = <NotificationDestination>[];
      final router = NotificationRouter(
        push: push,
        session: _Session(),
        capsules: FakeCapsuleRepository(),
        mapFocus: MapFocus(),
        navigate: (d) async => went.add(d),
      )..start();

      push.tap(_t(NotificationType.follow, userId: 'ann'));
      await pumpEventQueue();
      expect(went, isEmpty, reason: 'no home screen yet');

      // The tap while starting replaces the one the app was opened with.
      router.onHomeReady();
      await pumpEventQueue();
      expect(went.single, isA<ProfileDestination>());

      push.tap(_t(NotificationType.achievement));
      await pumpEventQueue();
      expect(went.last, isA<AchievementsDestination>());
      await router.dispose();
    },
  );
}
