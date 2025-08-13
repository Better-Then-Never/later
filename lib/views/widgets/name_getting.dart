import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NameGettingWidget extends StatelessWidget {
  final String uid;

  const NameGettingWidget({Key? key, required this.uid}) : super(key: key);

  Future<String?> _getName() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc['name'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getName(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return const Text('Error loading name');
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Text('Name not found');
        }
        return Text(
          snapshot.data!,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1),
        );
      },
    );
  }
}