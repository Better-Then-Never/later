import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

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
    getProfilePicture();
  }
  
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
                  image: Image.memory(
                    pickedImage!,
                  ).image,
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
        ) : null,
      ),
    );
  }

    Future<void> onProfileTapped() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child("user_1.jpg");
    final imageBytes = await image.readAsBytes();
    await imageRef.putData(imageBytes);

    setState(() => pickedImage = imageBytes);
  }

  Future<void> getProfilePicture() async {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child("user_1.jpg");

    try {
      final imageBytes = await imageRef.getData(10000000); // 10MB max size
      if (imageBytes == null) return;
      setState(() => pickedImage = imageBytes);
    } catch (e) {
      print("Profile picture not found.");
    }
  }
}