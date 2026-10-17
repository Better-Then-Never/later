import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/features/capsules/creation/widgets/capsule_submit_button.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('in the bottom bar the button leaves the page its room', (
    tester,
  ) async {
    const body = Key('body');
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: const SizedBox.expand(key: body),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: CapsuleSubmitButton(
                label: 'Create Capsule',
                saving: false,
                onSave: () async => true,
                onDone: () {},
              ),
            ),
          ),
        ),
      ),
    );
    final screen = tester.getSize(find.byType(Scaffold)).height;
    expect(tester.getSize(find.byKey(body)).height, greaterThan(screen * 0.8));
    expect(
      tester.getSize(find.byType(CapsuleSubmitButton)).height,
      lessThan(screen * 0.1),
    );
  });
}
