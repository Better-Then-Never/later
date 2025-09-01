import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:later/services/cache_firebase/user_services.dart';
import 'package:later/services/appearance/notification_system.dart';

class SharePage extends StatelessWidget {
  const SharePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          // Header section
          Container(
            width: screenWidth,
            height: screenHeight * 0.12,
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
                  bottom: 5,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Share profile',
                      style: TextStyle(
                        fontSize: screenWidth * 0.10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Irina',
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 8,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
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

          // QR Code Widget
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.03,
              ),
              child: QRShareWidget(),
            ),
          ),
        ],
      ),
    );
  }
}

class QRShareWidget extends StatelessWidget {
  const QRShareWidget({super.key});

  String _generateProfileLink(String userId) {
    return 'https://later-da778.web.app/?userId=$userId';
  }

  Future<void> _shareProfile(BuildContext context, String userId) async {
    try {
      final link = _generateProfileLink(userId);
      await Share.share(
        'Add me on Later! \n$link',
        subject: 'Connect with me on Later',
      );
    } catch (e) {
      if (context.mounted) {
        UnifiedNotification.showError(
          context: context,
          message: 'Failed to share profile',
          position: NotificationPosition.bottom,
        );
      }
    }
  }

  Future<void> _copyLink(BuildContext context, String userId) async {
    try {
      final link = _generateProfileLink(userId);
      await Clipboard.setData(ClipboardData(text: link));

      if (context.mounted) {
        UnifiedNotification.showSuccess(
          context: context,
          message: 'Link copied to clipboard!',
          position: NotificationPosition.bottom,
        );
      }
    } catch (e) {
      if (context.mounted) {
        UnifiedNotification.showError(
          context: context,
          message: 'Failed to copy link',
          position: NotificationPosition.bottom,
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final userService = Provider.of<UserService>(context);
    final userId = userService.uid;

    if (userId == null) {
      return Center(
        child: Text(
          'Unable to load user profile',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
            fontFamily: 'Irina',
          ),
        ),
      );
    }

    final profileLink = _generateProfileLink(userId);

    return Column(
      children: [
        // Title and description
        Text(
          'Share Your Profile',
          style: TextStyle(
            fontSize: screenWidth * 0.065,
            fontWeight: FontWeight.bold,
            fontFamily: 'Irina',
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: screenHeight * 0.005),

        Text(
          'Let others scan this QR code to add you as a friend',
          style: TextStyle(
            fontSize: screenWidth * 0.042,
            fontFamily: 'Irina',
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: screenHeight * 0.03),

        // QR Code Container
        Container(
          width: screenWidth * 0.75,
          height: screenWidth * 0.75,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                spreadRadius: 2,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: QrImageView(
              data: profileLink,
              version: QrVersions.auto,
              size: screenWidth * 0.55,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
              errorStateBuilder: (cxt, err) {
                return Center(
                  child: Text(
                    "Something went wrong...",
                    style: TextStyle(fontFamily: 'Irina', color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ),


        SizedBox(height: screenHeight * 0.02),

        // User info below QR code
        FutureBuilder<Map<String, dynamic>?>(
          future: _getUserData(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            final userData = snapshot.data;
            final displayName =
                userData?['name'] ?? userData?['displayName'] ?? 'User';
            final username = userData?['username'];

            return Column(
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: screenWidth * 0.055,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Irina',
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (username != null && username.isNotEmpty)
                  Text(
                    '@$username',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontFamily: 'Irina',
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  )
                else
                  Text(
                    'User ID: ${userId.substring(0, 8)}...',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontFamily: 'Irina',
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            );
          },
        ),

        SizedBox(height: screenHeight * 0.03),

        // Action buttons
        Row(
          children: [
            // Share button
            Expanded(
              child: Container(
                height: screenHeight * 0.06,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 33, 150, 243),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _shareProfile(context, userId),
                  icon: const Icon(Icons.share, size: 20),
                  label: Text(
                    'Share',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Irina',
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: 16),

            // Copy link button
            Expanded(
              child: Container(
                height: screenHeight * 0.06,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEAEAEA),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _copyLink(context, userId),
                  icon: const Icon(Icons.copy, size: 20),
                  label: Text(
                    'Copy Link',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Irina',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: screenHeight * 0.03),

        // Instructions
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Others can scan this code with their camera or the app to add you as a friend',
                  style: TextStyle(
                    fontSize: screenWidth * 0.037,
                    fontFamily: 'Irina',
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
