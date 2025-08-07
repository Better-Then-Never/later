import 'package:flutter/material.dart';

class SubmitButton extends StatefulWidget {
  final dynamic buttonText;

  const SubmitButton({super.key, required this.buttonText});

  @override
  _SubmitButtonState createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 275,
      height: 55,
      child: ElevatedButton(
        onPressed: () {
          // TODO: Email login
          Navigator.pushReplacementNamed(context, '/widgetTree');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF56C92E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        child: Text(
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
