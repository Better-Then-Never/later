import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_size_text/auto_size_text.dart';

class NameGettingWidget extends StatelessWidget {
  final String uid;

  const NameGettingWidget({Key? key, required this.uid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return const Text('Error loading name');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Name not found');
        }
        final name = snapshot.data!['name'] as String?;
        if (name == null) {
          return const Text('Name not found');
        }
        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: AutoSizeText(
            name,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1,
            ),
            maxLines: 1,
            minFontSize: 12,
            overflow: TextOverflow.visible,
          ),
        );
      },
    );
  }
}
