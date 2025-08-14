import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:later/views/widgets/background_picture.dart';
import 'package:later/views/widgets/name_getting.dart';
import 'package:later/views/widgets/prof_picture.dart';
import 'package:later/views/widgets/username_getting.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  //Profile and background pictures with name and username texts
  @override
  Widget build(BuildContext context) {
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
                  pictureWidth: MediaQuery.of(context).size.width,
                ),
                Container(
                  width: double.infinity,
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
                          NameGettingWidget(
                            uid:
                                FirebaseAuth.instance.currentUser?.uid ??
                                'null',
                          ),
                          UsernameGettingWidget(
                            uid:
                                FirebaseAuth.instance.currentUser?.uid ??
                                'null',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            //My capsules part
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
              width: 380,
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
                          width: 304,
                          height: 39,
                          child: TextButton(
                            onPressed: () {
                              print(
                                "Add to map friends tapped",
                              ); //add logic to navigate to add to map friends page
                            },
                            style: TextButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              foregroundColor: Colors.black,
                              textStyle: const TextStyle(fontSize: 16),
                              splashFactory: NoSplash.splashFactory,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                      width: 304,
                      height: 1,
                      color: Color.fromARGB(211, 211, 211, 211),
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(width: 65),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: SizedBox(
                          width: 304,
                          height: 41,
                          child: TextButton(
                            onPressed: () {
                              print(
                                "Add to map everyone tapped",
                              ); //add logic to navigate to add to map everyone page
                            },
                            style: TextButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              foregroundColor: Colors.black,
                              textStyle: const TextStyle(fontSize: 16),
                              splashFactory: NoSplash.splashFactory,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

            //Friends part //Add friends
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
                print(
                  "Add friends tapped", //add logic to navigate to add friends page
                );
              },
              child: Container(
                width: 380,
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

            //My Friends list
            const SizedBox(height: 8),
            Container(
              width: 380,
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
              child: Stack(
                children: [
                  Positioned(
                    bottom: 45,
                    left: 0,
                    child: Container(
                      width: 380,
                      height: 1,
                      color: const Color.fromARGB(211, 211, 211, 211),
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
                          width: 305,
                          height: 40,
                          child: TextButton(
                            onPressed: () {
                              print(
                                "My friends tapped", //add logic to navigate to add to map my friends page
                              ); 
                            },
                            style: TextButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              foregroundColor: Colors.black,
                              textStyle: const TextStyle(fontSize: 16),
                              splashFactory: NoSplash.splashFactory,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                ],
              ),
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
              width: 380,
              height: 100,
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
    );
  }
}
