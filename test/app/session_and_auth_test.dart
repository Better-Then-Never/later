import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/router/app_link_handler.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/core/errors/app_failure.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/features/auth/auth_controller.dart';

import '../fakes/fake_repositories.dart';

class _RecordingScope extends SessionScoped {
  final events = <String>[];

  @override
  void attach(String uid) => events.add('attach:$uid');

  @override
  void detach() => events.add('detach');

  @override
  Future<void> beforeSignOut(String uid) async =>
      events.add('beforeSignOut:$uid');
}

void main() {
  group('SessionController', () {
    late FakeAuthRepository auth;
    late FakeUserRepository users;
    late _RecordingScope scope;
    late SessionController session;

    setUp(() {
      auth = FakeAuthRepository();
      users = FakeUserRepository();
      scope = _RecordingScope();
      session = SessionController(auth: auth, users: users, scoped: [scope])
        ..start();
    });

    tearDown(() => session.dispose());

    test('starts unknown, then follows the auth state', () async {
      expect(
        SessionController(auth: auth, users: users).status,
        SessionStatus.unknown,
        reason: 'before start()',
      );
      await pumpEventQueue();
      expect(session.status, SessionStatus.signedOut);

      users.put(const UserProfile(uid: 'u1', name: 'A', username: 'a'));
      auth.emit('u1');
      await pumpEventQueue();
      expect(session.status, SessionStatus.signedIn);
      expect(session.uid, 'u1');
      expect(session.profile?.username, 'a');
      expect(scope.events, ['attach:u1']);
    });

    test('switching users detaches the previous user first', () async {
      auth.emit('u1');
      await pumpEventQueue();
      auth.emit('u2');
      await pumpEventQueue();
      expect(scope.events, ['attach:u1', 'detach', 'attach:u2']);
      expect(session.profile, isNull, reason: 'u1 profile must not leak');
    });

    test('explicit sign-out cleans up while authenticated', () async {
      auth.emit('u1');
      await pumpEventQueue();
      await session.signOut();
      await pumpEventQueue();
      expect(scope.events, ['attach:u1', 'beforeSignOut:u1', 'detach']);
      expect(session.status, SessionStatus.signedOut);
      expect(session.signedOutByUser, isTrue);
      expect(auth.signOuts, 1);
    });
  });

  group('AuthController', () {
    late FakeAuthRepository auth;
    late FakeUserRepository users;
    late AuthController controller;

    setUp(() {
      auth = FakeAuthRepository();
      users = FakeUserRepository();
      controller = AuthController(auth: auth, users: users);
    });

    test('login validates empty fields and reports clean messages', () async {
      expect(
        (await controller.login(email: '', password: 'x'))?.message,
        'Please fill in all fields',
      );
      auth.accounts['a@b.c'] = 'secret';
      auth.uidsByEmail['a@b.c'] = 'u1';
      final failure = await controller.login(email: 'a@b.c', password: 'bad');
      expect(failure, isA<AuthFailure>());
      expect(failure!.message, isNot(startsWith('Exception')));
      expect(
        await controller.login(email: ' a@b.c ', password: 'secret'),
        isNull,
      );
      expect(auth.currentUid, 'u1');
    });

    test('the page may close (and dispose it) while signing in', () async {
      auth.accounts['a@b.c'] = 'secret';
      auth.uidsByEmail['a@b.c'] = 'u1';
      final pending = controller.login(email: 'a@b.c', password: 'secret');
      controller.dispose(); // AuthGate swapped the login page out.
      expect(await pending, isNull);
    });

    test('signup normalises the username and creates the profile', () async {
      final failure = await controller.signUp(
        name: '  Alice ',
        username: ' Alice.W ',
        email: 'alice@x.io',
        password: 'pw123456',
      );
      expect(failure, isNull);
      final profile = users.profiles.values.single;
      expect(profile.username, 'alice.w');
      expect(profile.name, 'Alice');
    });

    test('signup with a taken username rolls back the new account', () async {
      users.takenUsernames.add('bob');
      final failure = await controller.signUp(
        name: 'Bob',
        username: 'bob',
        email: 'bob@x.io',
        password: 'pw123456',
      );
      expect(failure?.message, 'Username already taken');
      expect(auth.deletedUsers, 1);
      expect(auth.currentUid, isNull);
      expect(users.profiles, isEmpty);
    });

    test('signup rejects invalid usernames before creating anything', () async {
      final failure = await controller.signUp(
        name: 'X',
        username: 'a b',
        email: 'x@x.io',
        password: 'pw123456',
      );
      expect(failure, isA<ValidationFailure>());
      expect(auth.calls, isEmpty);
    });

    test('Google sign-in creates a profile with a free username', () async {
      users.takenUsernames.add('john');
      auth.googleResult = const SocialSignInResult(
        uid: 'g1',
        email: 'John@gmail.com',
        displayName: 'John Doe',
      );
      expect(await controller.signInWithGoogle(), isNull);
      final p = users.profiles['g1']!;
      expect(p.name, 'John Doe');
      expect(p.username, startsWith('john'));
      expect(p.username, isNot('john'));
    });

    test('Google sign-in keeps an existing profile untouched', () async {
      users.put(const UserProfile(uid: 'g1', name: 'Old', username: 'old'));
      auth.googleResult = const SocialSignInResult(
        uid: 'g1',
        email: 'x@gmail.com',
        displayName: 'New',
      );
      expect(await controller.signInWithGoogle(), isNull);
      expect(users.profiles['g1']!.name, 'Old');
    });

    test('cancelled Google sign-in is not an error', () async {
      expect(await controller.signInWithGoogle(), isNull);
      expect(users.profiles, isEmpty);
    });
  });

  group('AppLinkHandler', () {
    test('parses app and web profile links', () {
      expect(AppLinkHandler.profileUserId('later://profile/abc'), 'abc');
      expect(
        AppLinkHandler.profileUserId('https://later-da778.web.app/?userId=xyz'),
        'xyz',
      );
      expect(
        AppLinkHandler.profileUserId('https://evil.example/?userId=x'),
        isNull,
      );
      expect(AppLinkHandler.profileUserId('later://profile/'), isNull);
      expect(
        AppLinkHandler.profileWebLink('u1'),
        'https://later-da778.web.app/?userId=u1',
      );
    });

    test('queues a link until the home screen is ready', () {
      final opened = <String>[];
      final handler = AppLinkHandler(onOpenProfile: opened.add);
      handler.handleLink('later://profile/abc');
      expect(opened, isEmpty);
      handler.onHomeReady();
      expect(opened, ['abc']);
      handler.onHomeGone();
      handler.handleLink('later://profile/def');
      expect(opened, ['abc']);
    });
  });
}
