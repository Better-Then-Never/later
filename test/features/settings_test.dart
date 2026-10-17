import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/core/errors/app_failure.dart';
import 'package:later/data/models/user_settings.dart';
import 'package:later/features/settings/account_settings.dart';
import 'package:later/features/settings/settings_store.dart';

import '../fakes/fake_repositories.dart';

void main() {
  group('SettingsStore', () {
    late FakeSettingsRepository repo;
    late SettingsStore store;

    setUp(() {
      repo = FakeSettingsRepository();
      store = SettingsStore(repo, utcOffsetMinutes: () => 120);
    });

    test('a missing document means the defaults', () async {
      store.attach('alice');
      await pumpEventQueue();
      expect(store.isLoaded, isTrue);
      expect(store.settings, const UserSettings());
      expect(repo.docs, isEmpty, reason: 'no write without quiet hours');
    });

    test('saving applies at once and stores the device offset', () async {
      store.attach('alice');
      await pumpEventQueue();
      final pending = store.updateNotifications(
        store.notifications.copyWith(messages: false),
      );
      expect(store.notifications.messages, isFalse);
      expect(await pending, isNull);
      expect(repo.docs['alice']!.notifications.messages, isFalse);
      expect(repo.docs['alice']!.notifications.utcOffsetMinutes, 120);
    });

    test('a failed save rolls back', () async {
      store.attach('alice');
      await pumpEventQueue();
      repo.failWrites = true;
      final failure = await store.updateNotifications(
        store.notifications.copyWith(enabled: false),
      );
      expect(failure, isA<PermissionFailure>());
      expect(store.notifications.enabled, isTrue);

      expect(await store.setChatMuted('a_b', muted: true), isNotNull);
      expect(store.isMuted('a_b'), isFalse);
    });

    test('mute and unmute a chat', () async {
      store.attach('alice');
      await pumpEventQueue();
      await store.setChatMuted('alice_bob', muted: true);
      await pumpEventQueue();
      expect(store.isMuted('alice_bob'), isTrue);
      expect(repo.docs['alice']!.mutedChats, {'alice_bob'});
      await store.setChatMuted('alice_bob', muted: false);
      await pumpEventQueue();
      expect(store.mutedChats, isEmpty);
    });

    test('quiet hours follow the device time zone', () async {
      repo.docs['alice'] = const UserSettings(
        notifications: NotificationSettings(
          quietHours: QuietHours(enabled: true),
          utcOffsetMinutes: 60,
        ),
      );
      store.attach('alice');
      await pumpEventQueue();
      expect(repo.docs['alice']!.notifications.utcOffsetMinutes, 120);
    });

    test('sign-out forgets the settings', () async {
      repo.docs['alice'] = const UserSettings(mutedChats: {'x'});
      store.attach('alice');
      await pumpEventQueue();
      expect(store.isMuted('x'), isTrue);
      store.detach();
      expect(store.mutedChats, isEmpty);
      expect(store.isLoaded, isFalse);
    });
  });

  group('AccountSecurity', () {
    late FakeAuthRepository auth;

    setUp(() async {
      auth = FakeAuthRepository();
      auth.accounts['a@x.test'] = 'secret1';
      auth.uidsByEmail['a@x.test'] = 'alice';
      auth.emit('alice');
    });

    test('password change validates, then confirms the old password', () async {
      Future<AppFailure?> change(String current, String next, [String? c]) =>
          AccountSecurity.changePassword(
            auth,
            current: current,
            next: next,
            confirm: c ?? next,
          );

      expect(await change('', 'newpass'), isA<ValidationFailure>());
      expect(await change('secret1', '123'), isA<ValidationFailure>());
      expect(
        await change('secret1', 'newpass', 'other'),
        isA<ValidationFailure>(),
      );
      expect(await change('secret1', 'secret1'), isA<ValidationFailure>());
      expect(auth.calls, isNot(contains('reauth')));

      expect(await change('wrong', 'newpass'), isA<AuthFailure>());
      expect(auth.accounts['a@x.test'], 'secret1');

      expect(await change('secret1', 'newpass'), isNull);
      expect(auth.accounts['a@x.test'], 'newpass');
    });

    test('email change sends the link after re-authentication', () async {
      expect(
        await AccountSecurity.changeEmail(auth, newEmail: 'bad'),
        isA<ValidationFailure>(),
      );
      expect(
        await AccountSecurity.changeEmail(
          auth,
          newEmail: 'A@x.test',
          password: 'secret1',
        ),
        isA<ValidationFailure>(),
      );
      expect(
        await AccountSecurity.changeEmail(auth, newEmail: 'b@x.test'),
        isA<ValidationFailure>(),
        reason: 'password required',
      );
      expect(
        await AccountSecurity.changeEmail(
          auth,
          newEmail: ' b@x.test ',
          password: 'secret1',
        ),
        isNull,
      );
      expect(auth.calls, containsAllInOrder(['reauth', 'email:b@x.test']));
    });

    test(
      'Google accounts confirm with the picker; closing it cancels',
      () async {
        auth.hasPassword = false;
        auth.googleReauth = null;
        var deleted = false;
        final failure = await AccountSecurity.deleteAccount(
          auth,
          () async => deleted = true,
        );
        expect(failure, isA<CancelledFailure>());
        expect(deleted, isFalse);

        auth.googleReauth = true;
        expect(
          await AccountSecurity.deleteAccount(auth, () async => deleted = true),
          isNull,
        );
        expect(deleted, isTrue);
      },
    );

    test('deleting signs out and needs the right password', () async {
      final session = SessionController(auth: auth, users: FakeUserRepository())
        ..start();
      await pumpEventQueue();
      expect(session.status, SessionStatus.signedIn);

      expect(
        await AccountSecurity.deleteAccount(
          auth,
          session.deleteAccount,
          password: 'wrong',
        ),
        isA<AuthFailure>(),
      );
      expect(session.status, SessionStatus.signedIn);

      expect(
        await AccountSecurity.deleteAccount(
          auth,
          session.deleteAccount,
          password: 'secret1',
        ),
        isNull,
      );
      await pumpEventQueue();
      expect(session.status, SessionStatus.signedOut);
      expect(session.signedOutByUser, isFalse);
      expect(auth.accounts, isEmpty);
      session.dispose();
    });
  });
}
