import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfilePicture extends StatefulWidget { 
  final double? pictureHeight; 
  final double? pictureWidth; 
  const ProfilePicture({super.key, this.pictureHeight, this.pictureWidth});

  @override
  State<ProfilePicture> createState() => _ProfilePictureState();
}

class _ProfilePictureState extends State<ProfilePicture> {
  Uint8List? pickedImage;

  @override
  void initState () {
    super.initState();
    loadCachedImage();
  }

  Future<void> loadCachedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final base64Image = prefs.getString('profile_image');
    if (base64Image != null) {
      setState(() {
        pickedImage = base64Decode(base64Image);
      });
    } else {
      getProfilePicture();
    }
  }

  Future<void> onProfileTapped() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child("user_1.jpg");
    final imageBytes = await image.readAsBytes();
    await imageRef.putData(imageBytes);

    // Cache the image locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image', base64Encode(imageBytes));

    setState(() => pickedImage = imageBytes);
  }

  Future<void> getProfilePicture() async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child("user_1.jpg");
      final imageBytes = await imageRef.getData();
      if (imageBytes != null) {
        // Cache the image locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image', base64Encode(imageBytes));
        setState(() => pickedImage = imageBytes);
      }
    } catch (e) {
      // Handle error or show default image
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onProfileTapped,
      child: Container(
        height: widget.pictureHeight ?? 150,
        width: widget.pictureWidth ?? 150,
        decoration: BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
          image: pickedImage != null
              ? DecorationImage(
                  image: MemoryImage(pickedImage!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: pickedImage == null 
          ? const Center(
              child: Icon(
                Icons.person_rounded,
                size: 35,
                color: Colors.black38,
              ),
            )
          : null,
      ),
    );
  }
}