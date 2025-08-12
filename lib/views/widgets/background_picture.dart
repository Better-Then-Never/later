import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BackgroundPicture extends StatefulWidget { 
  final double? pictureHeight; 
  final double? pictureWidth; 
  const BackgroundPicture({super.key, this.pictureHeight, this.pictureWidth, required Alignment allignment});

  @override
  State<BackgroundPicture> createState() => _BackgroundPictureState();
}

class _BackgroundPictureState extends State<BackgroundPicture> {
  Uint8List? pickedImage;

  @override
  void initState () {
    super.initState();
    loadCachedImage();
  }

  Future<void> loadCachedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final base64Image = prefs.getString('background_image');
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
    final imageRef = storageRef.child("background_user_1.jpg");
    final imageBytes = await image.readAsBytes();
    await imageRef.putData(imageBytes);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('background_image', base64Encode(imageBytes));

    setState(() => pickedImage = imageBytes);
  }

  Future<void> getProfilePicture() async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child("user_1.jpg");
      final imageBytes = await imageRef.getData();
      if (imageBytes != null) {

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image', base64Encode(imageBytes));
        setState(() => pickedImage = imageBytes);
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onProfileTapped,
      child: Container(
        height: widget.pictureHeight ?? 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
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
