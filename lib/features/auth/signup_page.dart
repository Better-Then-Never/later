import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/app_routes.dart';
import '../../core/errors/app_failure.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/repositories.dart';
import 'auth_controller.dart';
import 'widgets/auth_heading.dart';
import 'widgets/auth_submit_button.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/social_login_buttons.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthController(
        auth: context.read<AuthRepository>(),
        users: context.read<UserRepository>(),
      ),
      child: const _SignupView(),
    );
  }
}

class _SignupView extends StatefulWidget {
  const _SignupView();

  @override
  State<_SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<_SignupView> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showFailure(AppFailure failure) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failure.message)));
  }

  Future<void> _signUp() async {
    final failure = await context.read<AuthController>().signUp(
      name: _name.text,
      username: _username.text,
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

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AuthController, bool>((c) => c.busy);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
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
                          const AuthHeading(
                            title: 'Sign Up Now',
                            subtitle:
                                'Please fill the details to create your account',
                          ),
                          const SizedBox(height: 17.5),
                          AutofillGroup(
                            child: Column(
                              children: [
                                AuthTextField(
                                  controller: _name,
                                  hint: 'Name',
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.name],
                                ),
                                const SizedBox(height: 10.0),
                                AuthTextField(
                                  controller: _username,
                                  hint: 'Nickname',
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.newUsername,
                                  ],
                                ),
                                const SizedBox(height: 10.0),
                                AuthTextField(
                                  controller: _email,
                                  hint: 'Email',
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                ),
                                const SizedBox(height: 10.0),
                                AuthTextField(
                                  controller: _password,
                                  hint: 'Password',
                                  obscure: true,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          AuthSubmitButton(
                            text: 'Sign Up',
                            isLoading: busy,
                            onPressed: _signUp,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Do you have an account?',
                                style: TextStyle(fontSize: 16.0),
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
                                onPressed: () => AppRoutes.toLogin(context),
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
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
