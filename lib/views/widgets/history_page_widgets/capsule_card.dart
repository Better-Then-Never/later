import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class CapsuleCard extends StatelessWidget {
  final String capsuleId;
  final Map<String, dynamic> data;
  final bool isSelected;
  final bool isSelectMode;
  final VoidCallback? onSelectToggle;
  final VoidCallback? onTap;
  final Position? userPosition;

  const CapsuleCard({
    super.key,
    required this.capsuleId,
    required this.data,
    this.isSelected = false,
    this.isSelectMode = false,
    this.onSelectToggle,
    this.onTap,
    this.userPosition,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Untitled';
    final openAt = data['openAt'];
    final location = data['location'] as GeoPoint?;
    final privacy = data['privacy'] ?? 'private';
    final imageUrl = data['imageUrl'] ?? '';
    final opensIn = _calculateOpensIn(openAt);
    final createdAt = data['createdAt'] as Timestamp?;
    final pinColorString = (data['color'] ?? 'green').toString().toLowerCase();

    // Map color string to asset
    String _getPinAsset(String color) {
      switch (color) {
        case 'red':
          return 'assets/images/icons/capsule_creation/pin_red_icon.png';
        case 'yellow':
          return 'assets/images/icons/capsule_creation/pin_yellow_icon.png';
        case 'blue':
          return 'assets/images/icons/capsule_creation/pin_blue_icon.png';
        case 'green':
          return 'assets/images/icons/capsule_creation/pin_green_icon.png';
        case 'orange':
          return 'assets/images/icons/capsule_creation/pin_orange_icon.png';
        case 'purple':
          return 'assets/images/icons/capsule_creation/pin_purple_icon.png';
        case 'pink':
          return 'assets/images/icons/capsule_creation/pin_pink_icon.png';
        default:
          return 'assets/images/icons/capsule_creation/pin_green_icon.png';
      }
    }

    Widget locationPill = FutureBuilder<List<Placemark>>(
      future: location != null
          ? placemarkFromCoordinates(location.latitude, location.longitude)
          : Future.value([]),
      builder: (context, snapshot) {
        String locationLabel = 'Somewhere';
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final p = snapshot.data!.first;
          locationLabel =
              p.locality ??
              p.subAdministrativeArea ??
              p.administrativeArea ??
              'Somewhere';
        }
        return Container(
          width: 130,
          height: 37,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 217, 0),
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              locationLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        );
      },
    );

    Widget datePill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 86, 201, 46),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        _formatTimestamp(createdAt),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
    Widget capsuleImage = Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: imageUrl.isNotEmpty
              ? ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Image.network(
                    imageUrl,
                    width: 70,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(
                  width: 70,
                  height: 100,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
        ),
        // Center the lock/opened icon over the image
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(128),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Image.asset(
                (opensIn == 'Opened' || opensIn == 'Not scheduled')
                    ? 'assets/images/icons/history_page/opened.png'
                    : 'assets/images/icons/history_page/locked.png',
                width: 40,
                height: 40,
              ),
            ),
          ),
        ),
      ],
    );
    double? distanceKm;
if (userPosition != null && location != null) {
  distanceKm = Geolocator.distanceBetween(
    userPosition!.latitude,
    userPosition!.longitude,
    location.latitude,
    location.longitude,
  ) / 1000;
}
Widget distanceRow = Row(
  children: [
    Image.asset(
      'assets/images/icons/capsule_creation/location_icon.png',
      width: 24,
      height: 24,
      color: Colors.black,
    ),
    const SizedBox(width: 7),
    const Text(
      'Distance:',
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
    ),
    const SizedBox(width: 2),
    Text(
      distanceKm != null ? '${distanceKm.toStringAsFixed(1)}km' : '...',
      style: const TextStyle(fontSize: 22),
    ),
  ],
);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title, date, location in one row
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 2, top: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Date, location, and pin in one row
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      datePill,
                      const SizedBox(width: 6),
                      locationPill,
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Color',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Image.asset(
                              _getPinAsset(pinColorString),
                              width: 18,
                              height: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  color: Colors.black,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: capsuleImage,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/icons/capsule_creation/timer_icon.png',
                                width: 24,
                                height: 24,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 7),
                              const Text(
                                'Opens in:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                opensIn,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          distanceRow,
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/icons/capsule_creation/privacy_icon.png',
                                width: 24,
                                height: 24,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 7),
                              const Text(
                                'Visibility:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                privacy,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isSelectMode)
            Positioned.fill(
              child: GestureDetector(
                onTap: onSelectToggle,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                  ),
                  child: isSelected
                      ? const Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.check_circle, color: Colors.blue),
                          ),
                        )
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'No date';
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _calculateOpensIn(dynamic openAt) {
    if (openAt == null) return 'Not scheduled';
    try {
      DateTime openDate;
      if (openAt is Timestamp) {
        openDate = openAt.toDate();
      } else if (openAt is String) {
        openDate = DateTime.parse(openAt);
      } else {
        return 'Not scheduled';
      }
      final now = DateTime.now();
      final difference = openDate.difference(now);
      if (difference.isNegative) return 'Opened';
      final days = difference.inDays;
      final hours = difference.inHours % 24;
      return '${days}d ${hours}h';
    } catch (e) {
      return 'Not scheduled';
    }
  }
}
