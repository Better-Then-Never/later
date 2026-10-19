import 'geo_position.dart';

enum CapsulePrivacy {
  private,
  friends,
  public;

  /// Tolerant parser: unknown or missing values become [fallback].
  static CapsulePrivacy parse(Object? value, {CapsulePrivacy? fallback}) {
    for (final p in values) {
      if (p.name == value) return p;
    }
    return fallback ?? CapsulePrivacy.friends;
  }
}

/// How exactly a capsule records where it was made.
enum LocationPrecision {
  exact,

  /// Rounded to about a kilometre before it leaves the phone.
  approximate;

  static LocationPrecision parse(Object? value) =>
      value == approximate.name ? approximate : exact;
}

/// The six reactions (functions/lib/social.js REACTIONS).
enum ReactionType {
  heart('❤️'),
  laugh('😂'),
  wow('😮'),
  sad('😢'),
  fire('🔥'),
  clap('👏');

  const ReactionType(this.emoji);

  final String emoji;

  static ReactionType? parse(Object? value) {
    for (final r in values) {
      if (r.name == value) return r;
    }
    return null;
  }
}

enum CapsuleColor {
  red,
  blue,
  green,
  yellow,
  orange,
  purple;

  static CapsuleColor parse(Object? value, {CapsuleColor? fallback}) {
    for (final c in values) {
      if (c.name == value) return c;
    }
    return fallback ?? CapsuleColor.red;
  }
}

/// A friends-only or public capsule that was deleted
/// (`capsule_deletions/{id}`, functions/lib/mapsync.js).
class CapsuleDeletion {
  const CapsuleDeletion(this.id, this.deletedAt);

  final String id;
  final DateTime deletedAt;
}

/// A time capsule (`capsules/{id}`).
class Capsule {
  const Capsule({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.privacy,
    required this.color,
    this.imageUrl,
    this.description,
    this.location,
    this.createdAt,
    this.openAt,
    this.isScheduled = false,
    this.sharedWith = const [],
    this.capturedAt,
    this.utcOffsetMinutes,
    this.showAuthor = true,
    this.allowComments = true,
    this.allowReactions = true,
    this.locationPrecision = LocationPrecision.exact,
    this.frames = const [],
    this.frameDelayMs = defaultFrameDelayMs,
    this.thumbUrl,
    this.placeName,
    this.reactionCounts = const {},
    this.reactionTotal = 0,
    this.commentCount = 0,
    this.pending = false,
    this.coAuthors = const [],
  });

  /// Most co-authors a capsule may have (firestore.rules).
  static const maxCoAuthors = 5;

  /// Friends of the owner who made it with them; they see it like the owner
  /// and may take themselves off it.
  final List<String> coAuthors;

  /// Pause between the frames of a loop capsule.
  static const defaultFrameDelayMs = 300;

  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final String? imageUrl;
  final GeoPosition? location;
  final CapsulePrivacy privacy;
  final CapsuleColor color;

  /// Null only while a server timestamp is pending or for malformed docs.
  final DateTime? createdAt;

  /// When the capsule opens. Null means "already open" (current behaviour).
  final DateTime? openAt;
  final bool isScheduled;

  /// For a capsule sent to a friend: the sender and the recipient. Private
  /// capsules are visible to everyone listed here.
  final List<String> sharedWith;

  /// When the photo was taken (differs from [createdAt] for a capsule saved
  /// offline and uploaded later). Null on older capsules.
  final DateTime? capturedAt;

  /// The device's offset from UTC when the photo was taken.
  final int? utcOffsetMinutes;

  /// False: shown without the author's name and avatar to others.
  final bool showAuthor;
  final bool allowComments;
  final bool allowReactions;
  final LocationPrecision locationPrecision;

  /// Image URLs of a loop capsule, in order (empty for a single photo).
  final List<String> frames;
  final int frameDelayMs;

  /// A small version of the image for lists and markers.
  final String? thumbUrl;

  /// Where it was made, in words ("Old Town, Warsaw").
  final String? placeName;

  /// Counted by the Cloud Functions.
  final Map<ReactionType, int> reactionCounts;
  final int reactionTotal;
  final int commentCount;

  /// Saved on this phone and waiting for a connection (offline outbox);
  /// never stored.
  final bool pending;

  /// When the moment happened: the capture time, else the upload time.
  DateTime? get takenAt => capturedAt ?? createdAt;

  bool get isLoop => frames.length > 1;

  bool isOpen(DateTime now) => openAt == null || !openAt!.isAfter(now);

  Duration timeUntilOpen(DateTime now) =>
      isOpen(now) ? Duration.zero : openAt!.difference(now);

