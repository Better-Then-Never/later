import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/core/theme/app_theme.dart';
import 'package:later/data/firebase/firebase_auth_repository.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/features/auth/auth_controller.dart';
import 'package:later/features/auth/login_page.dart';
import 'package:later/features/auth/signup_page.dart';
import 'package:later/features/auth/welcome_page.dart';
import 'package:later/features/auth/widgets/legal_notice.dart';
import 'package:later/features/auth/widgets/password_reset_dialog.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';

Widget _withRepositories(Widget child) => MultiProvider(
  providers: [
    Provider<AuthRepository>.value(value: FakeAuthRepository()),
    Provider<UserRepository>.value(value: FakeUserRepository()),
  ],
  child: child,
);

/// The app font, so text widths (and line breaks) are the real ones rather
/// than the wide test font's.
Future<void> _loadAppFont() async {
  final loader = FontLoader('Irina');
  for (final face in ['Regular', 'Bold']) {
    final bytes = File(
      'assets/fonts/inria_sans/InriaSans-$face.ttf',
    ).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadAppFont);
  tearDown(() => AppL10n.update(const Locale('en')));

  group('auth pages', () {
    final pages = <String, Widget Function()>{
      'welcome': () => const WelcomePage(),
      'login': () => const LoginPage(),
      'signup': () => const SignupPage(),
      'password reset': () =>
          Scaffold(body: PasswordResetDialog(onSubmit: (_) async => null)),
    };

    for (final locale in AppLocalizations.supportedLocales) {
      for (final dark in [false, true]) {
        testWidgets('fit a 320 dp phone in ${locale.languageCode}, '
            '${dark ? 'dark' : 'light'}', (tester) async {
          tester.view
            ..physicalSize = const Size(320, 640)
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          for (final page in pages.entries) {
            await tester.pumpWidget(
              _withRepositories(
                testApp(
                  home: page.value(),
                  locale: locale,
                  theme: dark ? AppTheme.dark : AppTheme.light,
                ),
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull, reason: page.key);
          }
        });
      }
    }

    testWidgets('keep their English texts', (tester) async {
      await tester.pumpWidget(
        _withRepositories(testApp(home: const LoginPage())),
      );
      expect(find.text('Log In Now'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(find.text('Or connect with'), findsOneWidget);

      await tester.pumpWidget(
        _withRepositories(testApp(home: const SignupPage())),
      );
      expect(find.text('Sign Up Now'), findsOneWidget);
      expect(find.text('Nickname'), findsOneWidget);
      expect(find.text('Do you have an account?'), findsOneWidget);
    });
  });

  group('LegalNotice', () {
    testWidgets('puts the links where the sentence wants them', (tester) async {
      await tester.pumpWidget(
        testApp(home: const Scaffold(body: LegalNotice())),
      );
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .toList();
      expect(texts, [
        'By signing up you agree to the ',
        'Terms of Use',
        ' and ',
        'Privacy Policy',
      ]);

      await tester.pumpWidget(
        testApp(
          home: const Scaffold(body: LegalNotice()),
          locale: const Locale('de'),
        ),
      );
      final german = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .toList();
      expect(german, [
        'Mit der Registrierung stimmst du den ',
        'Nutzungsbedingungen',
        ' und der ',
        'Datenschutzerklärung',
        ' zu',
      ]);
    });
  });

  group('messages follow the app language', () {
    test('validation failures', () async {
      final controller = AuthController(
        auth: FakeAuthRepository(),
        users: FakeUserRepository(),
      );
      expect(
        (await controller.sendPasswordReset(' '))?.message,
        'Please enter your email',
      );
      AppL10n.update(const Locale('de'));
      expect(
        (await controller.login(email: '', password: ''))?.message,
        'Bitte fülle alle Felder aus',
      );
    });

    test('Firebase Auth errors', () {
      expect(
        FirebaseAuthRepository.messageFor('weak-password'),
        'The password provided is too weak.',
      );
      expect(
        FirebaseAuthRepository.accountMessageFor('wrong-password'),
        'Wrong password.',
      );
      AppL10n.update(const Locale('es'));
      expect(
        FirebaseAuthRepository.messageFor('invalid-credential'),
        'Correo o contraseña incorrectos.',
      );
      expect(
        FirebaseAuthRepository.messageFor('network-request-failed'),
        'Sin conexión. Inténtalo de nuevo.',
      );
    });
  });
}
