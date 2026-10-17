import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/features/friends/widgets/profile/friend_capsules_strip.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';

Capsule _c(String id, CapsulePrivacy privacy, {DateTime? openAt}) => Capsule(
  id: id,
  ownerId: 'bob',
  title: 'Capsule $id',
  privacy: privacy,
  color: CapsuleColor.green,
  openAt: openAt,
  createdAt: DateTime(2026, 1, int.parse(id)),
);

void main() {
  testWidgets("a friend's shared capsules, newest first; private ones never", (
    tester,
  ) async {
    final repo = FakeCapsuleRepository()
      ..others = [
        _c('1', CapsulePrivacy.public),
        _c('2', CapsulePrivacy.friends, openAt: DateTime(2099)),
        _c('3', CapsulePrivacy.private),
      ];
    await tester.pumpWidget(
      Provider<CapsuleRepository>.value(
        value: repo,
        child: testApp(
          home: const Scaffold(body: FriendCapsulesStrip(friendUid: 'bob')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Capsule 1'), findsOneWidget);
    expect(find.text('Capsule 2'), findsOneWidget);
    expect(find.text('Capsule 3'), findsNothing);
    expect(find.byIcon(Icons.lock_clock), findsOneWidget, reason: 'locked');
  });

  testWidgets('nothing shared: the empty line', (tester) async {
    await tester.pumpWidget(
      Provider<CapsuleRepository>.value(
        value: FakeCapsuleRepository(),
        child: testApp(
          home: const Scaffold(body: FriendCapsulesStrip(friendUid: 'bob')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Friend's capsules will appear here"), findsOneWidget);
  });
}
