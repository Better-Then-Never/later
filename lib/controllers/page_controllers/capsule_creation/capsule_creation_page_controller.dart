import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:later/data/models/time_capsule.dart';
import 'package:later/services/chat_service.dart';
import 'package:later/services/popup_notification_service.dart';
import 'package:later/views/pages/navbar_pages/map_page.dart' as map;

class CapsuleCreationPageController extends ChangeNotifier {
  final String uid;
  final String imagePath;
  final String? recipientId;

  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  CapsulePrivacy privacy;
  CapsuleColor color;
  Timestamp? openAt;
  LatLng? pickedLocation;

  bool isSaving = false;

  bool get isSendingToFriend => recipientId != null;

  CapsuleCreationPageController({
    required this.uid,
    required this.imagePath,
    this.recipientId,
    CapsulePrivacy? initialPrivacy,
    CapsuleColor? initialColor,
    LatLng? initialLocation,
  }) : privacy = initialPrivacy ?? (recipientId != null ? CapsulePrivacy.private : CapsulePrivacy.public),
       color = initialColor ?? CapsuleColor.red,
       pickedLocation = initialLocation ?? map.MapPage.currentPositionStatic;

  void cyclePrivacy() {
    final values = CapsulePrivacy.values;
    privacy = values[(values.indexOf(privacy) + 1) % values.length];
    notifyListeners();
  }

  void cycleColor() {
    final values = CapsuleColor.values;
    color = values[(values.indexOf(color) + 1) % values.length];
    notifyListeners();
  }

  void setOpenAt(Timestamp timestamp) {
    openAt = timestamp;
    notifyListeners();
  }

  void setPickedLocation(LatLng location) {
    pickedLocation = location;
    notifyListeners();
  }

  Future<void> pickOpenDate(BuildContext context) async {
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
      setOpenAt(Timestamp.fromDate(chosenDateTime));
    }
  }

  Future<void> saveCapsule(BuildContext context) async {
    if (pickedLocation == null) {
      PopupNotificationService.showError(
        context: context,
        message: 'We could not detect your location',
        position: NotificationPosition.center,
      );
      return;
    }

    isSaving = true;
    notifyListeners();
    try {
      final capsuleId = FirebaseFirestore.instance
          .collection('capsules')
          .doc()
          .id;

      final ref = FirebaseStorage.instance.ref().child(
        'userdata/$uid/capsules/$capsuleId/image.jpg',
      );
      await ref.putFile(File(imagePath));
      final imageUrl = await ref.getDownloadURL();

      final capsule = TimeCapsule(
        id: capsuleId,
        ownerId: uid,
        imageUrl: imageUrl,
        title: titleController.text.isEmpty ? 'Capsule' : titleController.text,
        createdAt: Timestamp.now(),
        isScheduled: true,
        openAt: openAt,
        description: descriptionController.text.isEmpty
            ? null
            : descriptionController.text,
        location: GeoPoint(pickedLocation!.latitude, pickedLocation!.longitude),
        privacy: privacy,
        color: color,
        sharedWith: recipientId != null ? [uid, recipientId!] : null,
      );

      final capsuleMap = capsule.toMap();
      capsuleMap['privacy'] = privacy.name;

      await FirebaseFirestore.instance
          .collection('capsules')
          .doc(capsuleId)
          .set(capsuleMap);

      if (recipientId != null) {
        final chatService = ChatService();
        final chatId = ChatService.makeChatId(uid, recipientId!);
        await chatService.sendCapsuleMessage(
          chatId: chatId,
          otherUserId: recipientId!,
          capsuleId: capsuleId,
          capsuleTitle: capsule.title,
          capsuleImageUrl: imageUrl,
        );
      }

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        PopupNotificationService.showError(
          context: context,
          message: 'Failed to save capsule: $e',
          position: NotificationPosition.center,
        );
      }
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
