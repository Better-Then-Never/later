import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsernameGettingWidget extends StatelessWidget {
  final String uid;

  const UsernameGettingWidget({Key? key, required this.uid}) : super(key: key);

  Future<String?> _getUsername() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc['username'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUsername(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return const Text('Error loading username');
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Text('Username not found');
        }
        return Text(
          '@${snapshot.data}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, height: 1),
        );
      },
    );
  }
}