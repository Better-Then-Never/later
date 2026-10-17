import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/models/capsule.dart';
import '../../../data/models/geo_position.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/location_service.dart';
import '../../map/current_location.dart';

/// State of the "Create Capsule" screen.
///
/// Fixes BUG-054 (double tap created two capsules: saving is re-entrant
/// safe), BUG-055 (compressed upload with content type, temp photo deleted,
/// orphan image removed on failure — in the repository), BUG-056 (no raw
/// exception text) and BUG-058 (controllers disposed, no setState after
/// dispose). Firebase is reached only through [CapsuleRepository].
class CapsuleCreationController extends ChangeNotifier {
  CapsuleCreationController({
    required this.ownerId,
    required this.imagePath,
    required CapsuleRepository capsules,
    required LocationService location,
    required CurrentLocation currentLocation,
    CapsulePrivacy? initialPrivacy,
    this.recipientId,
    ChatRepository? chats,
    this.locationPrecision = LocationPrecision.exact,
    DateTime? capturedAt,
  }) : assert(recipientId == null || chats != null),
       capturedAt = capturedAt ?? DateTime.now(),
       _capsules = capsules,
       _chats = chats,
       _location = location,
       _currentLocation = currentLocation,
       // A capsule for a friend is private (only the two of you) by default.
       _privacy =
           initialPrivacy ??
           (recipientId != null
               ? CapsulePrivacy.private
               : CapsulePrivacy.public),
       _position = currentLocation.position {
    if (_position == null) unawaited(_locate());
  }

  final String ownerId;
  final String imagePath;

  /// Settings > Privacy: approximate places are rounded before upload.
  final LocationPrecision locationPrecision;

  /// When the photo was taken (the page opens right after the shutter).
  final DateTime capturedAt;

  /// The friend this capsule is sent to: it is shared with them and posted
  /// into your chat.
  final String? recipientId;
  final CapsuleRepository _capsules;
  final ChatRepository? _chats;
  final LocationService _location;
  final CurrentLocation _currentLocation;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  CapsulePrivacy _privacy;
  CapsuleColor _color = CapsuleColor.red;
  DateTime? _openAt;
  GeoPosition? _position;
  bool _saving = false;
  bool _disposed = false;

  /// Set once the capsule exists, so a retry after a failed chat post does
  /// not create it twice.
  Capsule? _created;

  CapsulePrivacy get privacy => _privacy;
  CapsuleColor get color => _color;
  DateTime? get openAt => _openAt;
  GeoPosition? get position => _position;
  bool get isSaving => _saving;

  void cyclePrivacy() {
    const values = CapsulePrivacy.values;
    _privacy = values[(values.indexOf(_privacy) + 1) % values.length];
    notifyListeners();
  }

  void cycleColor() {
    const values = CapsuleColor.values;
    _color = values[(values.indexOf(_color) + 1) % values.length];
    notifyListeners();
  }

  /// The chosen day at the current time of day (as before), from tomorrow.
  void setOpenDate(DateTime day) {
    final now = DateTime.now();
    _openAt = DateTime(
      day.year,
      day.month,
      day.day,
      now.hour,
      now.minute,
      now.second,
    );
    notifyListeners();
  }

  Future<void> _locate() async {
    final position = await _location.currentPosition();
    if (_disposed || position == null || !position.isValid) return;
    _currentLocation.update(position);
    _position = position;
    notifyListeners();
  }

  /// Creates the capsule. Returns null on success, the failure otherwise;
  /// calls while a save is running are ignored.
  Future<AppFailure?> save() async {
    if (_saving) return null;
    _saving = true;
    notifyListeners();
    try {
      if (_position == null) await _locate();
      final position = _position;
      if (position == null) {
        return ValidationFailure(AppL10n.current.capsulesErrorNoLocation);
      }
      final title = titleController.text.trim();
      final description = descriptionController.text.trim();
      final capsule = _created ??= await _capsules.create(
        CapsuleDraft(
          ownerId: ownerId,
          title: title.isEmpty ? AppL10n.current.capsulesDefaultTitle : title,
          description: description.isEmpty ? null : description,
          privacy: _privacy,
          color: _color,
          location: locationPrecision == LocationPrecision.approximate
              ? position.approximate
              : position,
          locationPrecision: locationPrecision,
          imagePath: imagePath,
          openAt: _openAt,
          recipientId: recipientId,
          capturedAt: capturedAt,
          utcOffsetMinutes: capturedAt.timeZoneOffset.inMinutes,
        ),
      );
      final to = recipientId;
      if (to != null) {
        try {
          await _chats!.sendCapsule(from: ownerId, to: to, capsule: capsule);
        } catch (e, st) {
          AppLogger.warning(
            'Posting the capsule to the chat failed',
            error: e,
            stackTrace: st,
          );
          return AppFailure.from(
            e,
            fallbackMessage: AppL10n.current.capsulesErrorSavedNotSent,
          );
        }
      }
      unawaited(_deleteTempPhoto());
      return null;
    } catch (e, st) {
      AppLogger.error('Saving the capsule failed', error: e, stackTrace: st);
      return AppFailure.from(
        e,
        fallbackMessage: AppL10n.current.capsulesErrorSaveFailed,
      );
    } finally {
      _saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _deleteTempPhoto() async {
    try {
      final file = File(imagePath);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // The OS cleans the cache directory eventually.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
