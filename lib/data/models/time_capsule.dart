import 'package:cloud_firestore/cloud_firestore.dart';

enum CapsulePrivacy { private, friends, public }

class TimeCapsule {
  final String id;
  final String ownerId;
  final String imageUrl;
  final String? description;
  final GeoPoint location;
  final CapsulePrivacy privacy;

  TimeCapsule({
    required this.id,
    required this.ownerId,
    required this.imageUrl,
    this.description,
    required this.location,
    required this.privacy,
  });

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'imageUrl': imageUrl,
    'description': description,
    'location': location,
    'privacy': privacy.toString().split('.').last,
  };

  static TimeCapsule fromMap(String id, Map<String, dynamic> map) =>
      TimeCapsule(
        id: id,
        ownerId: map['ownerId'],
        imageUrl: map['imageUrl'],
        description: map['description'],
        location: map['location'],
        privacy: CapsulePrivacy.values.firstWhere(
          (e) => e.toString().split('.').last == map['privacy'],
        ),
      );
}
