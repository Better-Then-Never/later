import 'package:flutter/material.dart';

class HistoryHeader extends StatelessWidget {
  final TextEditingController searchController;
  final bool isSelectMode;
  final VoidCallback onSortTap;
  final VoidCallback onSelectToggle;
  final Function(String) onSearchChanged;

  const HistoryHeader({
    super.key,
    required this.searchController,
    required this.isSelectMode,
    required this.onSortTap,
    required this.onSelectToggle,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
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
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: Row(
                      children: [
                        // Sort icon placeholder to balance the layout
                        SizedBox(width: screenWidth * 0.10),
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
                        const SizedBox(width: 8), 
                        Transform.translate(
                          offset: const Offset(0, 5), 
                          child: GestureDetector(
                            onTap: onSelectToggle,
                            child: Container(
                              width: 70, 
                              height: 32, 
                              decoration: BoxDecoration(
                                color: isSelectMode 
                                    ? const Color(0xFFD0D0D0) 
                                    : const Color(0xFFEAEAEA), 
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Center(
                                child: Text(
                                  isSelectMode ? 'Cancel' : 'Select',
                                  style: const TextStyle(
                                    fontFamily: 'Irina',
                                    fontSize: 19,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
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
          Positioned(
            bottom: 65,
            left: 20,
            child: GestureDetector(
              onTap: onSortTap,
              child: Image.asset(
                'assets/images/icons/history_page/sort.png',
                width: screenWidth * 0.09,
                height: screenWidth * 0.09,
              ),
            ),
          ),
        ],
      ),
    );
  }
}