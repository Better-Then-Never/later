import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:later/services/popup_notification_service.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/services/image_assets_service.dart';
import 'package:later/views/widgets/_common/default_elements/later_loading_bar.dart';

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
  bool isUploading = false;
  final AssetImageService assetService = AssetImageService();

  @override
  void initState() {
    super.initState();
    final userService = Provider.of<UserDataService>(context, listen: false);
    uid = userService.currentLoggedInUid;
    loadCachedImage();
  }

  Future<void> loadCachedImage() async {
    if (uid == null) return;
    final data = await assetService.getProfileImage(uid!);
    if (data != null) {
      setState(() => pickedImage = data);
    }
  }

  Future<void> pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null || uid == null) return;
    final imageBytes = await image.readAsBytes();
    await saveProfileImage(imageBytes);
  }

  Future<void> pickFromCamera() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null || uid == null) return;
    final imageBytes = await image.readAsBytes();
    await saveProfileImage(imageBytes);
  }

  Future<void> deleteProfileImage() async {
    if (uid == null) return;
    setState(() => isUploading = true);
    await assetService.deleteProfileImage(uid!);
    setState(() {
      pickedImage = null;
      isUploading = false;
    });
  }

  Future<void> saveProfileImage(Uint8List imageBytes) async {
    if (uid == null) return;
    setState(() => isUploading = true);
    try {
      await assetService.saveProfileImage(uid!, imageBytes);
      setState(() => pickedImage = imageBytes);

      if (mounted) {
        PopupNotificationService.showSuccess(
          context: context,
          message: 'Profile picture updated successfully!',
          duration: const Duration(seconds: 2),
          position: NotificationPosition.top,
        );
      }
    } catch (e) {
      if (mounted) {
        PopupNotificationService.showError(
          context: context,
          message: 'Failed to upload profile picture',
          duration: const Duration(seconds: 3),
          position: NotificationPosition.top,
        );
      }
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  Future<void> onProfileTapped() async {
    if (isUploading) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withAlpha(128),
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
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
                          color: const Color.fromARGB(255, 86, 201, 46),
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
                    color: const Color.fromARGB(255, 86, 201, 46),
                  ),
                  buildOptionButton('Choose from gallery', pickFromGallery),
                  Container(
                    width: 264,
                    height: 2,
                    color: const Color.fromARGB(255, 211, 211, 211),
                  ),
                  buildOptionButton('Take a photo', pickFromCamera),
                  Container(
                    width: 264,
                    height: 2,
                    color: const Color.fromARGB(255, 211, 211, 211),
                  ),
                  buildOptionButton(
                    'Delete profile icon',
                    deleteProfileImage,
                    foregroundColor: const Color.fromARGB(253, 253, 65, 64),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildOptionButton(
    String text,
    VoidCallback onTap, {
    Color? foregroundColor,
    BorderRadius? borderRadius,
  }) {
    return SizedBox(
      height: 37,
      width: 264,
      child: TextButton(
        onPressed: () {
          Navigator.pop(context);
          onTap();
        },
        style: TextButton.styleFrom(
          foregroundColor: foregroundColor ?? Colors.black,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            fontFamily: 'Irina',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.zero,
          ),
        ),
        child: Center(child: Text(text)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onProfileTapped,
      child: Container(
        height: widget.pictureHeight ?? 150,
        width: widget.pictureWidth ?? 150,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 223, 223, 223),
          borderRadius: BorderRadius.circular(25),
          image: pickedImage != null && !isUploading
              ? DecorationImage(
                  image: MemoryImage(pickedImage!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: isUploading
            ? const LaterLoadingBar(
                width: 40,
                height: 40,
                message: "Updating...",
                messageSpacing: 5,
              )
            : pickedImage == null
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
