import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:later/services/cache_firebase/user_services.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as developer;

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
  final String fileName = 'profile_image';

  @override
  void initState() {
    super.initState();
    final userService = Provider.of<UserService>(context, listen: false);
    uid = userService.uid;
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
      final imageRef = storageRef.child(
        "userdata/$uid/assets/images/$fileName",
      );
      await imageRef.delete();
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<Uint8List> _resizeImage(
    Uint8List imageBytes, {
    int maxSize = 128,
  }) async {
    final original = img.decodeImage(imageBytes);
    if (original == null) return imageBytes;
    final resized = img.copyResize(original, width: maxSize, height: maxSize);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
  }

  Future<void> saveProfileImage(Uint8List imageBytes) async {
    if (uid == null) return;
    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child("userdata/$uid/assets/images/$fileName");
    await imageRef.putData(imageBytes);

    final smallImageBytes = await _resizeImage(imageBytes, maxSize: 128);
    developer.log(
      'Original size: ${imageBytes.length}, Small size: ${smallImageBytes.length}',
      name: 'ProfilePicture',
    );
    final smallImageRef = storageRef.child(
      "userdata/$uid/assets/images/profile_image_small",
    );
    try {
      await smallImageRef.putData(smallImageBytes);
      developer.log('Small image uploaded successfully', name: 'ProfilePicture');
    } catch (e) {
      developer.log('Error uploading small image: $e', name: 'ProfilePicture');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image', base64Encode(imageBytes));
    setState(() => pickedImage = imageBytes);
  }

  Future<void> getProfilePicture() async {
    try {
      if (uid == null) return;
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child(
        "userdata/$uid/assets/images/$fileName",
      );
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
                  borderRadius: BorderRadius.circular(25),
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
                            fontFamily: 'Irina',
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
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Irina',
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
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Irina',
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
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Irina',
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(25),
                              bottomRight: Radius.circular(25),
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
          color: Color.fromARGB(255, 223, 223, 223),
          borderRadius: BorderRadius.circular(25),
          image: pickedImage != null
              ? DecorationImage(
                  image: MemoryImage(pickedImage!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: pickedImage == null
            ? Center(
                child: Image.asset(
                  'assets/images/icons/prof_page/choose_pp.png',
                  width: 35,
                  height: 35,
                  fit: BoxFit.contain,
                ),
              )
            : null,
      ),
    );
  }
}
