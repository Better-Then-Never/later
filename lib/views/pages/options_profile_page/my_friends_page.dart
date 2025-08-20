import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:later/services/auth/user_services.dart';

class MyFriendsPage extends StatelessWidget {
  const MyFriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final currentUid = userService.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text('My Friends'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: currentUid == null
          ? Center(child: Text('Not logged in'))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return Center(child: Text('No friends added yet'));
                }
                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final friendsList = List<String>.from(data['friends'] ?? []);
                if (friendsList.isEmpty) {
                  return Center(child: Text('No friends added yet'));
                }
                return FutureBuilder<List<DocumentSnapshot>>(
                  future: Future.wait(
                    friendsList.map((friendId) =>
                      FirebaseFirestore.instance.collection('users').doc(friendId).get()
                    ),
                  ),
                  builder: (context, friendsSnapshot) {
                    if (friendsSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!friendsSnapshot.hasData || friendsSnapshot.data!.isEmpty) {
                      return Center(child: Text('No friends added yet'));
                    }
                    final friendsDocs = friendsSnapshot.data!;
                    return ListView.builder(
                      itemCount: friendsDocs.length,
                      itemBuilder: (context, index) {
                        final friendData = friendsDocs[index].data() as Map<String, dynamic>? ?? {};
                        final friendName = friendData['name'] ?? '';
                        final friendUsername = friendData['username'] ?? '';
                        return ListTile(
                          leading: CircleAvatar(child: Icon(Icons.person)),
                          title: Text(friendName),
                          subtitle: Text('@$friendUsername'),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
