import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'user_services.dart';

class FriendsSearchWidget extends StatelessWidget {
  final Function(String userId) onAddFriend;
  final Function(String userId) onRemoveFriend;

  const FriendsSearchWidget({
    Key? key,
    required this.onAddFriend,
    required this.onRemoveFriend,
  }) : super(key: key);

  Future<String?> _getImageUrl(String avatarUrl) async {
    if (avatarUrl.startsWith('gs://')) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(avatarUrl);
        return await ref.getDownloadURL();
      } catch (e) {
        return null;
      }
    }
    return avatarUrl.isNotEmpty ? avatarUrl : null;
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
            final avatarUrl = userData['profile_image'] as String? ?? '';

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                leading: FutureBuilder<String?>(
                  future: _getImageUrl(avatarUrl),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
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
            );
          },
        );
      },
    );
  }
}