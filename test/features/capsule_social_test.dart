import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/errors/app_failure.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/social.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/services/profile_image_cache.dart';
import 'package:later/features/capsules/social/capsule_comments_sheet.dart';
import 'package:later/features/capsules/social/capsule_social_controller.dart';
import 'package:later/features/capsules/social/capsule_social_panel.dart';
import 'package:later/features/users/user_directory.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';

const _capsule = Capsule(
  id: 'cap',
  ownerId: 'owner',
  title: 'Beach',
  privacy: CapsulePrivacy.public,
  color: CapsuleColor.blue,
);

void main() {
  late FakeSocialRepository social;

  setUp(() => social = FakeSocialRepository());

  CapsuleSocialController open({String uid = 'me', Capsule? capsule}) =>
      CapsuleSocialController(
        capsule: capsule ?? _capsule,
        uid: uid,
        social: social,
      );

  group('CapsuleSocialController', () {
    test('a reaction toggles and replaces; counts include everyone', () async {
      social.reactions['cap'] = {
        'a': ReactionType.heart,
        'b': ReactionType.heart,
        'c': ReactionType.fire,
      };
      final c = open();
      await pumpEventQueue();
      expect(c.counts, {ReactionType.heart: 2, ReactionType.fire: 1});
      expect(c.myReaction, isNull);

      expect(await c.react(ReactionType.heart), isNull);
      await pumpEventQueue();
      expect(c.myReaction, ReactionType.heart);
      expect(c.counts[ReactionType.heart], 3);

      await c.react(ReactionType.wow);
      await pumpEventQueue();
      expect(c.myReaction, ReactionType.wow);
      expect(c.counts[ReactionType.heart], 2);
      expect(c.counts[ReactionType.wow], 1);

      await c.react(ReactionType.wow);
      await pumpEventQueue();
      expect(c.myReaction, isNull, reason: 'the same reaction removes it');
      expect(social.reactions['cap']!.containsKey('me'), isFalse);
      c.dispose();
    });

    test('a failed reaction rolls back and reports', () async {
      final c = open();
      await pumpEventQueue();
      social.failWrites = true;
      final failure = await c.react(ReactionType.clap);
      expect(failure, isA<AppFailure>());
      expect(c.myReaction, isNull);
      c.dispose();
    });

    test('comments: replies follow their comment; one level', () async {
      final c = open();
      await pumpEventQueue();
      await c.addComment('first');
      await c.addComment('second');
      await pumpEventQueue();
      final first = c.comments.first;
      await c.addComment('re: first', replyTo: first.id);
      await pumpEventQueue();
      expect(c.thread.map((x) => x.text), ['first', 're: first', 'second']);
      expect(c.commentCount, 3);
      expect(await c.addComment('   '), isNull, reason: 'blank: nothing sent');
      expect(
        await c.addComment('x' * 501),
        isA<ValidationFailure>(),
        reason: 'the rules accept 500 characters',
      );
      c.dispose();
    });

    test('authors and the capsule owner may delete', () async {
      final mine = open();
      final owner = open(uid: 'owner');
      await mine.addComment('hi');
      await pumpEventQueue();
      final comment = mine.comments.single;
      expect(mine.canDelete(comment), isTrue);
      expect(owner.canDelete(comment), isTrue);
      expect(open(uid: 'stranger').canDelete(comment), isFalse);
      expect(await owner.deleteComment(comment), isNull);
      await pumpEventQueue();
      expect(mine.comments, isEmpty);
      mine.dispose();
      owner.dispose();
    });

    test('a report records what and why', () async {
      final c = open();
      await c.report(
        target: ReportTarget.capsule,
        targetPath: 'capsules/cap',
        reason: ReportReason.spam,
      );
      expect(social.reports.single['reason'], ReportReason.spam);
      c.dispose();
    });
  });

  group('widgets', () {
    Widget host(Widget child) {
      final users = FakeUserRepository()
        ..put(const UserProfile(uid: 'me', name: 'Me', username: 'me'))
        ..put(const UserProfile(uid: 'zoe', name: 'Zoe', username: 'zoe'));
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserDirectory(users)),
          ChangeNotifierProvider(
            create: (_) => ProfileImageCache(
              FakeImageStorageRepository(),
              evict: (_) async {},
            ),
          ),
        ],
        child: testApp(
          home: Scaffold(body: Center(child: child)),
        ),
      );
    }

    testWidgets('the panel reacts and opens the comments', (tester) async {
      social.comments['cap'] = [
        const CapsuleComment(
          id: 'c1',
          capsuleId: 'cap',
          authorId: 'zoe',
          text: 'Lovely place',
        ),
      ];
      final c = open();
      await tester.pumpWidget(host(CapsuleSocialPanel(controller: c)));
      await tester.pumpAndSettle();
      expect(find.text('1 comment'), findsOneWidget);

      await tester.tap(find.text('🔥'));
      await tester.pumpAndSettle();
      expect(social.reactions['cap']!['me'], ReactionType.fire);
      expect(find.text('1'), findsOneWidget, reason: 'count next to 🔥');

      await tester.tap(find.text('1 comment'));
      await tester.pumpAndSettle();
      expect(find.byType(CapsuleCommentsSheet), findsOneWidget);
      expect(find.text('Lovely place'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Thanks!');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(social.comments['cap']!.last.text, 'Thanks!');
      expect(find.text('Thanks!'), findsOneWidget);
      c.dispose();
    });

    testWidgets('no comments, no reactions: what the author allowed', (
      tester,
    ) async {
      const closed = Capsule(
        id: 'cap',
        ownerId: 'owner',
        title: 'Quiet',
        privacy: CapsulePrivacy.public,
        color: CapsuleColor.red,
        allowComments: false,
        allowReactions: false,
      );
      expect(CapsuleSocialPanel.showsAnything(closed), isFalse);
    });
  });
}
