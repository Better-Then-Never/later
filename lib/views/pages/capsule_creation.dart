import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:later/data/models/time_capsule.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:later/views/pages/map_page.dart' as map;
import 'package:later/views/widgets/capsule_creation/capsule_image_preview.dart';
import 'package:later/views/widgets/capsule_creation/capsule_creation_location_label.dart';
import 'package:later/views/widgets/capsule_creation/capsule_creation_datestamp.dart';
import 'package:later/views/widgets/capsule_creation/capsule_creation_description_input.dart';
import 'package:later/views/widgets/capsule_creation/capsule_creation_title_input.dart';
import 'package:intl/intl.dart';
import 'package:later/views/widgets/common/default_icon_button.dart';
import 'package:later/views/widgets/common/page_header.dart';

class CapsuleCreationPage extends StatefulWidget {
  final String imagePath;
  final String? initialPrivacy;

  const CapsuleCreationPage({
    super.key,
    required this.imagePath,
    this.initialPrivacy,
  });

  @override
  State<CapsuleCreationPage> createState() => _CapsuleCreationPageState();
}

class _CapsuleCreationPageState extends State<CapsuleCreationPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  CapsulePrivacy _privacy = CapsulePrivacy.public;
  CapsuleColor _color = CapsuleColor.red;
  Timestamp? _openAt;

  LatLng? _pickedLocation;
  String? uid;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
    _pickedLocation = map.MapPage.currentPositionStatic;

    // Set initial privacy based on arguments
    if (widget.initialPrivacy == 'friends') {
      _privacy = CapsulePrivacy.friends;
    } else if (widget.initialPrivacy == 'public') {
      _privacy = CapsulePrivacy.public;
    }
  }

  void _cyclePrivacy() {
    final values = CapsulePrivacy.values;
    final currentIndex = values.indexOf(_privacy);
    final nextIndex = (currentIndex + 1) % values.length;
    setState(() {
      _privacy = values[nextIndex];
    });
  }

  void _cycleColor() {
    final values = CapsuleColor.values;
    final currentIndex = values.indexOf(_color);
    final nextIndex = (currentIndex + 1) % values.length;
    setState(() {
      _color = values[nextIndex];
    });
  }

  Future<void> _pickOpenDate(BuildContext context) async {
    final now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      final chosenDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        now.hour,
        now.minute,
        now.second,
      );

      setState(() {
        _openAt = Timestamp.fromDate(chosenDateTime);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              mainText: 'Create Capsule',
              leadingButton: DefaultIconButton(
                onTap: () => Navigator.pushReplacementNamed(context, '/camera'),
                assetPath: 'assets/images/icons/prof_page/go_back.png',
              ),
              trailingButton: DefaultIconButton(
                onTap: () => Navigator.pop(context),
                assetPath: 'assets/images/icons/capsule_creation/cross.png',
              ),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CapsuleCreationTitleInput(
                                controller: _titleController,
                              ),

                              CapsuleCreationDescriptionInputField(
                                controller: _descriptionController,
                              ),

                              CapsuleCreationDateStamp(
                                height: screenHeight * 0.045,
                              ),
                              const SizedBox(height: 8),
                              CapsuleCreationLocationLabel(
                                height: screenHeight * 0.05,
                                iconPath:
                                    'assets/images/icons/capsule_creation/location_icon.png',
                                location: _pickedLocation,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),

                  Text(
                    'Capsule Settings',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.05,
                      fontFamily: 'Irina',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.185,
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
                    child: Column(
                      children: [
                        _settingsRow(
                          context,
                          true,
                          'Privacy',
                          infoText: _privacy.label,
                          onTap: _cyclePrivacy,
                          leadingIconPath:
                              'assets/images/icons/capsule_creation/privacy_icon.png',
                          screenWidth: screenWidth,
                        ),
                        _settingsRow(
                          context,
                          true,
                          'Open At',
                          infoText: _openAt != null
                              ? DateFormat(
                                  'yyyy-MM-dd',
                                ).format(_openAt!.toDate())
                              : "Select date",
                          leadingIconPath:
                              'assets/images/icons/capsule_creation/timer_icon.png',
                          onTap: () => _pickOpenDate(context),
                          screenWidth: screenWidth,
                        ),
                        _settingsRow(
                          context,
                          false,
                          'Color',
                          infoText: _color.label,
                          infoLeadingIconPath:
                              'assets/images/icons/capsule_creation/pin_${_color.label.toLowerCase()}_icon.png',
                          leadingIconPath:
                              'assets/images/icons/capsule_creation/pin_color_icon.png',
                          onTap: _cycleColor,
                          screenWidth: screenWidth,
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
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
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
        isScheduled: true,
        openAt: _openAt,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        location: GeoPoint(
          _pickedLocation!.latitude,
          _pickedLocation!.longitude,
        ),
        privacy: _privacy,
        color: _color.label.toLowerCase(),
      );
      final capsuleMap = capsule.toMap();
      capsuleMap['privacy'] = _privacy.name;

      await FirebaseFirestore.instance
          .collection('capsules')
          .doc(capsuleId)
          .set(capsuleMap);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to save capsule: $e")));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }
}

Widget _settingsRow(
  BuildContext context,
  bool withDivider,
  String title, {
  VoidCallback? onTap,
  required double screenWidth,
  String? leadingIconPath,
  required String infoText,
  String? infoLeadingIconPath,
}) {
  return Column(
    children: [
      Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: ListTile(
          dense: true,
          minVerticalPadding: 12,
          visualDensity: const VisualDensity(vertical: -3),
          leading: leadingIconPath != null
              ? Image.asset(
                  leadingIconPath,
                  width: screenWidth * 0.07,
                  height: screenWidth * 0.07,
                )
              : null,
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.045,
              fontFamily: 'Irina',
              color: Colors.black,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                  color: Color.fromARGB(217, 217, 217, 217),
                ),
                width: screenWidth * 0.3,
                alignment: Alignment.centerRight,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Text(
                            infoText,
                            style: const TextStyle(
                              fontSize: 35,
                              fontFamily: 'Irina',
                              color: Color.fromARGB(255, 106, 106, 106),
                            ),
                          ),
                          if (infoLeadingIconPath != null) SizedBox(width: 8),
                          if (infoLeadingIconPath != null)
                            Image.asset(
                              infoLeadingIconPath,
                              width: screenWidth * 0.1,
                              height: screenWidth * 0.1,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          contentPadding: EdgeInsets.only(
            left: screenWidth * 0.05,
            right: screenWidth * 0.03,
          ),
          onTap: onTap,
        ),
      ),
      if (withDivider)
        const Divider(
          height: 1,
          thickness: 1,
          indent: 0,
          endIndent: 0,
          color: Color.fromARGB(255, 211, 211, 211),
        ),
    ],
  );
}
