import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CapsuleCreationLocationLabel extends StatelessWidget {
  final double height;
  final String iconPath;
  final LatLng? location; // pass location here

  const CapsuleCreationLocationLabel({
    super.key,
    required this.height,
    required this.iconPath,
    this.location,
  });

  Future<Object> _getAddress(LatLng? loc) async {
    if (loc == null) return "No location";
    try {
      final placemarks = await placemarkFromCoordinates(
        loc.latitude,
        loc.longitude,
      );
      if (placemarks.isEmpty) return "Unknown location";
      final p = placemarks.first;
      return p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? 'Unknown';
    } catch (e) {
      return "Error getting location";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: height,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 255, 217, 0),
              borderRadius: BorderRadius.all(Radius.circular(25)),
            ),
            child: Center(
              child: FutureBuilder<Object>(
                future: _getAddress(location),
                builder: (context, snapshot) {
                  final text = snapshot.data?.toString() ?? "Loading...";
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 50,
                          fontFamily: 'Irina',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: height,
          width: height,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Image.asset(iconPath),
        ),
      ],
    );
  }
}
