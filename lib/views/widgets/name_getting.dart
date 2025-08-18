import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_size_text/auto_size_text.dart';

class NameGettingWidget extends StatelessWidget {
  final String uid;
  final TextStyle? style;
  final int? maxLines;
  final double? minFontSize;

  const NameGettingWidget({
    super.key,
    required this.uid,
    this.style,
    this.maxLines,
    this.minFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading name');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Loading...');
        }
        final name = snapshot.data!['name'] as String?;
        if (name == null) {
          return const Text('Name not found');
        }
        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: AutoSizeText(
            name,
            style:
                style ??
                const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 255, 255, 255),
                  height: 1,
                ),
            maxLines: maxLines ?? 1,
            minFontSize: minFontSize ?? 12,
            overflow: TextOverflow.visible,
          ),
        );
      },
    );
  }
}
