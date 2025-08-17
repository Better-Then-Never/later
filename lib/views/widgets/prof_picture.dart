import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> clearProfileImageCache() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('profile_image');
}

class ProfilePicture extends StatefulWidget {
  final double? pictureHeight;
  final double? pictureWidth;
  const ProfilePicture({super.key, this.pictureHeight, this.pictureWidth});

  @override
  State<ProfilePicture> createState() => _ProfilePictureState();
}

class _ProfilePictureState extends State<ProfilePicture> {
  Uint8List? pickedImage;
  String? uid;
  final String fileName = 'profile_image'; // Always use this file name

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
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
      await getProfilePicture();
    }
  }

  Future<void> pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final imageBytes = await image.readAsBytes();
    await saveProfileImage(imageBytes);
  }

  Future<void> pickFromCamera() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    final imageBytes = await image.readAsBytes();
    await saveProfileImage(imageBytes);
  }

  Future<void> deleteProfileIcon() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_image');
    setState(() => pickedImage = null);

    try {
      if (uid == null) return;
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child("profile_pictures/$uid/$fileName");
      await imageRef.delete();
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<void> saveProfileImage(Uint8List imageBytes) async {
    if (uid == null) return;
    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child("profile_pictures/$uid/$fileName");
    await imageRef.putData(imageBytes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image', base64Encode(imageBytes));
    setState(() => pickedImage = imageBytes);
  }

  Future<void> getProfilePicture() async {
    try {
      if (uid == null) return;
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child("profile_pictures/$uid/$fileName");
      final imageBytes = await imageRef.getData();
      if (imageBytes != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image', base64Encode(imageBytes));
        setState(() => pickedImage = imageBytes);
      }
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<void> onProfileTapped() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withAlpha(128),
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 264,
                height: 153,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 37,
                      width: 264,
                      child: Center(
                        child: Text(
                          'Profile picture',
                          style: TextStyle(
                            color: Color.fromARGB(255, 86, 201, 46),
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 264,
                      height: 1,
                      color: Color.fromARGB(255, 86, 201, 46),
                    ),
                    SizedBox(
                      height: 37,
                      width: 264,
                      child: TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await pickFromGallery();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(0),
                              topRight: Radius.circular(0),
                            ),
                          ),
                        ),
                        child: const Center(child: Text('Choose from gallery')),
                      ),
                    ),
                    Container(
                      width: 264,
                      height: 2,
                      color: Color.fromARGB(255, 211, 211, 211),
                    ),
                    SizedBox(
                      height: 37,
                      width: 264,
                      child: TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await pickFromCamera();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Center(child: Text('Take a photo')),
                      ),
                    ),
                    Container(
                      width: 264,
                      height: 2,
                      color: Color.fromARGB(255, 211, 211, 211),
                    ),
                    SizedBox(
                      height: 37,
                      width: 264,
                      child: TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await deleteProfileIcon();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color.fromARGB(
                            253,
                            253,
                            65,
                            64,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                        ),
                        child: const Center(child: Text('Delete profile icon')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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
          borderRadius: BorderRadius.circular(25),
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
