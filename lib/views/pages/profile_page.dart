import 'package:flutter/material.dart';
import 'package:later/services/auth/user_services.dart';
import 'package:later/views/widgets/background_picture.dart';
import 'package:later/services/auth/name_getting.dart';
import 'package:later/views/widgets/prof_picture.dart';
import 'package:later/services/auth/username_getting.dart';
import 'package:provider/provider.dart';
import 'package:later/views/widgets/friends_row_profile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final userService = Provider.of<UserService>(context, listen: false);
    final uid = userService.uid ?? 'null';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                BackgroundPicture(
                  allignment: Alignment.topLeft,
                  pictureHeight: 230,
                  pictureWidth: screenWidth,
                ),
                Container(
                  width: screenWidth,
                  height: 1,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(120),
                        spreadRadius: 60,
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 25,
                  right: 12,
                  child: Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(minWidth: 0),
                        icon: Image.asset(
                          'assets/images/icons/prof_page/notifications_button.png',
                          width: 41,
                          height: 41,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/notificationsPage');
                        },
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        icon: Image.asset(
                          'assets/images/icons/prof_page/share_button.png',
                          width: 40,
                          height: 40,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/sharePage');
                        },
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        icon: Image.asset(
                          'assets/images/icons/prof_page/settings_button.png',
                          width: 40,
                          height: 40,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/settingsPage');
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 99,
                  left: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ProfilePicture(pictureHeight: 115, pictureWidth: 115),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NameGettingWidget(uid: uid),
                          UsernameGettingWidget(uid: uid),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    "My capsules",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: screenWidth - 32,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          spreadRadius: 1,
                          blurRadius: 9,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Image.asset(
                                  'assets/images/icons/prof_page/my_capsules.png',
                                ),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            SizedBox(width: 65),
                            Align(
                              alignment: Alignment.topLeft,
                              child: SizedBox(
                                width: screenWidth - 108,
                                height: 39,
                                child: TextButton(
                                  onPressed: () {
                                    //TODO : Implement Add To Map friends button
                                  },
                                  style: TextButton.styleFrom(
                                    alignment: Alignment.centerLeft,
                                    foregroundColor: Colors.black,
                                    textStyle: const TextStyle(fontSize: 16),
                                    splashFactory: NoSplash.splashFactory,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    overlayColor: Colors.transparent,
                                  ),
                                  child: const Text(
                                    "Add to map | Only for friends",
                                    style: TextStyle(fontFamily: 'Irina'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: screenWidth - 108,
                            height: 1,
                            color: Color.fromARGB(255, 211, 211, 211),
                          ),
                        ),
                        Row(
                          children: [
                            SizedBox(width: 65),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: SizedBox(
                                width: screenWidth - 108,
                                height: 41,
                                child: TextButton(
                                  onPressed: () {
                                    //TODO: Add to map everyone tapped
                                  },
                                  style: TextButton.styleFrom(
                                    alignment: Alignment.centerLeft,
                                    foregroundColor: Colors.black,
                                    textStyle: const TextStyle(fontSize: 16),
                                    splashFactory: NoSplash.splashFactory,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    overlayColor: Colors.transparent,
                                  ),
                                  child: const Text(
                                    "Add to map | Everyone",
                                    style: TextStyle(fontFamily: 'Irina'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Friends",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/addFriendsPage');
                    },
                    child: Container(
                      width: screenWidth - 32,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(40),
                            spreadRadius: 1,
                            blurRadius: 9,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 18),
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Image.asset(
                              'assets/images/icons/prof_page/add_friend.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 18),
                          const Text(
                            "Add friends",
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        width: screenWidth - 32,
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(40),
                              spreadRadius: 1,
                              blurRadius: 9,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 21),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: RandomFriendsRow(currentUserUid: uid),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Container(
                          width: screenWidth - 32,
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(25),
                              bottomRight: Radius.circular(25),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 3,
                        left: 0,
                        right: 0,
                        child: Row(
                          children: [
                            const SizedBox(width: 18),
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: Image.asset(
                                'assets/images/icons/prof_page/my_friends.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 5),
                            SizedBox(
                              width: screenWidth - 95,
                              height: 40,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/myFriendsPage',
                                  );
                                },
                                style: TextButton.styleFrom(
                                  alignment: Alignment.centerLeft,
                                  foregroundColor: Colors.black,
                                  textStyle: const TextStyle(fontSize: 16),
                                  splashFactory: NoSplash.splashFactory,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  overlayColor: Colors.transparent,
                                ),
                                child: const Text(
                                  "My friends",
                                  style: TextStyle(fontFamily: 'Irina'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 45,
                        left: 0,
                        child: Container(
                          width: screenWidth - 32,
                          height: 1,
                          color: const Color.fromARGB(255, 211, 211, 211),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Map",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: screenWidth - 32,
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          spreadRadius: 1,
                          blurRadius: 9,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
