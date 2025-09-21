import 'package:flutter/material.dart';

class HistoryHeader extends StatelessWidget {
  final TextEditingController searchController;
  final bool isSelectMode;
  final VoidCallback onSortTap;
  final VoidCallback onSelectToggle;
  final Function(String) onSearchChanged;
  final VoidCallback onFilterTap;
  final bool isFilterActive;

  const HistoryHeader({
    super.key,
    required this.searchController,
    required this.isSelectMode,
    required this.onSortTap,
    required this.onSelectToggle,
    required this.onSearchChanged,
    required this.onFilterTap,
    required this.isFilterActive,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // White container with header and search bar
        Container(
          width: screenWidth,
          height: screenHeight * 0.18,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'My capsules',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.09,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Irina',
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 1),
                      // Search bar
                      Padding(
                        padding: EdgeInsets.only(
                          left: screenWidth * 0.05,
                          right: screenWidth * 0.05,
                          top: 0,
                          bottom: screenHeight * 0.01,
                        ),
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAEAEA),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                ),
                                child: Image.asset(
                                  'assets/images/icons/friends_page/look_for.png',
                                  width: screenWidth * 0.07,
                                  height: screenWidth * 0.07,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.search,
                                      size: screenWidth * 0.07,
                                      color: Colors.grey[600],
                                    );
                                  },
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  decoration: const InputDecoration(
                                    hintText: "Find capsules...",
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  style: const TextStyle(
                                    fontFamily: 'Irina',
                                    fontSize: 22,
                                  ),
                                  onChanged: onSearchChanged,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Button row under the white container
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.049),
          child: Row(
            children: [
              // Sort by
              GestureDetector(
                onTap: onSortTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAEAEA),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/icons/history_page/sort.png',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Sort by',
                        style: TextStyle(
                          fontFamily: 'Irina',
                          fontSize: 19,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Filter by
              GestureDetector(
                onTap: onFilterTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isFilterActive
                        ? const Color(0xFFD0D0D0) // Darker when active
                        : const Color(0xFFEAEAEA), // Default color
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/icons/history_page/filter.png',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Filter by',
                        style: TextStyle(
                          fontFamily: 'Irina',
                          fontSize: 19,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Select (now with logic and color change)
              GestureDetector(
                onTap: onSelectToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelectMode
                        ? const Color(0xFFD0D0D0)
                        : const Color(0xFFEAEAEA),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    isSelectMode ? 'Cancel' : 'Select',
                    style: const TextStyle(
                      fontFamily: 'Irina',
                      fontSize: 19,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.015),
      ],
    );
  }
}
