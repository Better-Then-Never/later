import 'package:cloud_firestore/cloud_firestore.dart';

enum CapsulePrivacy { private, friends, public }

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
  final String color;

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
    'color': color,
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
        openAt: map['openAt'], // can be null
        color: map['color'] ?? 'red', // default if missing
      );
}
