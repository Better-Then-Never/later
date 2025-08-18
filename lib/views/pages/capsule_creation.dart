import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:later/data/models/time_capsule.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CapsuleCreationPage extends StatefulWidget {
  final String imagePath;

  const CapsuleCreationPage({super.key, required this.imagePath});

  @override
  State<CapsuleCreationPage> createState() => _CapsuleCreationPageState();
}

class _CapsuleCreationPageState extends State<CapsuleCreationPage> {
  final TextEditingController _descriptionController = TextEditingController();
  CapsulePrivacy _privacy = CapsulePrivacy.public;
  LatLng? _pickedLocation;
  String? uid;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Image.file(
                File(widget.imagePath),
                width: 180,
                height: 280,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description (optional)",
                ),
              ),
              const SizedBox(height: 12),

              DropdownButton<CapsulePrivacy>(
                value: _privacy,
                items: CapsulePrivacy.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.toString().split('.').last.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _privacy = v!),
              ),

              ElevatedButton(
                onPressed: () async {
                  // TODO: Implement proper map location picking
                  // For now we use dummy coordinates
                  _pickedLocation = LatLng(
                    51.76926904036574,
                    19.48539528790105,
                  );
                  await _saveCapsule();
                },
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text("Post Capsule"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCapsule() async {
    if (_pickedLocation == null) return;

    setState(() => _isSaving = true);
    try {
      final capsuleId = FirebaseFirestore.instance
          .collection('capsules')
          .doc()
          .id;

      // 1. Upload image to Firebase Storage
      final ref = FirebaseStorage.instance.ref().child(
        'userdata/$uid/capsules/$capsuleId/image.jpg',
      );
      await ref.putFile(File(widget.imagePath));
      final imageUrl = await ref.getDownloadURL();

      // 2. Create capsule object
      final capsule = TimeCapsule(
        id: capsuleId,
        ownerId: uid!,
        imageUrl: imageUrl,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        location: GeoPoint(
          _pickedLocation!.latitude,
          _pickedLocation!.longitude,
        ),
        privacy: _privacy,
      );

      // 3. Save capsule to Firestore
      await FirebaseFirestore.instance
          .collection('capsules')
          .doc(capsuleId)
          .set(capsule.toMap());

      if (context.mounted) Navigator.pop(context);
    } catch (e, st) {
      print("Error saving capsule: $e\n$st");
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to save capsule: $e")));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
