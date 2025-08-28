import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:later/services/auth/user_services.dart';
import 'package:later/services/auth/friend_request.dart';
import 'package:later/views/widgets/friends_logic_pages/add_friend_profile_page.dart';

class FriendsSearchWidget extends StatelessWidget {
  final Function(String userId) onSendRequest;
  final Function(String userId) onRemoveFriend;
  final Set<String> hiddenUserIds;
  final Set<String> sentRequestIds;
  final String searchQuery;
  final VoidCallback? onStateChanged;

  static final Map<String, String?> _imageUrlCache = {};
  final FriendRequestService _requestService = FriendRequestService();

  FriendsSearchWidget({
    super.key,
    required this.onSendRequest,
    required this.onRemoveFriend,
    required this.hiddenUserIds,
    required this.sentRequestIds,
    required this.searchQuery,
    this.onStateChanged,
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
            .where((user) => !userService.friends.contains(user.id))
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
                spreadRadius: 0,
                blurRadius: 9,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < users.length; i++) ...[
                FriendSuggestionRow(
                  userId: users[i].id,
                  name: (users[i].data() as Map<String, dynamic>)['name'] ?? '',
                  username:
                      (users[i].data() as Map<String, dynamic>)['username'] ??
                      '',
                  avatarFuture: _getImageUrl(users[i].id),
                  onTapProfile: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddFriendProfilePage(
                          userId: users[i].id,
                          onStateChanged: onStateChanged, // Pass the callback
                        ),
                      ),
                    );
                  },
                  onSendRequest: () => onSendRequest(users[i].id),
                  onRemove: () => onRemoveFriend(users[i].id),
                  isSent: sentRequestIds.contains(users[i].id),
                  screenWidth: screenWidth,
                  requestService: _requestService,
                  currentUid: currentUid!,
                  onStateChanged: onStateChanged, // Pass callback to row
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

class FriendSuggestionRow extends StatefulWidget {
  final String userId;
  final String name;
  final String username;
  final Future<String?> avatarFuture;
  final VoidCallback onTapProfile;
  final VoidCallback onSendRequest;
  final VoidCallback onRemove;
  final bool isSent;
  final double screenWidth;
  final FriendRequestService requestService;
  final String currentUid;
  final VoidCallback? onStateChanged;

  const FriendSuggestionRow({
    super.key,
    required this.userId,
    required this.name,
    required this.username,
    required this.avatarFuture,
    required this.onTapProfile,
    required this.onSendRequest,
    required this.onRemove,
    required this.isSent,
    required this.screenWidth,
    required this.requestService,
    required this.currentUid,
    this.onStateChanged,
  });

  @override
  State<FriendSuggestionRow> createState() => _FriendSuggestionRowState();
}

class _FriendSuggestionRowState extends State<FriendSuggestionRow> {
  String? requestStatus;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRequestStatus();
  }

  @override
  void didUpdateWidget(FriendSuggestionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh status when widget updates (like when parent refreshes)
    if (oldWidget.userId != widget.userId ||
        oldWidget.currentUid != widget.currentUid) {
      _checkRequestStatus();
    }
  }

  Future<void> _checkRequestStatus() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      final status = await widget.requestService.getRequestStatus(
        widget.currentUid,
        widget.userId,
      );

      if (!mounted) return;
      
      setState(() {
        requestStatus = status;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildActionButton() {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (widget.isSent || requestStatus == 'pending') {
      return Image.asset(
        'assets/images/icons/friends_page/pending.png',
        width: widget.screenWidth * 0.09,
        height: widget.screenWidth * 0.09,
      );
    }

    return GestureDetector(
      onTap: widget.onSendRequest,
      child: Image.asset(
        'assets/images/icons/prof_page/add_friend.png',
        width: widget.screenWidth * 0.09,
        height: widget.screenWidth * 0.09,
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          // Add mounted check here too
          if (!mounted) return;
          
          // Refresh status when returning from a page
          await _checkRequestStatus();
          
          if (!mounted) return;
          widget.onStateChanged?.call();
        }
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: widget.onTapProfile,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.screenWidth * 0.02),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 0),
            leading: FutureBuilder<String?>(
              future: widget.avatarFuture,
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
                  radius: widget.screenWidth * 0.07,
                  backgroundImage: avatar,
                  backgroundColor: Colors.grey[200],
                );
              },
            ),
            title: Text(
              widget.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: widget.screenWidth * 0.045,
                fontFamily: 'Irina',
                color: Colors.black,
              ),
            ),
            subtitle: Text(
              '@${widget.username}',
              style: TextStyle(
                fontSize: widget.screenWidth * 0.040,
                fontFamily: 'Irina',
                color: Color.fromARGB(255, 94, 94, 94),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onRemove,
                  child: Image.asset(
                    'assets/images/icons/friends_page/delete_reset.png',
                    width: widget.screenWidth * 0.07,
                    height: widget.screenWidth * 0.07,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
