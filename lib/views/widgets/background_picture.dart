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
  void initState() {
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
      getBackgroundPicture();
    }
  }

  Future<void> pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final imageBytes = await image.readAsBytes();
    await saveBackgroundImage(imageBytes);
  }

  Future<void> pickFromCamera() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    final imageBytes = await image.readAsBytes();
    await saveBackgroundImage(imageBytes);
  }

  Future<void> deleteBackgroundImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('background_image');
    setState(() => pickedImage = null);

    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child("background_user_1.jpg");
      await imageRef.delete();
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<void> saveBackgroundImage(Uint8List imageBytes) async {
    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child("background_user_1.jpg");
    await imageRef.putData(imageBytes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('background_image', base64Encode(imageBytes));
    setState(() => pickedImage = imageBytes);
  }

  Future<void> onBackgroundTapped() async {
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
                          'Background picture',
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
                          await deleteBackgroundImage();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color.fromARGB(253, 253, 65, 64),
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
                        child: const Center(child: Text('Delete background picture')),
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

  Future<void> getBackgroundPicture() async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child("background_user_1.jpg");
      final imageBytes = await imageRef.getData();
      if (imageBytes != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('background_image', base64Encode(imageBytes));
        setState(() => pickedImage = imageBytes);
      }
    } catch (e) {
      // Handle error if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBackgroundTapped,
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