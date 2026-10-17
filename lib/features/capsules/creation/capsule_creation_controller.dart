import 'dart:async';
import 'dart:math' as math;
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
import '../outbox/capsule_outbox.dart';

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
    this.framePaths = const [],
    required CapsuleRepository capsules,
    required LocationService location,
    required CurrentLocation currentLocation,
    CapsulePrivacy? initialPrivacy,
    this.recipientId,
    ChatRepository? chats,
    LocationPrecision locationPrecision = LocationPrecision.exact,
    DateTime? capturedAt,
    CapsuleOutbox? outbox,
    this.uploadTimeout = const Duration(seconds: 20),
  }) : assert(recipientId == null || chats != null),
       _outbox = outbox,
       _precision = locationPrecision,
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

  /// The frames of a loop capsule (the first is [imagePath]); empty for a
  /// photo.
  final List<String> framePaths;
  bool get isLoop => framePaths.length > 1;

  /// Keeps the capsule on the phone when there is no connection (F-26).
  final CapsuleOutbox? _outbox;

  /// How long an upload may take before the capsule goes to the outbox.
  final Duration uploadTimeout;

  /// Fixed before the first attempt, so a retry (here or from the outbox)
  /// writes the same capsule.
  late final String _id = _capsules.newCapsuleId();

  bool _queued = false;

  /// The last save kept the capsule on the phone, to upload later.
  bool get queued => _queued;

  /// Starts from Settings > Privacy; approximate places are rounded before
  /// upload.
  LocationPrecision _precision;
  LocationPrecision get locationPrecision => _precision;

  /// What others may do with the capsule (F-29).
  bool _allowComments = true;
  bool _allowReactions = true;
  bool get allowComments => _allowComments;
  bool get allowReactions => _allowReactions;

  set allowComments(bool value) {
    _allowComments = value;
    notifyListeners();
  }

  set allowReactions(bool value) {
    _allowReactions = value;
    notifyListeners();
  }

  /// Others see who left it (F-60).
  bool _showAuthor = true;
  bool get showAuthor => _showAuthor;

  set showAuthor(bool value) {
    _showAuthor = value;
    notifyListeners();
  }

  set approximateLocation(bool value) {
    _precision = value
        ? LocationPrecision.approximate
        : LocationPrecision.exact;
    notifyListeners();
  }

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

  set privacy(CapsulePrivacy value) {
    if (value == _privacy) return;
    _privacy = value;
    notifyListeners();
  }

  set color(CapsuleColor value) {
    if (value == _color) return;
    _color = value;
    notifyListeners();
  }

  /// No open date: the capsule is open as soon as it exists.
  void clearOpenDate() {
    if (_openAt == null) return;
    _openAt = null;
    notifyListeners();
  }

  /// [from] plus [months] calendar months, on the same day when that month
  /// has it, else on its last day (31 January + 1 month = 28/29 February).
  static DateTime addMonths(DateTime from, int months) {
    final first = DateTime(from.year, from.month + months);
    final lastDay = DateTime(first.year, first.month + 1, 0).day;
    return DateTime(first.year, first.month, math.min(from.day, lastDay));
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
    // A capsule needs a place: ask for the permission here if the
    // onboarding step was skipped.
    final position = await _location.currentPosition(request: true);
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
      final draft = CapsuleDraft(
        id: _id,
        ownerId: ownerId,
        title: title.isEmpty ? AppL10n.current.capsulesDefaultTitle : title,
        description: description.isEmpty ? null : description,
        privacy: _privacy,
        color: _color,
        location: locationPrecision == LocationPrecision.approximate
            ? position.approximate
            : position,
        locationPrecision: locationPrecision,
        allowComments: _allowComments,
        allowReactions: _allowReactions,
        showAuthor: _showAuthor,
        imagePath: imagePath,
        framePaths: framePaths,
        openAt: _openAt,
        recipientId: recipientId,
        capturedAt: capturedAt,
        utcOffsetMinutes: capturedAt.timeZoneOffset.inMinutes,
      );
      final Capsule capsule;
      try {
        capsule = _created ??= await _capsules
            .create(draft)
            .timeout(uploadTimeout);
      } catch (e) {
        final outbox = _outbox;
        // No connection: keep it on the phone (not for a friend: the chat
        // post needs the connection too).
        if (outbox == null ||
            recipientId != null ||
            !CapsuleOutbox.isOffline(e)) {
          rethrow;
        }
        AppLogger.info('No connection: capsule $_id kept for later');
        await outbox.enqueue(draft);
        _queued = true;
        unawaited(_deleteTempPhoto());
        return null;
      }
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
    for (final path in {imagePath, ...framePaths}) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // The OS cleans the cache directory eventually.
      }
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
