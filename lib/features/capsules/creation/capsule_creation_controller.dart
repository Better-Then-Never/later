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
import '../../../data/services/gallery_service.dart';
import '../../../data/services/geocoding_service.dart';
import '../../../data/services/location_service.dart';
import '../../map/current_location.dart';
import '../outbox/capsule_outbox.dart';
import 'creation_draft.dart';

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
    required String imagePath,
    List<String> framePaths = const [],
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
    this.highQuality = false,
    this.saveToGallery = false,
    GalleryService? gallery,
    GeocodingService? geocoding,
    CreationDraftStore? drafts,
    CreationDraft? draft,
  }) : assert(recipientId == null || chats != null),
       _drafts = drafts,
       _photoPath = imagePath,
       _frames = List.of(framePaths),
       _taken = {imagePath, ...framePaths},
       _outbox = outbox,
       _gallery = gallery,
       _geocoding = geocoding,
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
    if (draft != null) _restore(draft);
    if (_position == null) unawaited(_locate());
    _askPlace();
    if (_drafts != null) {
      addListener(_draftChanged);
      titleController.addListener(_draftChanged);
      descriptionController.addListener(_draftChanged);
      // The photo alone is worth keeping.
      _draftChanged();
    }
  }

  final String ownerId;
  final String _photoPath;
  final List<String> _frames;

  /// Every file the camera made for this capsule, removed frames too, so
  /// they are all deleted at the end.
  final Set<String> _taken;

  /// The photo, or the first frame of a loop (its picture in lists).
  String get imagePath => isLoop ? _frames.first : _photoPath;

  /// The frames of a loop capsule (the first is [imagePath]); empty for a
  /// photo.
  List<String> get framePaths => List.unmodifiable(_frames);
  bool get isLoop => _frames.length > 1;

  /// A loop keeps at least two frames.
  bool get canRemoveFrame => _frames.length > 2;

  void removeFrame(int index) {
    if (!canRemoveFrame || index < 0 || index >= _frames.length) return;
    _frames.removeAt(index);
    notifyListeners();
  }

  /// Moves frame [from] to [to] (indexes as ReorderableListView gives them).
  void moveFrame(int from, int to) {
    if (from < 0 || from >= _frames.length) return;
    final frame = _frames.removeAt(from);
    _frames.insert(to > from ? to - 1 : to, frame);
    notifyListeners();
  }

  /// Pause between frames: slow, normal (the default) or fast.
  static const frameDelays = [500, Capsule.defaultFrameDelayMs, 150];
  int _frameDelayMs = Capsule.defaultFrameDelayMs;
  int get frameDelayMs => _frameDelayMs;

  set frameDelayMs(int value) {
    _frameDelayMs = value.clamp(80, 2000);
    notifyListeners();
  }

  /// Keeps the capsule on the phone when there is no connection (F-26).
  final CapsuleOutbox? _outbox;

  /// How long an upload may take before the capsule goes to the outbox.
  final Duration uploadTimeout;

  /// The photo goes up larger (Settings > Map and camera).
  final bool highQuality;

  /// The photo also goes to the phone's gallery once the capsule is made
  /// (or kept for later): the phone's own copy is deleted afterwards.
  final bool saveToGallery;
  final GalleryService? _gallery;

  /// The town and country for the world view (B7).
  final GeocodingService? _geocoding;

  /// Where the capsule will be stored: rounded when approximate.
  GeoPosition? get _stored {
    final position = _position;
    if (position == null) return null;
    return _precision == LocationPrecision.approximate
        ? position.approximate
        : position;
  }

  /// Asks the geocoder early (it caches), so saving rarely waits for it.
  void _askPlace() {
    final spot = _stored;
    final geocoding = _geocoding;
    if (spot != null && geocoding != null) unawaited(geocoding.place(spot));
  }

  /// The place of [spot], waiting at most 2 s; null when unknown (offline,
  /// no geocoder): the capsule is then saved without it.
  Future<GeoPlace?> _placeOf(GeoPosition spot) async {
    final geocoding = _geocoding;
    if (geocoding == null) return null;
    try {
      return await geocoding
          .place(spot)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }

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

  /// Friends who made it with the user (at most [Capsule.maxCoAuthors]).
  List<String> _coAuthors = const [];
  List<String> get coAuthors => _coAuthors;

  set coAuthors(List<String> value) {
    _coAuthors = value.take(Capsule.maxCoAuthors).toList();
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

  /// Keeps the capsule as left (B4): saved a second after each change, and
  /// when the page closes, until the capsule is made.
  final CreationDraftStore? _drafts;
  Timer? _draftTimer;
  bool _finished = false;

  /// Camera files copied into the draft folder (camera path -> copy).
  final Map<String, String> _kept = {};

  void _restore(CreationDraft d) {
    titleController.text = d.title;
    descriptionController.text = d.description;
    if (d.privacy case final p?) _privacy = p;
    _color = d.color;
    _openAt = d.openAt;
    _coAuthors = d.coAuthors;
    _allowComments = d.allowComments;
    _allowReactions = d.allowReactions;
    _showAuthor = d.showAuthor;
    _precision = d.locationPrecision;
    _frameDelayMs = d.frameDelayMs;
    if (d.pin case final pin?) {
      _here = _position;
      _position = pin;
    }
  }

  void _draftChanged() {
    if (_drafts == null || _finished || _disposed) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(
      const Duration(seconds: 1),
      () => unawaited(_saveDraft()),
    );
  }

  Future<void> _saveDraft() async {
    final drafts = _drafts;
    if (drafts == null || _finished) return;
    // Read now: the page may be closing (the text fields go with it).
    final photo = imagePath;
    final frames = framePaths;
    final title = titleController.text;
    final description = descriptionController.text;
    final pin = _here == null ? null : _position;
    try {
      final dir = (await drafts.folder(ownerId)).path;
      for (final path in [photo, ...frames]) {
        if (_kept.containsKey(path)) continue;
        if (path.startsWith(dir)) {
          _kept[path] = path;
          continue;
        }
        final name = path.split(RegExp(r'[\\/]')).last;
        final copy = '$dir/${_kept.length}_$name';
        await File(path).copy(copy);
        _kept[path] = copy;
      }
      if (_finished) return;
      await drafts.save(
        ownerId,
        CreationDraft(
          imagePath: _kept[photo]!,
          framePaths: [for (final f in frames) _kept[f]!],
          title: title,
          description: description,
          privacy: _privacy,
          color: _color,
          openAt: _openAt,
          coAuthors: _coAuthors,
          allowComments: _allowComments,
          allowReactions: _allowReactions,
          showAuthor: _showAuthor,
          locationPrecision: _precision,
          frameDelayMs: _frameDelayMs,
          pin: pin,
          recipientId: recipientId,
          capturedAt: capturedAt,
          savedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      AppLogger.debug('Draft not kept: $e');
    }
  }

  /// Made (or kept for later): the draft goes.
  Future<void> _dropDraft() async {
    _finished = true;
    _draftTimer?.cancel();
    await _drafts?.discard(ownerId);
  }

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

  /// Where the phone was when the capsule was made (the pin moves around
  /// it, PinPickerSheet).
  GeoPosition? get here => _here ?? _position;
  GeoPosition? _here;

  /// The capsule goes to [spot] instead of where the phone is.
  void movePin(GeoPosition spot) {
    _here ??= _position;
    if (spot == _position) return;
    _position = spot;
    _askPlace();
    notifyListeners();
  }

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
    _askPlace();
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
      final stored = locationPrecision == LocationPrecision.approximate
          ? position.approximate
          : position;
      final place = await _placeOf(stored);
      final draft = CapsuleDraft(
        id: _id,
        ownerId: ownerId,
        title: title.isEmpty ? AppL10n.current.capsulesDefaultTitle : title,
        description: description.isEmpty ? null : description,
        privacy: _privacy,
        color: _color,
        location: stored,
        locationPrecision: locationPrecision,
        placeName: place?.name,
        countryCode: place?.countryCode,
        allowComments: _allowComments,
        allowReactions: _allowReactions,
        showAuthor: _showAuthor,
        coAuthors: _coAuthors,
        highQuality: highQuality,
        imagePath: imagePath,
        framePaths: framePaths,
        frameDelayMs: _frameDelayMs,
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
        // No connection: keep it on the phone; a friend's capsule goes to
        // the chat once it is uploaded (the outbox posts it).
        if (outbox == null || !CapsuleOutbox.isOffline(e)) rethrow;
        AppLogger.info('No connection: capsule $_id kept for later');
        await outbox.enqueue(draft);
        _queued = true;
        _finished = true;
        unawaited(
          _keepInGallery()
              .whenComplete(_deleteTempPhoto)
              .whenComplete(_dropDraft),
        );
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
      _finished = true;
      unawaited(
        _keepInGallery()
            .whenComplete(_deleteTempPhoto)
            .whenComplete(_dropDraft),
      );
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

  /// The photo into the gallery when the user wants it, before the phone's
  /// own copy is deleted (a waiting capsule's outbox has its own copy).
  Future<void> _keepInGallery() async {
    final gallery = _gallery;
    if (!saveToGallery || gallery == null) return;
    await gallery.save(imagePath, name: 'Later_$_id');
  }

  Future<void> _deleteTempPhoto() async {
    for (final path in _taken) {
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
    // Leaving with a change not kept yet: keep it now.
    if (_draftTimer?.isActive ?? false) {
      _draftTimer!.cancel();
      unawaited(_saveDraft());
    }
    _disposed = true;
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
