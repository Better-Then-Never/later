import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/shared/widgets/user/user_placeholder.dart';

void main() {
  test('a person always gets the same gradient; people get different ones', () {
    expect(UserGradient.of('alice-uid'), UserGradient.of('alice-uid'));
    final looks = {
      for (var i = 0; i < 40; i++)
        UserGradient.of('user-$i').colors.join() +
            UserGradient.of('user-$i').begin.toString(),
    };
    expect(looks.length, greaterThan(12), reason: 'pairs × diagonals vary');
  });

  testWidgets('without a known name the placeholder is just the gradient', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.square(
          dimension: 48,
          child: UserPlaceholder(userId: 'u1'),
        ),
      ),
    );
    final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    expect((box.decoration as BoxDecoration).gradient, UserGradient.of('u1'));
    expect(find.byType(Text), findsNothing);
  });
}
