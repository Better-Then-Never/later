import 'package:flutter/material.dart';
import 'package:later/services/firebase_auth_service.dart';
import 'package:provider/provider.dart';
import 'package:later/views/pages/auth_pages/permission_gate_page.dart';
import 'package:later/views/pages/core_pages/widget_tree_wrapper_page.dart';
import 'package:later/main.dart';

class SubmitButton extends StatefulWidget {
  final String buttonText;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController? name;
  final TextEditingController? username;
  final bool isSignUp;

  const SubmitButton({
    super.key,
    required this.isSignUp,
    required this.buttonText,
    required this.email,
    required this.password,
    this.name,
    this.username,
  });

  @override
  State<SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton> {
  bool _isLoading = false;

  void _handleSubmit() async {
    if (widget.email.text.isEmpty ||
        widget.password.text.isEmpty ||
        (widget.isSignUp &&
            ((widget.name?.text.isEmpty ?? true) ||
                (widget.username?.text.isEmpty ?? true)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final authService = Provider.of<FirebaseAuthService>(
      context,
      listen: false,
    );
    try {
      if (widget.isSignUp) {
        await authService.createUserWithEmailAndPassword(
          widget.email.text.trim(),
          widget.password.text,
          name: widget.name!.text.trim(),
          username: widget.username!.text.trim(),
        );
      } else {
        await authService.signInWithEmailAndPassword(
          widget.email.text.trim(),
          widget.password.text,
        );
      }

      if (!mounted) return;
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(
          builder: (_) => PermissionGatePage(
            onAllGranted: () {
              navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (_) => const WidgetTreeWrapper()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      // TODO: Proper error codes
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 275,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF56C92E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.buttonText,
                style: const TextStyle(
                  fontFamily: 'Irina',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 32.0,
                ),
              ),
      ),
    );
  }
}
