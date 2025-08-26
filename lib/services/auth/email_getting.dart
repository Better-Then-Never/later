import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailGettingWidget extends StatelessWidget {
  final String uid;
  final TextStyle? style;

  const EmailGettingWidget({super.key, required this.uid, this.style});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading email');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Loading...');
        }
        final email = snapshot.data!['email'] as String?;
        if (email == null) {
          return const Text('Email not found');
        }
        return Text(
          email,
          style:
              style ??
              const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1,
              ),
        );
      },
    );
  }
}
