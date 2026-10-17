import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/app_routes.dart';
import '../../core/errors/app_failure.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../data/repositories/repositories.dart';
import 'auth_controller.dart';
import 'widgets/auth_heading.dart';
import 'widgets/auth_submit_button.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/password_reset_dialog.dart';
import 'widgets/social_login_buttons.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthController(
        auth: context.read<AuthRepository>(),
        users: context.read<UserRepository>(),
      ),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showFailure(AppFailure failure) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failure.message)));
  }

  Future<void> _login() async {
    final failure = await context.read<AuthController>().login(
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    if (failure != null) return _showFailure(failure);
    AppRoutes.backToRoot();
  }

  Future<void> _google() async {
    final failure = await context.read<AuthController>().signInWithGoogle();
    if (!mounted) return;
    if (failure != null) return _showFailure(failure);
    AppRoutes.backToRoot();
  }

  void _forgotPassword() {
    final controller = context.read<AuthController>();
    showPasswordResetDialog(
      context,
      initialEmail: _email.text,
      onSubmit: controller.sendPasswordReset,
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AuthController, bool>((c) => c.busy);
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(),
                      Column(
                        children: [
                          AuthHeading(
                            title: l10n.authLoginTitle,
                            subtitle: l10n.authLoginSubtitle,
                          ),
                          const SizedBox(height: 30),
                          AutofillGroup(
                            child: Column(
                              children: [
                                AuthTextField(
                                  hint: l10n.authEmailHint,
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                ),
                                const SizedBox(height: 10),
                                AuthTextField(
                                  hint: l10n.authPasswordHint,
                                  obscure: true,
                                  controller: _password,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 325,
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      splashFactory: NoSplash.splashFactory,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      overlayColor: Colors.transparent,
                                    ),
                                    onPressed: _forgotPassword,
                                    child: Text(
                                      l10n.authForgotPassword,
                                      style: const TextStyle(
                                        color: AppColors.brandGreen,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                          AuthSubmitButton(
                            text: l10n.authLogInButton,
                            isLoading: busy,
                            onPressed: _login,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.authNoAccount,
                                style: const TextStyle(fontSize: 16.0),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.all(5),
                                  splashFactory: NoSplash.splashFactory,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  overlayColor: Colors.transparent,
                                ),
                                onPressed: () =>
                                    AppRoutes.toSignupFromLogin(context),
                                child: Text(
                                  l10n.authGoToSignUp,
                                  style: TextStyle(
                                    color: context.palette.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40.0),
                          SocialLoginButtons(onGoogle: busy ? null : _google),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
