import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:later/data/models/time_capsule.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:later/views/pages/map_page.dart' as map;
import 'package:later/views/widgets/capsule_creation/capsule_privacy_dropdown.dart';
import 'package:later/views/widgets/capsule_creation/capsule_image_preview.dart';
import 'package:later/views/widgets/capsule_creation/capsule_creation_top_bar.dart';

class CapsuleCreationPage extends StatefulWidget {
  final String imagePath;

  const CapsuleCreationPage({super.key, required this.imagePath});

  @override
  State<CapsuleCreationPage> createState() => _CapsuleCreationPageState();
}

class _CapsuleCreationPageState extends State<CapsuleCreationPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80), // leave space for button
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CapsuleCreationTopBar(
              screenWidth: MediaQuery.of(context).size.width,
              screenHeight: MediaQuery.of(context).size.height,
              onBack: () => Navigator.pushReplacementNamed(context, '/camera'),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Capsule Preview',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.05,
                        fontFamily: 'Irina',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.all(Radius.circular(25)),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.45,
                          height: double.infinity,
                          child: CapsuleImagePreview(
                            imagePath: widget.imagePath,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  hintText: "Add Title... ",
                                  hintStyle: TextStyle(
                                    fontSize: 25,
                                    fontFamily: 'Irina',
                                    fontWeight: FontWeight.bold,
                                  ),
                                  border: InputBorder.none,
                                ),
                                style: const TextStyle(
                                  fontSize: 25,
                                  fontFamily: 'Irina',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextField(
                                controller: _descriptionController,
                                decoration: const InputDecoration(
                                  hintText: "Add description...",
                                  hintStyle: TextStyle(
                                    fontFamily: 'Irina',
                                    fontWeight: FontWeight.normal,
                                  ),
                                  border: InputBorder.none,
                                ),
                                style: const TextStyle(
                                  fontFamily: 'Irina',
                                  fontWeight: FontWeight.normal,
                                ),
                                maxLines: 10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 86, 201, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            onPressed: () async {
              _pickedLocation = map.MapPage.currentPositionStatic;
              await _saveCapsule();
            },
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "Create Capsule",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Irina',
                      color: Colors.white,
                    ),
                  ),
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

      final ref = FirebaseStorage.instance.ref().child(
        'userdata/$uid/capsules/$capsuleId/image.jpg',
      );
      await ref.putFile(File(widget.imagePath));
      final imageUrl = await ref.getDownloadURL();

      final capsule = TimeCapsule(
        id: capsuleId,
        ownerId: uid!,
        imageUrl: imageUrl,
        title: _titleController.text.isEmpty
            ? 'Capsule'
            : _titleController.text,
        createdAt: Timestamp.now(),
        isScheduled: false,
        openAt: Timestamp.now(),
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        location: GeoPoint(
          _pickedLocation!.latitude,
          _pickedLocation!.longitude,
        ),
        privacy: _privacy,
        color: 'blue',
      );

      await FirebaseFirestore.instance
          .collection('capsules')
          .doc(capsuleId)
          .set(capsule.toMap());

      if (context.mounted) Navigator.pop(context);
      Navigator.pop(context);
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
