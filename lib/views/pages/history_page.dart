import 'package:later/views/widgets/history_page_widgets/capsule_card.dart';
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
                return CapsuleCard(
                  capsuleId: capsule.id,
                  data: data,
                  isSelected: _selectedCapsules.contains(capsule.id),
                  isSelectMode: _isSelectMode,
                  onSelectToggle: () => _toggleCapsuleSelection(capsule.id),
                );
              },
            );
          },
        );
      },
    );
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
