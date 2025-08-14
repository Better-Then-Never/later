import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NameChangingWidget extends StatefulWidget {
  const NameChangingWidget({super.key});

  @override
  State<NameChangingWidget> createState() => _NameChangingWidgetState();
}

class _NameChangingWidgetState extends State<NameChangingWidget> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  Future<void> _saveName() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _error = "User not logged in.";
        _isSaving = false;
      });
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
      });
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name updated!')),
      );
    } catch (e) {
      setState(() {
        _error = "Failed to update name.";
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Change your name:",
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Enter new name",
            errorText: _error,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveName,
          child: _isSaving
              ? CircularProgressIndicator(color: Colors.white)
              : Text("Save Name"),
        ),
      ],
    );
  }
}