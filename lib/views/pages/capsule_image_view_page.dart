import 'package:flutter/material.dart';

class CapsuleImageViewPage extends StatelessWidget {
  final String imageUrl;
  const CapsuleImageViewPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
          Positioned(
            top: 52,
            left: 8,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Image.asset(
                'assets/images/icons/prof_page/go_back.png',
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
