import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:later/services/auth/user_services.dart';
import 'package:later/views/friend_profile_page.dart';

class FriendsSearchWidget extends StatelessWidget {
  final Function(String userId) onAddFriend;
  final Function(String userId) onRemoveFriend;

  const FriendsSearchWidget({
    Key? key,
    required this.onAddFriend,
    required this.onRemoveFriend,
  }) : super(key: key);

  Future<String?> _getImageUrl(String userId) async {
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

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context, listen: false);
    final currentUid = userService.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data!.docs
            .where((user) => user.id != currentUid)
            .toList();
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final userData = user.data() as Map<String, dynamic>? ?? {};
            final userId = user.id;

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FriendProfilePage(userId: userId),
                    ),
                  );
                },
                child: ListTile(
                  leading: FutureBuilder<String?> (
                    future: _getImageUrl(userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              child: Icon(Icons.person, color: Colors.grey[500]),
                            ),
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        );
                      } else if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData &&
                          snapshot.data != null &&
                          snapshot.data!.isNotEmpty) {
                        return CircleAvatar(
                          backgroundImage: NetworkImage(snapshot.data!),
                        );
                      } else {
                        return CircleAvatar(
                          backgroundImage: AssetImage(
                            'assets/images/icons/navbar/icon-profile.png',
                          ),
                        );
                      }
                    },
                  ),
                  title: Text(userData['name'] ?? ''),
                  subtitle: Text('@${userData['username'] ?? ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.person_add, color: Colors.green),
                        onPressed: () => onAddFriend(user.id),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => onRemoveFriend(user.id),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}