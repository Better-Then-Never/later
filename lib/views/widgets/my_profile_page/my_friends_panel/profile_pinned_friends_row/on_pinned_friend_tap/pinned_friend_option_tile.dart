import 'package:flutter/material.dart';

class PinnedFriendOptionTile extends StatelessWidget {
  final VoidCallback onTap;
  final String text;

  const PinnedFriendOptionTile({
    super.key,
    required this.onTap,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 37,
      width: 264,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Colors.black,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            fontFamily: 'Irina',
          ),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Center(child: Text(text)),
      ),
    );
  }
}
