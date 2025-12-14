import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:later/views/pages/navbar_pages/map_page.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/my_profile_page/profile_page_divider.dart';
import 'package:geolocator/geolocator.dart';

class CapsuleListTile extends StatefulWidget {
  final Map<String, dynamic> capsule;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback? onLongPress;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  const CapsuleListTile({
    super.key,
    required this.capsule,
    this.onTap,
    this.isSelected = false,
    this.selectionMode = false,
    this.onLongPress,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  @override
  State<CapsuleListTile> createState() => _CapsuleListTileState();
}

class _CapsuleListTileState extends State<CapsuleListTile> {
  late DateTime? openAt;
  final String openedLabel = "Capsule is opened!";

  late LatLng? location;
  Timer? _timer;
  String? address;

  @override
  void initState() {
    super.initState();
    openAt = widget.capsule['openAt']?.toDate();
    location = widget.capsule['location'] != null
        ? LatLng(
            widget.capsule['location'].latitude,
            widget.capsule['location'].longitude,
          )
        : null;

    if (openAt != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }

    if (location != null) {
      _getAddress(location).then((addr) {
        if (mounted)
          setState(() {
            address = addr;
          });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    final String title = widget.capsule['title'] ?? 'Untitled';
    final String color = widget.capsule['color'] ?? 'blue';
    final String? imageUrl = widget.capsule['imageUrl'];
    final String privacy = widget.capsule['privacy'] ?? 'private';
    final DateTime? createdAt = widget.capsule['createdAt']?.toDate();

    return InkWell(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecorations.whiteCard().copyWith(
          color: widget.isSelected ? const Color.fromARGB(255, 103, 207, 255).withAlpha(100) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      width: screenWidth * 0.2,
                      height: screenHeight * 0.15,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 0.2,
                      height: 0.15,
                      child: const Icon(Icons.lock_clock, color: Colors.white),
                    ),
            ),

            SizedBox(width: screenWidth * 0.04),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DefaultText(
                          title,
                          fontWeight: FontWeight.w500,
                          fontSize: screenWidth * 0.04,
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Image.asset(
                        'assets/images/icons/capsule_creation/pin_${color.toLowerCase()}_icon.png',
                        width: screenHeight * 0.025,
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      GestureDetector(
                        onTap: widget.onFavoriteTap,
                        child: Icon(
                          widget.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: screenHeight * 0.03,
                          color: widget.isFavorite ? Colors.red : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.004),
                  ProfilePageDivider(width: double.infinity),
                  SizedBox(height: screenHeight * 0.016),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/icons/capsule_creation/timer_icon.png',
                                  width: screenWidth * 0.05,
                                ),
                                SizedBox(width: screenWidth * 0.01),
                                if (openAt != null)
                                  DefaultText(formatCountdown(openAt!))
                                else
                                  DefaultText(openedLabel),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.008),
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/icons/capsule_creation/privacy_icon.png',
                                  width: screenWidth * 0.05,
                                ),
                                SizedBox(width: screenWidth * 0.01),
                                DefaultText(toCapitalCase(privacy)),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.008),
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/icons/capsule_creation/location_icon.png',
                                  width: screenWidth * 0.05,
                                ),
                                SizedBox(width: screenWidth * 0.01),
                                DefaultText('${distanceInKm(location!)} km'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: screenWidth * 0.23,
                            height: screenHeight * 0.035,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 217, 0),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.02,
                                  vertical: screenHeight * 0.003,
                                ),
                                child: Text(
                                  address ?? 'No location',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontFamily: 'Irina',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.005),
                          if (createdAt != null)
                            Container(
                              width: screenWidth * 0.23,
                              height: screenHeight * 0.035,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 85, 201, 46),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.02,
                                    vertical: screenHeight * 0.003,
                                  ),
                                  child: Text(
                                    "${createdAt.day}.${createdAt.month}.${createdAt.year}",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      fontFamily: 'Irina',
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatCountdown(DateTime openAt) {
    final now = DateTime.now();

    Duration diff = openAt.difference(now);

    if (diff.inSeconds <= 0) return openedLabel;

    final years = diff.inDays ~/ 365;
    final days = diff.inDays % 365;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    if (years > 0) {
      return "${years}y ${days}d ${hours}h ${minutes}m";
    } else {
      return "${days}d ${hours}h ${minutes}m ${seconds}s";
    }
  }

  String toCapitalCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Future<String> _getAddress(LatLng? loc) async {
    if (loc == null) return "";
    try {
      final placemarks = await placemarkFromCoordinates(
        loc.latitude,
        loc.longitude,
      );
      if (placemarks.isEmpty) return "";
      final p = placemarks.first;
      return p.locality ??
          p.subAdministrativeArea ??
          p.administrativeArea ??
          'Unknown';
    } catch (e) {
      return "";
    }
  }

  double distanceInKm(LatLng capsuleLocation) {
    if (MapPage.currentPositionStatic == null) return 0.0;

    final double distanceMeters = Geolocator.distanceBetween(
      MapPage.currentPositionStatic!.latitude,
      MapPage.currentPositionStatic!.longitude,
      capsuleLocation.latitude,
      capsuleLocation.longitude,
    );

    double distanceKm = distanceMeters / 1000;
    return double.parse(distanceKm.toStringAsFixed(1));
  }
}
