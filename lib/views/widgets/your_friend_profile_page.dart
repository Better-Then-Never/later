import 'package:flutter/material.dart';

class YourFriendProfilePage extends StatelessWidget {
  const YourFriendProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Center(
        child: Text(
          "Your Friend's Profile Page",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }
}