  Capsule copyWith({
    String? imageUrl,
    Map<ReactionType, int>? reactionCounts,
    int? reactionTotal,
    int? commentCount,
    List<String>? coAuthors,
  }) => Capsule(
    id: id,
    ownerId: ownerId,
    title: title,
    privacy: privacy,
    color: color,
    imageUrl: imageUrl ?? this.imageUrl,
    description: description,
    location: location,
    createdAt: createdAt,
    openAt: openAt,
    isScheduled: isScheduled,
    sharedWith: sharedWith,
    capturedAt: capturedAt,
    utcOffsetMinutes: utcOffsetMinutes,
    showAuthor: showAuthor,
    coAuthors: coAuthors ?? this.coAuthors,
    allowComments: allowComments,
    allowReactions: allowReactions,
    locationPrecision: locationPrecision,
    frames: frames,
    frameDelayMs: frameDelayMs,
    thumbUrl: thumbUrl,
    placeName: placeName,
    reactionCounts: reactionCounts ?? this.reactionCounts,
    reactionTotal: reactionTotal ?? this.reactionTotal,
    commentCount: commentCount ?? this.commentCount,
  );

  @override
  bool operator ==(Object other) =>
      other is Capsule &&
      other.id == id &&
      other.ownerId == ownerId &&
      other.title == title &&
      other.description == description &&
      other.imageUrl == imageUrl &&
      other.location == location &&
      other.privacy == privacy &&
      other.color == color &&
      other.createdAt == createdAt &&
      other.openAt == openAt &&
      other.isScheduled == isScheduled &&
      other.sharedWith.length == sharedWith.length &&
      other.sharedWith.every(sharedWith.contains) &&
      other.capturedAt == capturedAt &&
      other.utcOffsetMinutes == utcOffsetMinutes &&
      other.showAuthor == showAuthor &&
      _listEquals(other.coAuthors, coAuthors) &&
      other.allowComments == allowComments &&
      other.allowReactions == allowReactions &&
      other.locationPrecision == locationPrecision &&
      _listEquals(other.frames, frames) &&
      other.frameDelayMs == frameDelayMs &&
      other.thumbUrl == thumbUrl &&
      other.placeName == placeName &&
      _mapEquals(other.reactionCounts, reactionCounts) &&
      other.reactionTotal == reactionTotal &&
      other.commentCount == commentCount;

  @override
  int get hashCode => Object.hash(
    id,
    ownerId,
    title,
    description,
    imageUrl,
    location,
    privacy,
    color,
    createdAt,
    openAt,
    isScheduled,
    capturedAt,
    reactionTotal,
    commentCount,
    frames.length,
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

/// Data entered on the creation screen, before the capsule exists.
class CapsuleDraft {
  const CapsuleDraft({
    required this.ownerId,
    required this.title,
    required this.privacy,
    required this.color,
    required this.location,
    required this.imagePath,
    this.id,
    this.description,
    this.openAt,
    this.recipientId,
    this.capturedAt,
    this.utcOffsetMinutes,
    this.showAuthor = true,
    this.allowComments = true,
    this.allowReactions = true,
    this.locationPrecision = LocationPrecision.exact,
    this.framePaths = const [],
    this.frameDelayMs = Capsule.defaultFrameDelayMs,
    this.placeName,
    this.countryCode,
    this.coAuthors = const [],
    this.highQuality = false,
  });

  /// Friends who made it with the owner (at most [Capsule.maxCoAuthors]).
  final List<String> coAuthors;

  /// The photo goes up larger and sharper (Settings > Map and camera).
  final bool highQuality;

  final String ownerId;
  final String title;
  final String? description;
  final CapsulePrivacy privacy;
  final CapsuleColor color;
  final GeoPosition location;
  final String imagePath;
  final DateTime? openAt;

  /// The friend this capsule is sent to, if any.
  final String? recipientId;

  /// When the photo was taken and the device's UTC offset then (streaks
  /// count the capture day, even when the upload happens later).
  final DateTime? capturedAt;
  final int? utcOffsetMinutes;
  final bool showAuthor;
  final bool allowComments;
  final bool allowReactions;

  /// [location] is already rounded when approximate; this records it.
  final LocationPrecision locationPrecision;

  /// The capsule's id, chosen before the upload so a retry (offline outbox)
  /// writes the same document instead of a second one. Null: a new id.
  final String? id;

  CapsuleDraft copyWith({
    String? id,
    String? imagePath,
    List<String>? framePaths,
  }) => CapsuleDraft(
    ownerId: ownerId,
    title: title,
    privacy: privacy,
    color: color,
    location: location,
    imagePath: imagePath ?? this.imagePath,
    id: id ?? this.id,
    description: description,
    openAt: openAt,
    recipientId: recipientId,
    capturedAt: capturedAt,
    utcOffsetMinutes: utcOffsetMinutes,
    showAuthor: showAuthor,
    allowComments: allowComments,
    allowReactions: allowReactions,
    locationPrecision: locationPrecision,
    framePaths: framePaths ?? this.framePaths,
    frameDelayMs: frameDelayMs,
    placeName: placeName,
    countryCode: countryCode,
    coAuthors: coAuthors,
    highQuality: highQuality,
  );

  /// Local files of a loop capsule, in order; [imagePath] is the first.
  final List<String> framePaths;
  final int frameDelayMs;

  /// The town and country (ISO "PL") from the phone's geocoder, for the
  /// world view (B7); either may be missing.
  final String? placeName;
  final String? countryCode;
}
