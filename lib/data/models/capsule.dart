import 'geo_position.dart';

enum CapsulePrivacy {
  private,
  friends,
  public;

  String get label => switch (this) {
    CapsulePrivacy.public => 'Public',
    CapsulePrivacy.private => 'Private',
    CapsulePrivacy.friends => 'Friends',
  };

  /// Tolerant parser: unknown or missing values become [fallback].
  static CapsulePrivacy parse(Object? value, {CapsulePrivacy? fallback}) {
    for (final p in values) {
      if (p.name == value) return p;
    }
    return fallback ?? CapsulePrivacy.friends;
  }
}

enum CapsuleColor {
  red,
  blue,
  green,
  yellow,
  orange,
  purple;

  String get label => '${name[0].toUpperCase()}${name.substring(1)}';

  static CapsuleColor parse(Object? value, {CapsuleColor? fallback}) {
    for (final c in values) {
      if (c.name == value) return c;
    }
    return fallback ?? CapsuleColor.red;
  }
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
  });

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

  bool isOpen(DateTime now) => openAt == null || !openAt!.isAfter(now);

  Duration timeUntilOpen(DateTime now) =>
      isOpen(now) ? Duration.zero : openAt!.difference(now);

  Capsule copyWith({String? imageUrl}) => Capsule(
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
      other.isScheduled == isScheduled;

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
  );
}

/// Data entered on the creation screen, before the capsule exists.
class CapsuleDraft {
  const CapsuleDraft({
    required this.ownerId,
    required this.title,
    required this.privacy,
    required this.color,
    required this.location,
    required this.imagePath,
    this.description,
    this.openAt,
  });

  final String ownerId;
  final String title;
  final String? description;
  final CapsulePrivacy privacy;
  final CapsuleColor color;
  final GeoPosition location;
  final String imagePath;
  final DateTime? openAt;
}
