import 'package:flutter/material.dart';

class CapsuleInfoPanel extends StatelessWidget {
  final String title;
  final VoidCallback onMoreInfo;

  const CapsuleInfoPanel({
    super.key,
    required this.title,
    required this.onMoreInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Irina',
              fontSize: 16,
            ),
          ),
          Text(
            '12-03-1999',
            style: const TextStyle(fontFamily: 'Irina', fontSize: 16),
          ),

          const Spacer(),
          Positioned(
            bottom: 10,
            child: ElevatedButton(
              onPressed: onMoreInfo,
              child: const Text('Open'),
            ),
          ),
        ],
      ),
    );
  }
}
