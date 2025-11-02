import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:later/services/popup_notification_service.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/services/image_assets_service.dart';
import 'package:later/views/widgets/_common/default_elements/later_loading_bar.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';

class ProfileBackgroundPicture extends StatefulWidget {
  final double? pictureHeight;
  final double? pictureWidth;
  const ProfileBackgroundPicture({
    super.key,
    this.pictureHeight,
    this.pictureWidth,
    required Alignment allignment,
  });

  @override
  State<ProfileBackgroundPicture> createState() =>
      _ProfileBackgroundPictureState();
}

class _ProfileBackgroundPictureState extends State<ProfileBackgroundPicture> {
  Uint8List? pickedImage;
  String? uid;
  bool isUploading = false;
  final AssetImageService _assetService = AssetImageService();

  @override
  void initState() {
    super.initState();
    final userService = Provider.of<UserDataService>(context, listen: false);
    uid = userService.currentLoggedInUid;
    _loadCachedImage();
  }

  Future<void> _loadCachedImage() async {
    if (uid == null) return;
    final data = await _assetService.getBackgroundImage(uid!);
    if (data != null && mounted) {
      setState(() => pickedImage = data);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (uid == null) return;
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    await _saveImage(bytes);
  }

  Future<void> _saveImage(Uint8List imageBytes) async {
    if (uid == null) return;
    setState(() => isUploading = true);
    try {
      await _assetService.saveBackgroundImage(uid!, imageBytes);
      if (mounted) setState(() => pickedImage = imageBytes);
      if (mounted) {
        PopupNotificationService.showSuccess(
          context: context,
          message: 'Background picture updated successfully!',
          duration: const Duration(seconds: 2),
          position: NotificationPosition.top,
        );
      }
    } catch (_) {
      if (mounted) {
        PopupNotificationService.showError(
          context: context,
          message: 'Failed to upload background picture',
          duration: const Duration(seconds: 3),
          position: NotificationPosition.top,
        );
      }
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  Future<void> _deleteImage() async {
    if (uid == null) return;
    setState(() => isUploading = true);
    await _assetService.deleteBackgroundImage(uid!);
    if (mounted) setState(() => pickedImage = null);
    setState(() => isUploading = false);
  }

  Future<void> _onBackgroundTapped() async {
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
                        'Background picture',
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
                  SizedBox(
                    height: 37,
                    width: 264,
                    child: TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _pickImage(ImageSource.gallery);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Irina',
                        ),
                      ),
                      child: const Center(child: Text('Choose from gallery')),
                    ),
                  ),
                  Container(
                    width: 264,
                    height: 2,
                    color: const Color.fromARGB(255, 211, 211, 211),
                  ),
                  SizedBox(
                    height: 37,
                    width: 264,
                    child: TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _pickImage(ImageSource.camera);
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
                    color: const Color.fromARGB(255, 211, 211, 211),
                  ),
                  SizedBox(
                    height: 37,
                    width: 264,
                    child: TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _deleteImage();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color.fromARGB(253, 253, 65, 64),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Irina',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : _onBackgroundTapped,
      child: Container(
        height: widget.pictureHeight ?? 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 187, 187, 187),
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
                    messageStyle: const TextStyle(
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
