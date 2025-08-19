import 'package:flutter/material.dart';

class CapsuleCreationTopBar extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final VoidCallback onBack;

  const CapsuleCreationTopBar({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: screenHeight * 0.12,
      width: screenWidth,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 5,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Create Capsule',
                style: TextStyle(
                  fontSize: screenWidth * 0.09,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Irina',
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: GestureDetector(
              onTap: onBack,
              child: Image.asset(
                'assets/images/icons/prof_page/go_back.png',
                width: screenWidth * 0.11,
                height: screenWidth * 0.11,
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Image.asset(
                'assets/images/icons/capsule_creation/cross.png',
                width: screenWidth * 0.11,
                height: screenWidth * 0.11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
