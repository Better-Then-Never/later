import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:later/services/auth/auth_services.dart';
import 'package:later/views/widgets/history_page_widgets/history_header.dart';

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
              padding: const EdgeInsets.all(16),
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

  // ...rest of your existing methods remain the same...
  Widget _buildCapsuleCard(String capsuleId, Map<String, dynamic> data) {
    final isSelected = _selectedCapsules.contains(capsuleId);
    final title = data['title'] ?? 'Untitled';
    final openAt = data['openAt']; // This can be null
    final location = data['location'] as GeoPoint?; // Location is a GeoPoint
    final privacy =
        data['privacy'] ?? 'private'; // Changed from 'visibility' to 'privacy'
    final imageUrl = data['imageUrl'] ?? '';
    final opensIn = _calculateOpensIn(openAt);
    final createdAt = data['createdAt'] as Timestamp?;

    // Extract location string from GeoPoint
    String locationString = 'No location';
    if (location != null) {
      locationString =
          '${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[300],
                  ),
                  child: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.image,
                                color: Colors.grey,
                              );
                            },
                          ),
                        )
                      : const Icon(Icons.image, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatTimestamp(createdAt),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Tatry',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 4),
                          Text('Opens in: $opensIn'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Location: $locationString',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.visibility, size: 16),
                          const SizedBox(width: 4),
                          Text('Privacy: $privacy'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Pin icon
          Positioned(
            top: 8,
            right: 8,
            child: Icon(
              Icons.push_pin,
              color: privacy == 'private' ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          // Selection overlay
          if (_isSelectMode)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _toggleCapsuleSelection(capsuleId),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
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
