// The profile menu's "Report" asks why and files a report on the profile.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/data/models/social.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/features/friends/widgets/report_user.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';

class _Session extends ChangeNotifier implements SessionController {
  @override
  String? get uid => 'me';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('reporting a profile asks why and files it', (tester) async {
    final social = FakeSocialRepository();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SessionController>.value(value: _Session()),
          Provider<SocialRepository>.value(value: social),
        ],
        child: testApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => reportUser(context, 'bob'),
              child: const Text('report'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spam'));
    await tester.pumpAndSettle();
    expect(social.reports.single['targetPath'], 'users/bob');
    expect(social.reports.single['target'], ReportTarget.user);
    expect(social.reports.single['reason'], ReportReason.spam);
    // The thank-you toast goes away on its own.
    await tester.pump(const Duration(seconds: 5));
  });
}
