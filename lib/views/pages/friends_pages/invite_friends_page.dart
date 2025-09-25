import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:later/services/popup_notification_service.dart';
import 'package:later/views/widgets/friends/contacts_list.dart';

class InviteFriendsPage extends StatefulWidget {
  const InviteFriendsPage({super.key});

  @override
  State<InviteFriendsPage> createState() => _InviteFriendsPageState();
}

class _InviteFriendsPageState extends State<InviteFriendsPage> {
  List<Contact> _contacts = [];
  bool _isLoading = true;
  bool _hasPermission = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadContacts();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionAndLoadContacts() async {
    try {
      setState(() {
        _isLoading = true;
        _hasPermission = true;
      });

      final status = await Permission.contacts.status;

      if (!status.isGranted) {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
        return;
      }

      await _loadContacts();
    } catch (e) {
      print('Error checking permission: $e');
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      final validContacts = contacts
          .where((contact) => contact.phones.isNotEmpty)
          .toList();

      validContacts.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );

      if (mounted) {
        setState(() {
          _contacts = validContacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading contacts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        PopupNotificationService.showError(
          context: context,
          message: 'Failed to load contacts',
          position: NotificationPosition.bottom,
        );
      }
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.contacts.request();

    if (status.isGranted) {
      _checkPermissionAndLoadContacts();
    } else if (status.isPermanentlyDenied) {
      _showSettingsDialog();
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Permission Required',
            style: TextStyle(fontFamily: 'Irina', fontWeight: FontWeight.bold),
          ),
          content: Text(
            'To invite friends, Later needs access to your contacts. Please enable contacts permission in your device settings.',
            style: TextStyle(fontFamily: 'Irina'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(fontFamily: 'Irina', color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text(
                'Open Settings',
                style: TextStyle(
                  fontFamily: 'Irina',
                  color: Color.fromARGB(255, 33, 150, 243),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionDeniedWidget() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/icons/friends_page/friend_book.png',
              width: screenWidth * 0.3,
              height: screenWidth * 0.3,
              color: Colors.grey[400],
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              'Contacts Access Required',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Irina',
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'To invite friends to Later, we need access to your contacts. This helps you find and invite people you know.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Irina',
                fontSize: screenWidth * 0.04,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: screenHeight * 0.04),
            SizedBox(
              width: screenWidth * 0.6,
              height: 50,
              child: ElevatedButton(
                onPressed: _requestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 86, 201, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Grant Permission',
                  style: TextStyle(
                    fontFamily: 'Irina',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          // Header
          Container(
            width: screenWidth,
            height: screenHeight * 0.18,
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
                  bottom: _hasPermission ? 4 : 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'Invite friends',
                          style: TextStyle(
                            fontSize: screenWidth * 0.10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Irina',
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 1),
                        if (_hasPermission) ...[
                          Padding(
                            padding: EdgeInsets.only(
                              left: screenWidth * 0.05,
                              right: screenWidth * 0.05,
                              top: 0,
                              bottom: screenHeight * 0.01,
                            ),
                            child: Container(
                              height: 45,
                              decoration: BoxDecoration(
                                color: Color(0xFFEAEAEA),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                    ),
                                    child: Image.asset(
                                      'assets/images/icons/friends_page/look_for.png',
                                      width: screenWidth * 0.07,
                                      height: screenWidth * 0.07,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: InputDecoration(
                                        hintText: "Search...",
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Irina',
                                        fontSize: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                              vertical: 0,
                            ),
                            child: Text(
                              'Please grant permission',
                              style: TextStyle(
                                fontFamily: 'Irina',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color.fromARGB(255, 94, 94, 94),
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                        ],
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: _hasPermission ? 64 : 30,
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

          Expanded(
            child: !_hasPermission
                ? _buildPermissionDeniedWidget()
                : Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: screenWidth * 0.07,
                            top: screenHeight * 0.009,
                          ),
                          child: Text(
                            'Invite to Later',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Irina',
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ContactsList(
                          contacts: _contacts,
                          searchQuery: _searchQuery,
                          isLoading: _isLoading,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
