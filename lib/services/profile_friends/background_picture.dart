import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:later/services/cache_firebase/firebase_user_services.dart';
import 'package:later/services/appearance/notification_system.dart';
import 'package:later/views/widgets/_common/default_elements/later_loading_bar.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

Future<void> clearBackgroundImageCache() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('background_image');
}

class BackgroundPicture extends StatefulWidget {
  final double? pictureHeight;
  final double? pictureWidth;
  const BackgroundPicture({
    super.key,
    this.pictureHeight,
    this.pictureWidth,
    required Alignment allignment,
  });

  @override
  State<BackgroundPicture> createState() => _BackgroundPictureState();
}

class _BackgroundPictureState extends State<BackgroundPicture> {
  Uint8List? pickedImage;
  String? uid;
  final String fileName = 'background_image';
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    final userService = Provider.of<FirebaseUserService>(
      context,
      listen: false,
    );
    uid = userService.uid;
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
      await getBackgroundPicture();
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
    setState(() => isUploading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('background_image');
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
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<void> saveBackgroundImage(Uint8List imageBytes) async {
    setState(() => isUploading = true);

    if (uid == null) {
      setState(() => isUploading = false);
      return;
    }

    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child(
        "userdata/$uid/assets/images/$fileName",
      );
      await imageRef.putData(imageBytes);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('background_image', base64Encode(imageBytes));
      setState(() => pickedImage = imageBytes);

      if (mounted) {
        UnifiedNotification.showSuccess(
          context: context,
          message: 'Background picture updated successfully!',
          duration: const Duration(seconds: 2),
          position: NotificationPosition.top,
        );
      }
    } catch (e) {
      if (mounted) {
        UnifiedNotification.showError(
          context: context,
          message: 'Failed to upload background picture',
          duration: const Duration(seconds: 3),
          position: NotificationPosition.top,
        );
      }
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<void> getBackgroundPicture() async {
    try {
      if (uid == null) return;
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child(
        "userdata/$uid/assets/images/$fileName",
      );
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

  Future<void> onBackgroundTapped() async {
    if (isUploading) return; // Disable tap during upload

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
                          'Background picture',
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
                          await deleteBackgroundImage();
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
                        child: const Center(
                          child: Text('Delete background picture'),
                        ),
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
      onTap: isUploading
          ? null
          : onBackgroundTapped, // Disable tap during upload
      child: Container(
        height: widget.pictureHeight ?? 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 187, 187, 187),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
          image: pickedImage != null && !isUploading
              ? DecorationImage(
                  image: MemoryImage(pickedImage!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: isUploading
            ? Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: LaterLoadingBar(
                    width: 40,
                    height: 40,
                    message: "Updating...",
                    messageSpacing: 5,
                    messageStyle: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Inria',
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : pickedImage == null
            ? Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Image.asset(
                    'assets/images/icons/prof_page/choose_bg.png',
                    width: 35,
                    height: 35,
                    fit: BoxFit.contain,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
