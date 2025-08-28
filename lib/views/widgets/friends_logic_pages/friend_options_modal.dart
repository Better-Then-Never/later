import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class FriendOptionsModal extends StatelessWidget {
  final String friendUid;

  const FriendOptionsModal({super.key, required this.friendUid});

  static void show(BuildContext context, String friendUid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withAlpha(128),
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: FriendOptionsModal(friendUid: friendUid),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Manage friendship option
          SizedBox(
            height: 37,
            width: 264,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                ManageFriendshipModal.show(context, friendUid);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Irina',
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                splashFactory: NoSplash.splashFactory,
                overlayColor: Colors.transparent,
              ),
              child: const Center(child: Text('Manage friendship')),
            ),
          ),
          // Gray separator line
          Container(
            width: 264,
            height: 2,
            color: Color.fromARGB(255, 211, 211, 211),
          ),
          // Chat settings option
          SizedBox(
            height: 37,
            width: 264,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Handle chat settings action
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Irina',
                ),
                splashFactory: NoSplash.splashFactory,
                overlayColor: Colors.transparent,
              ),
              child: const Center(child: Text('Chat settings')),
            ),
          ),
          // Gray separator line
          Container(
            width: 264,
            height: 2,
            color: Color.fromARGB(255, 211, 211, 211),
          ),
          // Capsules settings option
          SizedBox(
            height: 37,
            width: 264,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Handle capsules settings action
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Irina',
                ),
                splashFactory: NoSplash.splashFactory,
                overlayColor: Colors.transparent,
              ),
              child: const Center(child: Text('Capsules settings')),
            ),
          ),
          // Gray separator line
          Container(
            width: 264,
            height: 2,
            color: Color.fromARGB(255, 211, 211, 211),
          ),
          // Share profile option
          SizedBox(
            height: 37,
            width: 264,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Handle share profile action
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Irina',
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                splashFactory: NoSplash.splashFactory,
                overlayColor: Colors.transparent,
              ),
              child: const Center(child: Text('Share profile')),
            ),
          ),
        ],
      ),
    );
  }
}

class ManageFriendshipModal extends StatelessWidget {
  final String friendUid;

  const ManageFriendshipModal({super.key, required this.friendUid});

  static void show(BuildContext context, String friendUid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withAlpha(128),
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: ManageFriendshipModal(friendUid: friendUid),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Manage friendship header
          SizedBox(
            height: 37,
            width: 264,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: const Center(
                child: Text(
                  'Manage friendship',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Irina',
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          // Gray separator line
          Container(width: 264, height: 1, color: Color.fromARGB(255, 0, 0, 0)),
          // Report option
          SizedBox(
            height: 37,
            width: 264,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Handle report action
              },
              style: TextButton.styleFrom(
                foregroundColor: Color.fromARGB(255, 253, 65, 64),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Irina',
                ),
                splashFactory: NoSplash.splashFactory,
                overlayColor: Colors.transparent,
              ),
              child: const Center(child: Text('Report')),
            ),
          ),
          // Gray separator line
          Container(
            width: 264,
            height: 2,
            color: Color.fromARGB(255, 211, 211, 211),
          ),
          // Block option
          SizedBox(
            height: 37,
            width: 264,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Handle block action
              },
              style: TextButton.styleFrom(
                foregroundColor: Color.fromARGB(255, 253, 65, 64),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Irina',
                ),
                splashFactory: NoSplash.splashFactory,
                overlayColor: Colors.transparent,
              ),
              child: const Center(child: Text('Block')),
            ),
          ),
          // Gray separator line
          Container(
            width: 264,
            height: 2,
            color: Color.fromARGB(255, 211, 211, 211),
          ),
          // Remove from friends option
          SizedBox(
            height: 37,
            width: 264,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                RemoveFriendConfirmModal.show(context, friendUid);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Irina',
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                splashFactory: NoSplash.splashFactory,
                overlayColor: Colors.transparent,
              ),
              child: const Center(child: Text('Remove from friends')),
            ),
          ),
        ],
      ),
    );
  }
}

class RemoveFriendConfirmModal extends StatelessWidget {
  final String friendUid;

  const RemoveFriendConfirmModal({super.key, required this.friendUid});

  static void show(BuildContext context, String friendUid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withAlpha(128),
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: RemoveFriendConfirmModal(friendUid: friendUid),
            ),
          ),
        );
      },
    );
  }

  Future<void> _removeFriend(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final currentUserUid = currentUser.uid;
      final firestore = FirebaseFirestore.instance;

      // Start a batch write for atomic operation
      final batch = firestore.batch();

      // Remove friend from current user's friends list
      final currentUserRef = firestore.collection('users').doc(currentUserUid);
      batch.update(currentUserRef, {
        'friends': FieldValue.arrayRemove([friendUid])
      });

      // Remove current user from friend's friends list
      final friendRef = firestore.collection('users').doc(friendUid);
      batch.update(friendRef, {
        'friends': FieldValue.arrayRemove([currentUserUid])
      });

      // Delete friend request records (both directions)
      final requestId1 = '${currentUserUid}_$friendUid';
      final requestId2 = '${friendUid}_$currentUserUid';
      
      final friendRequestRef1 = firestore.collection('friend_requests').doc(requestId1);
      final friendRequestRef2 = firestore.collection('friend_requests').doc(requestId2);
      
      // Check if documents exist before trying to delete them
      final doc1 = await friendRequestRef1.get();
      if (doc1.exists) {
        batch.delete(friendRequestRef1);
      }
      
      final doc2 = await friendRequestRef2.get();
      if (doc2.exists) {
        batch.delete(friendRequestRef2);
      }

      // Commit the batch
      await batch.commit();

      // Close the modal and show success message
      if (context.mounted) {
        Navigator.of(context).pop(); // Close confirmation modal
        Navigator.of(context).pop(); // Close profile page
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend removed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing friend: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.only(top: 12, bottom: 1, left: 12, right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Are you sure you want to remove user from friends?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Irina',
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 140,
            height: 45,
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 253, 65, 64),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextButton(
              onPressed: () async {
                await _removeFriend(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Irina',
                ),
                splashFactory: NoSplash.splashFactory,
                overlayColor: Colors.transparent,
              ),
              child: const Text('Remove'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Color.fromARGB(255, 95, 95, 95),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Irina',
              ),
              splashFactory: NoSplash.splashFactory,
              overlayColor: Colors.transparent,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}