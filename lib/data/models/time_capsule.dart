import 'package:cloud_firestore/cloud_firestore.dart';

enum CapsulePrivacy { private, friends, public }

enum CapsuleColor { red, blue, green, yellow, orange, purple}

class TimeCapsule {
  final String id;
  final String ownerId;
  final String imageUrl;
  final String? description;
  final String title;
  final GeoPoint location;
  final CapsulePrivacy privacy;

  final Timestamp createdAt;
  final bool isScheduled;
  final Timestamp? openAt;
  final CapsuleColor color;
  final List<String>? sharedWith;

  TimeCapsule({
    required this.id,
    required this.ownerId,
    required this.imageUrl,
    this.description,
    required this.title,
    required this.location,
    required this.privacy,
    required this.createdAt,
    required this.isScheduled,
    this.openAt,
    required this.color,
    this.sharedWith,
  });

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'imageUrl': imageUrl,
    'description': description,
    'title': title,
    'location': location,
    'privacy': privacy.toString().split('.').last,
    'createdAt': createdAt,
    'isScheduled': isScheduled,
    'openAt': openAt,
    'color': color.name,
    if (sharedWith != null) 'sharedWith': sharedWith,
  };

  static TimeCapsule fromMap(String id, Map<String, dynamic> map) =>
      TimeCapsule(
        id: id,
        ownerId: map['ownerId'],
        imageUrl: map['imageUrl'],
        title: map['title'],
        description: map['description'],
        location: map['location'],
        privacy: CapsulePrivacy.values.firstWhere(
          (e) => e.toString().split('.').last == map['privacy'],
        ),
        createdAt: map['createdAt'] as Timestamp,
        isScheduled: map['isScheduled'] ?? false,
        openAt: map['openAt'],
        color: CapsuleColor.values.firstWhere(
          (c) => c.name == (map['color'] ?? 'red'),
        ),
        sharedWith: (map['sharedWith'] as List<dynamic>?)?.cast<String>(),
      );
}

extension CapsulePrivacyX on CapsulePrivacy {
  String get label {
    switch (this) {
      case CapsulePrivacy.public:
        return "Public";
      case CapsulePrivacy.private:
        return "Private";
      case CapsulePrivacy.friends:
        return "Friends";
    }
  }
}

extension CapsuleColorX on CapsuleColor {
  String get label {
    switch (this) {
      case CapsuleColor.red:
        return "Red";
      case CapsuleColor.blue:
        return "Blue";
      case CapsuleColor.green:
        return "Green";
      case CapsuleColor.yellow:
        return "Yellow";
      case CapsuleColor.orange:
        return "Orange";
      case CapsuleColor.purple:
        return "Purple";
    }
  }
}
