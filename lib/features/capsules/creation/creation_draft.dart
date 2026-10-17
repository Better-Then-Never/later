import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/logging/app_logger.dart';
import '../../../data/models/capsule.dart';
import '../../../data/models/geo_position.dart';

/// A capsule being made, as left (B4): what was typed and chosen, and its
/// photo or frames, kept in the app's documents folder so leaving the page
/// (or the app being closed) loses nothing.
class CreationDraft {
  const CreationDraft({
    required this.imagePath,
    this.framePaths = const [],
    this.title = '',
    this.description = '',
    this.privacy,
    this.color = CapsuleColor.red,
    this.openAt,
    this.coAuthors = const [],
    this.allowComments = true,
    this.allowReactions = true,
    this.showAuthor = true,
    this.locationPrecision = LocationPrecision.exact,
    this.frameDelayMs = Capsule.defaultFrameDelayMs,
    this.pin,
    this.recipientId,
    this.capturedAt,
    this.savedAt,
  });

  final String imagePath;
  final List<String> framePaths;
  final String title;
  final String description;
  final CapsulePrivacy? privacy;
  final CapsuleColor color;
  final DateTime? openAt;
  final List<String> coAuthors;
  final bool allowComments;
  final bool allowReactions;
  final bool showAuthor;
  final LocationPrecision locationPrecision;
  final int frameDelayMs;

  /// Where the pin was moved to (null: where the phone is).
  final GeoPosition? pin;
  final String? recipientId;
  final DateTime? capturedAt;
  final DateTime? savedAt;

  Map<String, Object?> toJson() => {
    'imagePath': imagePath,
    'framePaths': framePaths,
    'title': title,
    'description': description,
    'privacy': ?privacy?.name,
    'color': color.name,
    'openAt': ?openAt?.toIso8601String(),
    'coAuthors': coAuthors,
    'allowComments': allowComments,
    'allowReactions': allowReactions,
    'showAuthor': showAuthor,
    'locationPrecision': locationPrecision.name,
    'frameDelayMs': frameDelayMs,
    if (pin case final p?) 'pin': [p.latitude, p.longitude],
    'recipientId': ?recipientId,
    'capturedAt': ?capturedAt?.toIso8601String(),
    'savedAt': ?savedAt?.toIso8601String(),
  };

  static CreationDraft fromJson(Map<String, Object?> j) {
    DateTime? date(Object? v) => v is String ? DateTime.tryParse(v) : null;
    List<String> strings(Object? v) => [
      for (final s in (v as List?) ?? const [])
        if (s is String) s,
    ];
    final pin = j['pin'];
    return CreationDraft(
      imagePath: j['imagePath']! as String,
      framePaths: strings(j['framePaths']),
      title: j['title'] as String? ?? '',
      description: j['description'] as String? ?? '',
      privacy: j['privacy'] == null ? null : CapsulePrivacy.parse(j['privacy']),
      color: CapsuleColor.parse(j['color']),
      openAt: date(j['openAt']),
      coAuthors: strings(j['coAuthors']),
      allowComments: j['allowComments'] as bool? ?? true,
      allowReactions: j['allowReactions'] as bool? ?? true,
      showAuthor: j['showAuthor'] as bool? ?? true,
      locationPrecision: LocationPrecision.parse(j['locationPrecision']),
      frameDelayMs:
          (j['frameDelayMs'] as num?)?.toInt() ?? Capsule.defaultFrameDelayMs,
      pin: pin is List && pin.length == 2
          ? GeoPosition((pin[0] as num).toDouble(), (pin[1] as num).toDouble())
          : null,
      recipientId: j['recipientId'] as String?,
      capturedAt: date(j['capturedAt']),
      savedAt: date(j['savedAt']),
    );
  }
}

/// One unfinished capsule per account on this phone (documents/drafts/uid).
class CreationDraftStore {
  CreationDraftStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directory;

  Future<Directory> folder(String uid) async {
    final root = await _directory();
    final dir = Directory('${root.path}/drafts/$uid');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _file(String uid) async =>
      File('${(await folder(uid)).path}/draft.json');

  /// The draft left by [uid], if its photo is still there.
  Future<CreationDraft?> load(String uid) async {
    try {
      final file = await _file(uid);
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString()) as Map;
      final draft = CreationDraft.fromJson(json.cast<String, Object?>());
      if (!await File(draft.imagePath).exists()) return null;
      return draft;
    } catch (e) {
      AppLogger.warning('Unreadable capsule draft', error: e);
      return null;
    }
  }

  Future<void> save(String uid, CreationDraft draft) async =>
      (await _file(uid)).writeAsString(jsonEncode(draft.toJson()));

  /// Throws the draft away with its photo and frames.
  Future<void> discard(String uid) async {
    try {
      final dir = await folder(uid);
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (e) {
      AppLogger.debug('Could not delete the draft: $e');
    }
  }
}
