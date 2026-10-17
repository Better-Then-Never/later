import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_dimens.dart';
import 'package:later/core/theme/app_colors.dart';

/// 325×55 outlined input of the auth screens, with an optional show/hide
/// toggle for passwords.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
  });

  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 325,
      height: 55,
      child: TextField(
        controller: widget.controller,
        obscureText: widget.obscure && _hidden,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        style: const TextStyle(fontSize: 20.0),
        decoration: InputDecoration(
          hintText: widget.hint,
          suffixIcon: widget.obscure
              ? IconButton(
                  tooltip: _hidden ? 'Show password' : 'Hide password',
                  icon: Image.asset(
                    _hidden
                        ? AppIcons.authPasswordShown
                        : AppIcons.authPasswordHidden,
                    width: 25.0,
                    height: 25.0,
                  ),
                  onPressed: () => setState(() => _hidden = !_hidden),
                )
              : null,
          enabledBorder: const OutlineInputBorder(
            borderRadius: AppRadii.lCircular,
            borderSide: BorderSide(width: 1.5, color: AppColors.black),
          ),
          border: const OutlineInputBorder(borderRadius: AppRadii.lCircular),
        ),
      ),
    );
  }
}
