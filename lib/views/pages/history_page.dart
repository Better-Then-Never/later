import 'package:later/views/widgets/history_page_widgets/capsule_card.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:later/services/auth/auth_services.dart';
import 'package:later/views/widgets/history_page_widgets/history_header.dart';
import 'package:geolocator/geolocator.dart';
import 'package:later/views/widgets/history_page_widgets/confirm_delete_modal.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'date_newest';
  bool _isSelectMode = false;
  Set<String> _selectedCapsules = {};
  Position? _userPosition;
  bool get _isAnyFilterActive =>
      (_filterColor != null && _filterColor!.isNotEmpty) ||
      (_filterVisibility != null && _filterVisibility!.isNotEmpty) ||
      (_filterOpensIn != null && _filterOpensIn!.isNotEmpty);

  // Filter fields
  String? _filterColor;
  String? _filterVisibility;
  String? _filterOpensIn;

  @override
  void initState() {
    super.initState();
    Geolocator.getCurrentPosition().then((pos) {
      setState(() {
        _userPosition = pos;
      });
    });
  }

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
            onFilterTap: _showFilterOptions,
            isFilterActive: _isAnyFilterActive,
            onDeletePressed: _deleteSelectedCapsules, // Pass delete callback
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

            return StatefulBuilder(
              builder: (context, setLocalState) {
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
                  itemCount: filteredCapsules.length,
                  itemBuilder: (context, index) {
                    final capsule = filteredCapsules[index];
                    final data = capsule.data() as Map<String, dynamic>;
                    return CapsuleCard(
                      capsuleId: capsule.id,
                      data: data,
                      isSelected: _selectedCapsules.contains(capsule.id),
                      isSelectMode: _isSelectMode,
                      onSelectToggle: () {
                        setLocalState(() {
                          if (_selectedCapsules.contains(capsule.id)) {
                            _selectedCapsules.remove(capsule.id);
                          } else {
                            _selectedCapsules.add(capsule.id);
                          }
                          if (_selectedCapsules.isEmpty) {
                            setState(() {
                              _isSelectMode = false;
                            });
                          }
                        });
                      },
                      userPosition: _userPosition,
                      onLongPress: () {
                        if (!_isSelectMode) {
                          setState(() {
                            _isSelectMode = true;
                          });
                          setLocalState(() {
                            _selectedCapsules.add(capsule.id);
                          });
                        }
                      },
                    );
                  },
                );
              },
            );
          },
        );
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

