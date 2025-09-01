import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsernameGettingWidget extends StatelessWidget {
  final String uid;
  final TextStyle? style;

  const UsernameGettingWidget({super.key, required this.uid, this.style});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading username');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Loading...');
        }
        final username = snapshot.data!['username'] as String?;
        if (username == null) {
          return const Text('Username not found');
        }
        return Text(
          '@$username',
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
