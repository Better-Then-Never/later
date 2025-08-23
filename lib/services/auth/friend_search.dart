import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:later/services/auth/user_services.dart';
import 'package:later/views/widgets/add_friend_profile_page.dart';

class FriendsSearchWidget extends StatelessWidget {
  final Function(String userId) onAddFriend;
  final Function(String userId) onRemoveFriend;
  final Set<String> hiddenUserIds;
  final String searchQuery;

  static final Map<String, String?> _imageUrlCache = {};

  const FriendsSearchWidget({
    super.key,
    required this.onAddFriend,
    required this.onRemoveFriend,
    required this.hiddenUserIds,
    required this.searchQuery,
  });

  Future<String?> _getImageUrl(String userId) async {
    if (_imageUrlCache.containsKey(userId)) {
      return _imageUrlCache[userId];
    }
    final optimizedPath = 'userdata/$userId/assets/images/profile_image_small';
    final originalPath = 'userdata/$userId/assets/images/profile_image';
    try {
      final ref = FirebaseStorage.instance.ref().child(optimizedPath);
      final url = await ref.getDownloadURL();
      _imageUrlCache[userId] = url;
      return url;
    } catch (e) {
      try {
        final ref = FirebaseStorage.instance.ref().child(originalPath);
        final url = await ref.getDownloadURL();
        _imageUrlCache[userId] = url;
        return url;
      } catch (e) {
        _imageUrlCache[userId] = null;
        return null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final currentUid = userService.uid;
    final screenWidth = MediaQuery.of(context).size.width;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data!.docs
            .where((user) => user.id != currentUid)
            .where((user) => !(userService.friends.contains(user.id)))
            .where((user) => !hiddenUserIds.contains(user.id))
            .where((user) {
              if (searchQuery.isEmpty) return true;
              final data = user.data() as Map<String, dynamic>;
              final username = (data['username'] ?? '')
                  .toString()
                  .toLowerCase();
              return username.contains(searchQuery.toLowerCase());
            })
            .toList();

        if (users.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: 180),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'No more suggested friends',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Irina',
                  color: Colors.black,
                ),
              ),
            ),
          );
        }

        return Container(
          width: screenWidth * 0.92,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                spreadRadius: 1,
                blurRadius: 9,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < users.length; i++) ...[
                FriendSuggestionRow(
                  name: (users[i].data() as Map<String, dynamic>)['name'] ?? '',
                  username:
                      (users[i].data() as Map<String, dynamic>)['username'] ??
                      '',
                  avatarFuture: _getImageUrl(users[i].id),
                  onTapProfile: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddFriendProfilePage(userId: users[i].id),
                      ),
                    );
                  },
                  onAdd: () => onAddFriend(users[i].id),
                  onRemove: () => onRemoveFriend(users[i].id),
                  screenWidth: screenWidth,
                ),
                if (i < users.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 0,
                    endIndent: 0,
                    color: Color.fromARGB(255, 211, 211, 211),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class FriendSuggestionRow extends StatelessWidget {
  final String name;
  final String username;
  final Future<String?> avatarFuture;
  final VoidCallback onTapProfile;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final double screenWidth;

  const FriendSuggestionRow({
    super.key,
    required this.name,
    required this.username,
    required this.avatarFuture,
    required this.onTapProfile,
    required this.onAdd,
    required this.onRemove,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: onTapProfile,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 4),
          leading: FutureBuilder<String?>(
            future: avatarFuture,
            builder: (context, snapshot) {
              ImageProvider avatar;
              if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.isNotEmpty) {
                avatar = NetworkImage(snapshot.data!);
              } else {
                avatar = AssetImage(
                  'assets/images/icons/navbar/icon-profile.png',
                );
              }
              return CircleAvatar(
                radius: screenWidth * 0.07,
                backgroundImage: avatar,
                backgroundColor: Colors.grey[200],
              );
            },
          ),
          title: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.045,
              fontFamily: 'Irina',
              color: Colors.black,
            ),
          ),
          subtitle: Text(
            '@$username',
            style: TextStyle(
              fontSize: screenWidth * 0.040,
              fontFamily: 'Irina',
              color: Color.fromARGB(255, 94, 94, 94),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onAdd,
                child: Image.asset(
                  'assets/images/icons/prof_page/add_friend.png',
                  width: screenWidth * 0.09,
                  height: screenWidth * 0.09,
                ),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: Image.asset(
                  'assets/images/icons/friends_page/delete_reset.png',
                  width: screenWidth * 0.07,
                  height: screenWidth * 0.07,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
