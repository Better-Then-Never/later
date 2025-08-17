import 'package:flutter/material.dart';

class MainText extends StatefulWidget {
  final String mainText;
  final String additionalText;
  const MainText({
    super.key,
    required this.mainText,
    required this.additionalText,
  });

  @override
  State<MainText> createState() => _MainTextState();
}

class _MainTextState extends State<MainText> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset("assets/images/later_logo.png", height: 150, width: 120),
        Column(
          children: [
            Text(
              widget.mainText,
              style: const TextStyle(
                fontSize: 40.0,
                fontFamily: 'Irina',
                letterSpacing: -1,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              widget.additionalText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.0,
                fontFamily: 'Irina',
                letterSpacing: 0.1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
