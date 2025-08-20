import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FriendProfilePage extends StatelessWidget {
  final String userId;

  const FriendProfilePage({Key? key, required this.userId}) : super(key: key);

  Future<String?> _getProfileImageUrl() async {
    final optimizedPath = 'userdata/$userId/assets/images/profile_image_small';
    final originalPath = 'userdata/$userId/assets/images/profile_image';
    try {
      final ref = FirebaseStorage.instance.ref().child(optimizedPath);
      return await ref.getDownloadURL();
    } catch (e) {
      try {
        final ref = FirebaseStorage.instance.ref().child(originalPath);
        return await ref.getDownloadURL();
      } catch (e) {
        return null;
      }
    }
  }

  Future<String?> _getBackgroundImageUrl() async {
    final bgPath = 'userdata/$userId/assets/images/background_image';
    try {
      final ref = FirebaseStorage.instance.ref().child(bgPath);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Stack(
        children: [
          FutureBuilder<String?>(
            future: _getBackgroundImageUrl(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  width: screenWidth,
                  height: screenHeight * 0.35,
                  color: Colors.grey[300],
                );
              } else if (snapshot.hasData && snapshot.data != null) {
                return Image.network(
                  snapshot.data!,
                  width: screenWidth,
                  height: screenHeight * 0.35,
                  fit: BoxFit.cover,
                );
              } else {
                return Container(
                  width: screenWidth,
                  height: screenHeight * 0.35,
                  color: Colors.grey[300],
                );
              }
            },
          ),
          Positioned(
            top: screenHeight * 0.18,
            left: (screenWidth - 120) / 2,
            child: FutureBuilder<String?>(
              future: _getProfileImageUrl(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.person, size: 60, color: Colors.grey[500]),
                  );
                } else if (snapshot.hasData && snapshot.data != null) {
                  return CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(snapshot.data!),
                  );
                } else {
                  return CircleAvatar(
                    radius: 60,
                    backgroundImage: AssetImage('assets/images/icons/navbar/icon-profile.png'),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
