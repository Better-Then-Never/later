import 'package:flutter/material.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import 'package:later/core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_sheets.dart';

class PasswordResetDialog extends StatefulWidget {
  final String initialEmail;
  final Future<AppFailure?> Function(String email) onSubmit;

  const PasswordResetDialog({
    super.key,
    this.initialEmail = '',
    required this.onSubmit,
  });

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  late final TextEditingController _emailController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      // Wider than a menu card: it holds a text field.
      width: 300,
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppSheets.radius),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.authResetTitle,
            style: TextStyle(
              color: context.palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.authResetDescription,
            style: TextStyle(color: context.palette.textFaint, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: l10n.authEmailHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              isDense: true,
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 180,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
                padding: EdgeInsets.zero,
              ),
              onPressed: _submitting
                  ? null
                  : () async {
                      final email = _emailController.text.trim();
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.authEnterEmail)),
                        );
                        return;
                      }
                      setState(() => _submitting = true);
                      // Captured now: the sheet's context is gone
                      // once it is popped.
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      final failure = await widget.onSubmit(email);
                      if (!mounted) return;
                      if (failure == null) {
                        navigator.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(l10n.authResetSent),
                            backgroundColor: AppColors.brandGreen,
                          ),
                        );
                      } else {
                        setState(() => _submitting = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.authErrorWithMessage(failure.message),
                            ),
                          ),
                        );
                      }
                    },
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.onAccent,
                        ),
                      ),
                    )
                  : Text(
                      l10n.authResetSend,
                      style: const TextStyle(
                        color: AppColors.onAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: context.palette.textSecondary,
              textStyle: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              padding: EdgeInsets.zero,
            ),
            child: Text(l10n.commonCancel),
          ),
        ],
      ),
    );
  }
}

Future<void> showPasswordResetDialog(
  BuildContext context, {
  String initialEmail = '',
  required Future<AppFailure?> Function(String) onSubmit,
}) {
  return showCenteredSheet<void>(
    context,
    PasswordResetDialog(initialEmail: initialEmail, onSubmit: onSubmit),
  );
}
