import 'package:flutter/material.dart';

class MainText extends StatefulWidget {
  final dynamic mainText;
  final dynamic additionalText;
  const MainText({ Key? key, required this.mainText, required this.additionalText }) : super(key: key);

  @override
  _MainTextState createState() => _MainTextState();
}

class _MainTextState extends State<MainText> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Column(
      children: [
        Image.asset(
          "assets/images/later_logo.png",
          height: 150,
          width: 120,
        ),
        SizedBox(height: screenHeight * 0.005),
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