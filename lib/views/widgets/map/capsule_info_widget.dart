import 'package:flutter/material.dart';

class CapsuleInfoPanel extends StatelessWidget {
  final String title;
  final String dateStamp;
  final VoidCallback onMoreInfo;

  const CapsuleInfoPanel({
    super.key,
    required this.title,
    required this.dateStamp,
    required this.onMoreInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
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
              fontSize: 25,
            ),
          ),

          Text(
            dateStamp,
            style: const TextStyle(fontFamily: 'Irina', fontSize: 16),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 86, 201, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                onPressed: onMoreInfo,
                child: const Text(
                  'Open',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Irina',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
