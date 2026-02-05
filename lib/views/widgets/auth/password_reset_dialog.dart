import 'package:flutter/material.dart';

class PasswordResetDialog extends StatefulWidget {
  final String initialEmail;
  final Future<void> Function(String email) onSubmit;

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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Center(
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Reset Password',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enter your email to receive a password reset link',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
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
                      backgroundColor: const Color(0xFF56C92E),
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
                                const SnackBar(
                                  content: Text('Please enter your email'),
                                ),
                              );
                              return;
                            }
                            setState(() => _submitting = true);
                            try {
                              await widget.onSubmit(email);
                              if (!mounted) return;
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password reset email sent! Check your inbox.',
                                  ),
                                  backgroundColor: Color(0xFF56C92E),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _submitting = false);
                              }
                            }
                          },
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Send Reset Link',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color.fromARGB(255, 95, 95, 95),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showPasswordResetDialog(
  BuildContext context, {
  String initialEmail = '',
  required Future<void> Function(String) onSubmit,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withAlpha(128),
    builder: (context) =>
        PasswordResetDialog(initialEmail: initialEmail, onSubmit: onSubmit),
  );
}
