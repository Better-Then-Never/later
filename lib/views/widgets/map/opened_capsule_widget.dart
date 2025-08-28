import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:later/views/widgets/capsule_creation/capsule_creation_location_label.dart';
import 'package:later/views/widgets/capsule_creation/capsule_creation_datestamp.dart';

class CapsulePreviewCard extends StatelessWidget {
  final Map<String, dynamic> capsuleData;

  const CapsulePreviewCard({super.key, required this.capsuleData});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final String title = capsuleData['title'] ?? 'Capsule';
    final String? description = capsuleData['description'];
    final String? imageUrl = capsuleData['imageUrl'];

    final LatLng? location = capsuleData['location'] != null
        ? LatLng(
            capsuleData['location'].latitude,
            capsuleData['location'].longitude,
          )
        : null;

    return Container(
      width: screenWidth,
      height: screenHeight * 0.45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(25)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          if (imageUrl != null)
            SizedBox(
              width: screenWidth * 0.45,
              height: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(imageUrl, fit: BoxFit.cover),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Irina',
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      description ?? 'This capsule has no description.',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Irina',
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                CapsuleCreationLocationLabel(
                  height: screenHeight * 0.05,
                  iconPath:
                      'assets/images/icons/capsule_creation/location_icon.png',
                  location: location,
                ),
                const SizedBox(height: 8),
                CapsuleCreationDateStamp(
                  height: screenHeight * 0.05,
                  date: capsuleData['createdAt']?.toDate(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
