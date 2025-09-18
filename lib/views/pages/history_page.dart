import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:later/services/auth/auth_services.dart';
import 'package:later/views/widgets/history_page_widgets/history_header.dart';
import 'package:geocoding/geocoding.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'date';
  bool _isSelectMode = false;
  Set<String> _selectedCapsules = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          HistoryHeader(
            searchController: _searchController,
            isSelectMode: _isSelectMode,
            onSortTap: _showSortOptions,
            onSelectToggle: _toggleSelectMode,
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          Expanded(child: _buildCapsulesList()),
        ],
      ),
    );
  }

  // Remove the _buildHeader() method since it's now a separate widget

  Widget _buildCapsulesList() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final currentUser = authService.currentUser;

        if (currentUser == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Please log in to view your capsules'),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('capsules')
              .where('ownerId', isEqualTo: currentUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final capsules = snapshot.data?.docs ?? [];
            print(
              'Found ${capsules.length} capsules for user ${currentUser.uid}',
            );

            final filteredCapsules = _filterAndSortCapsules(capsules);

            if (filteredCapsules.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No capsules found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create your first time capsule!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                150,
              ), // Added extra bottom padding
              itemCount: filteredCapsules.length,
              itemBuilder: (context, index) {
                final capsule = filteredCapsules[index];
                final data = capsule.data() as Map<String, dynamic>;
                return _buildCapsuleCard(capsule.id, data);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCapsuleCard(String capsuleId, Map<String, dynamic> data) {
    final isSelected = _selectedCapsules.contains(capsuleId);
    final title = data['title'] ?? 'Untitled';
    final openAt = data['openAt'];
    final location = data['location'] as GeoPoint?;
    final privacy = data['privacy'] ?? 'private';
    final imageUrl = data['imageUrl'] ?? '';
    final opensIn = _calculateOpensIn(openAt);
    final createdAt = data['createdAt'] as Timestamp?;
    final distanceKm = data['distanceKm'] ?? 500;
    final pinColorString = (data['color'] ?? 'green').toString().toLowerCase();

    // Map color string to Color
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

    // Get location label from coordinates
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
          constraints: const BoxConstraints(
            maxWidth: 200, // Set your desired max width
            minWidth: 60, // Optional: set a min width for consistency
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 217, 0),
            borderRadius: BorderRadius.circular(25),
          ),
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
      alignment: Alignment.center,
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
        if (opensIn == 'Opened' || opensIn == 'Not scheduled')
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(128),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/icons/history_page/opened.png',
              width: 40,
              height: 40,
            ),
          )
        else
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(128),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/icons/history_page/locked.png',
              width: 40,
              height: 40,
            ),
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
                  padding: const EdgeInsets.only(left: 20, right: 2, top: 2),
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
                  padding: const EdgeInsets.only(left: 20, bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      datePill,
                      const SizedBox(width: 6),
                      locationPill,
                      const SizedBox(width: 8),
                      // Use custom pin image instead of Icon
                      Image.asset(
                        _getPinAsset(pinColorString),
                        width: 22,
                        height: 22,
                      ),
                    ],
                  ),
                ),
                // Black line under the header row
                Container(
                  height: 1,
                  color: Colors.black,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                ),
                const SizedBox(height: 8),
                // Image and details row
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
                          // Opens in
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
                          // Destination
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/icons/capsule_creation/location_icon.png',
                                width: 24,
                                height: 24,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 7),
                              const Text(
                                'Destination:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${distanceKm}km',
                                style: const TextStyle(fontSize: 22),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Visibility
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
          if (_isSelectMode)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _toggleCapsuleSelection(capsuleId),
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

  List<QueryDocumentSnapshot> _filterAndSortCapsules(
    List<QueryDocumentSnapshot> capsules,
  ) {
    // Filter by search query
    var filtered = capsules.where((capsule) {
      final data = capsule.data() as Map<String, dynamic>;
      final title = (data['title'] ?? '').toLowerCase();
      final description = (data['description'] ?? '').toLowerCase();
      return title.contains(_searchQuery) || description.contains(_searchQuery);
    }).toList();

    // Sort based on selected criteria
    filtered.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      switch (_sortBy) {
        case 'date':
          final timestampA = dataA['createdAt'] as Timestamp?;
          final timestampB = dataB['createdAt'] as Timestamp?;
          if (timestampA == null && timestampB == null) return 0;
          if (timestampA == null) return 1;
          if (timestampB == null) return -1;
          return timestampB.compareTo(timestampA);
        case 'visibility':
          return (dataA['privacy'] ?? '').compareTo(dataB['privacy'] ?? '');
        case 'destination':
          // Since location is GeoPoint, we can't easily sort by it
          return 0;
        case 'opensIn':
          // Since openAt can be null, we'll sort by scheduled status
          final scheduledA = dataA['isScheduled'] ?? false;
          final scheduledB = dataB['isScheduled'] ?? false;
          return scheduledB.toString().compareTo(scheduledA.toString());
        default:
          return 0;
      }
    });

    return filtered;
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

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort by',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSortOption('Date', 'date'),
            _buildSortOption('Privacy', 'visibility'),
            _buildSortOption('Scheduled Status', 'opensIn'),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, String value) {
    return ListTile(
      title: Text(title),
      trailing: _sortBy == value
          ? const Icon(Icons.check, color: Colors.blue)
          : null,
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        Navigator.pop(context);
      },
    );
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (!_isSelectMode) {
        _selectedCapsules.clear();
      }
    });
  }

  void _toggleCapsuleSelection(String capsuleId) {
    setState(() {
      if (_selectedCapsules.contains(capsuleId)) {
        _selectedCapsules.remove(capsuleId);
      } else {
        _selectedCapsules.add(capsuleId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