Future<void> _deleteSelectedCapsules() async {
  if (_selectedCapsules.isEmpty) return;
  final confirm = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withAlpha(128),
    builder: (context) => const ConfirmDeleteModal(),
  );
  if (confirm != true) return;

  for (final id in _selectedCapsules) {
    await FirebaseFirestore.instance.collection('capsules').doc(id).delete();
  }
  setState(() {
    _selectedCapsules.clear();
    _isSelectMode = false;
  });
}

  List<QueryDocumentSnapshot> _filterAndSortCapsules(
    List<QueryDocumentSnapshot> capsules,
  ) {
    var filtered = capsules.where((capsule) {
      final data = capsule.data() as Map<String, dynamic>;
      final title = (data['title'] ?? '').toLowerCase();
      final description = (data['description'] ?? '').toLowerCase();

      // Search
      if (_searchQuery.isNotEmpty &&
          !title.contains(_searchQuery) &&
          !description.contains(_searchQuery)) {
        return false;
      }

      // Color filter
      if (_filterColor != null && _filterColor!.isNotEmpty) {
        final color = (data['color'] ?? '').toString().toLowerCase();
        if (color != _filterColor) return false;
      }

      // Visibility filter (now includes 'friends')
      if (_filterVisibility != null && _filterVisibility!.isNotEmpty) {
        final privacy = (data['privacy'] ?? '').toString().toLowerCase();
        if (privacy != _filterVisibility) return false;
      }

      // Opens in status filter
      if (_filterOpensIn != null) {
        final openAt = data['openAt'];
        final now = DateTime.now();
        if (_filterOpensIn == 'opened') {
          if (openAt is Timestamp) {
            final openDate = openAt.toDate();
            if (openDate.isAfter(now)) return false;
          } else {
            // If not scheduled, not considered opened
            return false;
          }
        } else if (_filterOpensIn == 'future') {
          if (openAt is Timestamp) {
            final openDate = openAt.toDate();
            if (openDate.isBefore(now)) return false;
          } else {
            // If not scheduled, not considered future
            return false;
          }
        } else if (_filterOpensIn == 'not_scheduled') {
          if (openAt is Timestamp) {
            // If scheduled, not "not scheduled"
            return false;
          }
        }
      }

      return true;
    }).toList();

    // Sort based on selected criteria
    filtered.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      double getDistance(dynamic loc) {
        if (_userPosition == null) return double.infinity;
        if (loc is GeoPoint) {
          return Geolocator.distanceBetween(
            _userPosition!.latitude,
            _userPosition!.longitude,
            loc.latitude,
            loc.longitude,
          );
        }
        return double.infinity;
      }

      switch (_sortBy) {
        case 'date_newest':
          final timestampA = dataA['createdAt'] as Timestamp?;
          final timestampB = dataB['createdAt'] as Timestamp?;
          if (timestampA == null && timestampB == null) return 0;
          if (timestampA == null) return 1;
          if (timestampB == null) return -1;
          return timestampB.compareTo(timestampA);
        case 'date_oldest':
          final timestampA = dataA['createdAt'] as Timestamp?;
          final timestampB = dataB['createdAt'] as Timestamp?;
          if (timestampA == null && timestampB == null) return 0;
          if (timestampA == null) return 1;
          if (timestampB == null) return -1;
          return timestampA.compareTo(timestampB);
        case 'distance_farthest':
          if (_userPosition == null) return 0;
          final distA = getDistance(dataA['location']);
          final distB = getDistance(dataB['location']);
          return distB.compareTo(distA);
        case 'distance_closest':
          if (_userPosition == null) return 0;
          final distA = getDistance(dataA['location']);
          final distB = getDistance(dataB['location']);
          return distA.compareTo(distB);
        default:
          return 0;
      }
    });

    return filtered;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
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
            _buildSortOption('Date (newest to oldest)', 'date_newest'),
            _buildSortOption('Date (oldest to newest)', 'date_oldest'),
            _buildSortOption('Distance (closest)', 'distance_closest'),
            _buildSortOption('Distance (farthest)', 'distance_farthest'),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Filter by',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Color
                DropdownButtonFormField<String>(
                  value: _filterColor,
                  decoration: InputDecoration(
                    labelText: 'Color',
                    labelStyle: const TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 86, 201, 46),
                        width: 2,
                      ),
                    ),
                  ),
                  dropdownColor: Colors.white,
                  iconEnabledColor: Color.fromARGB(190, 0, 0, 0),
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Any')),
                    DropdownMenuItem(value: 'green', child: Text('Green')),
                    DropdownMenuItem(value: 'yellow', child: Text('Yellow')),
                    DropdownMenuItem(value: 'red', child: Text('Red')),
                    DropdownMenuItem(value: 'blue', child: Text('Blue')),
                    DropdownMenuItem(value: 'orange', child: Text('Orange')),
                    DropdownMenuItem(value: 'pink', child: Text('Pink')),
                    DropdownMenuItem(value: 'purple', child: Text('Purple')),
                  ],
                  onChanged: (val) {
                    setModalState(() => _filterColor = val);
                  },
                ),
                const SizedBox(height: 12),
                // Visibility
                DropdownButtonFormField<String>(
                  value: _filterVisibility,
                  decoration: InputDecoration(
                    labelText: 'Visibility',
                    labelStyle: const TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 86, 201, 46),
                        width: 2,
                      ),
                    ),
                  ),
                  dropdownColor: Colors.white,
                  iconEnabledColor: Color.fromARGB(190, 0, 0, 0),
                  borderRadius: const BorderRadius.all(Radius.circular(25)),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Any')),
                    DropdownMenuItem(value: 'private', child: Text('Private')),
                    DropdownMenuItem(value: 'public', child: Text('Public')),
                    DropdownMenuItem(value: 'friends', child: Text('Friends')),
                  ],
                  onChanged: (val) {
                    setModalState(() => _filterVisibility = val);
                  },
                ),
                const SizedBox(height: 12),
                // Opens in status
                DropdownButtonFormField<String>(
                  value: _filterOpensIn,
                  decoration: InputDecoration(
                    labelText: 'Opens status',
                    labelStyle: const TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 86, 201, 46),
                        width: 2,
                      ),
                    ),
                  ),
                  dropdownColor: Colors.white,
                  iconEnabledColor: Color.fromARGB(190, 0, 0, 0),
                  borderRadius: const BorderRadius.all(Radius.circular(25)),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Any')),
                    DropdownMenuItem(
                      value: 'opened',
                      child: Text('Already opened'),
                    ),
                    DropdownMenuItem(
                      value: 'future',
                      child: Text('Opens in future'),
                    ),
                    DropdownMenuItem(
                      value: 'not_scheduled',
                      child: Text('Not scheduled'),
                    ),
                  ],
                  onChanged: (val) {
                    setModalState(() => _filterOpensIn = val);
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            86,
                            201,
                            46,
                          ), // Green
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Apply',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            255,
                            87,
                            87,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          setModalState(() {
                            _filterColor = null;
                            _filterVisibility = null;
                            _filterOpensIn = null;
                          });
                          setState(() {});
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, String value) {
    return ListTile(
      title: Text(title),
      trailing: _sortBy == value
          ? Image.asset(
              'assets/images/icons/friends_page/done.png',
              width: 24,
              height: 24,
            )
          : null,
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}