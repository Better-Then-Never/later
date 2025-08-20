import 'package:flutter/material.dart';
import 'package:later/services/auth/friends_search.dart';

class AddFriendsPage extends StatelessWidget {
  const AddFriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
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
                        Text(
                          'Add friends',
                          style: TextStyle(
                            fontSize: screenWidth * 0.10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Irina',
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 1),
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
                              color: Color(0xFFEAEAEA),
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
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: "Search...",
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Irina',
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                  ),
                                  child: Image.asset(
                                    'assets/images/icons/friends_page/open_camera.png',
                                    width: screenWidth * 0.08,
                                    height: screenWidth * 0.08,
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
                  left: 8,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Image.asset(
                      'assets/images/icons/prof_page/go_back.png',
                      width: screenWidth * 0.11,
                      height: screenWidth * 0.11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FriendsSearchWidget(
              onAddFriend: (userId) {
                // TODO: Implement add friend logic
              },
              onRemoveFriend: (userId) {
                // TODO: Implement remove friend logic
              },
            ),
          ),
        ],
      ),
    );
  }
}
