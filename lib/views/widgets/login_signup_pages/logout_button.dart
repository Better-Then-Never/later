import 'package:flutter/material.dart';
import 'package:later/services/auth/auth_services.dart';
import 'package:provider/provider.dart';
import 'package:later/views/widgets/prof_picture.dart';
import 'package:later/views/widgets/background_picture.dart';

class LogOutButton extends StatefulWidget {
  final String buttonText;
  final VoidCallback? onSignedOut;
  const LogOutButton({
    super.key,
    this.buttonText = "Sign Out",
    this.onSignedOut,
  });

  @override
  State<LogOutButton> createState() => _LogOutButtonState();
}

class _LogOutButtonState extends State<LogOutButton> {
  bool _isLoading = false;

  void _handleSignOut() async {
    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.signOut();
      await clearProfileImageCache();
      await clearBackgroundImageCache();
      if (widget.onSignedOut != null) {
        widget.onSignedOut!();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      // TODO: Proper error codes
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 275,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignOut,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF56C92E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text(widget.buttonText, style: const TextStyle(/* ... */)),
      ),
    );
  }
}
