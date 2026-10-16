import 'package:flutter/material.dart';
import 'package:later/core/assets/app_assets.dart';

class RegistrationInputField extends StatefulWidget {
  final dynamic textHint;
  final bool isTextHidden;
  final TextEditingController controller;

  const RegistrationInputField({
    super.key,
    required this.textHint,
    required this.controller,
    this.isTextHidden = false,
  });

  @override
  State<RegistrationInputField> createState() => _RegistrationInputFieldState();
}

class _RegistrationInputFieldState extends State<RegistrationInputField> {
  bool isObscured = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 325,
      height: 55,
      child: TextField(
        controller: widget.controller,
        obscureText: widget.isTextHidden && isObscured,
        style: const TextStyle(fontSize: 20.0),
        decoration: InputDecoration(
          hintText: widget.textHint,
          suffixIcon: widget.isTextHidden
              ? IconButton(
                  icon: isObscured
                      ? Image.asset(
                          AppIcons.authPasswordShown,
                          width: 25.0,
                          height: 25.0,
                        )
                      : Image.asset(
                          AppIcons.authPasswordHidden,
                          width: 25.0,
                          height: 25.0,
                        ),
                  onPressed: () {
                    setState(() {
                      isObscured = !isObscured;
                    });
                  },
                )
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: const BorderSide(width: 1.5, color: Colors.black),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0)),
        ),
      ),
    );
  }
}
