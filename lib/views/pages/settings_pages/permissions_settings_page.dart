import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

// TODO: Refactor

class PermissionsSettingsPage extends StatefulWidget {
  const PermissionsSettingsPage({super.key});

  @override
  State<PermissionsSettingsPage> createState() =>
      _PermissionsSettingsPageState();
}

class _PermissionsSettingsPageState extends State<PermissionsSettingsPage> {
  final Map<Permission, PermissionStatus> _permissionStatuses = {};
  bool _isLoading = true;

  final List<AppPermissionSetting> _permissions = [
    AppPermissionSetting(
      name: "Camera",
      description: "Access camera to create time capsules",
      permission: Permission.camera,
      iconAsset: "assets/images/icons/camera/Camerafull.png",
    ),
    AppPermissionSetting(
      name: "Microphone",
      description: "Record audio for time capsules",
      permission: Permission.microphone,
      iconAsset: "assets/images/icons/capsule_creation/microphone_icon.png",
    ),
    AppPermissionSetting(
      name: "Location",
      description: "Find capsules nearby and location-based features",
      permission: Platform.isIOS
          ? Permission.locationWhenInUse
          : Permission.location,
      iconAsset: "assets/images/icons/capsule_creation/location_icon.png",
    ),
    AppPermissionSetting(
      name: "Contacts",
      description: "Invite friends and find people you know",
      permission: Permission.contacts,
      iconAsset: "assets/images/icons/friends_page/friend_book.png",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadPermissionStatuses();
  }

  Future<void> _loadPermissionStatuses() async {
    setState(() => _isLoading = true);

    for (var permission in _permissions) {
      final status = await permission.permission.status;
      _permissionStatuses[permission.permission] = status;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePermission(Permission permission) async {
    final currentStatus = _permissionStatuses[permission];

    if (currentStatus?.isGranted ?? false) {
      // Permission is granted, show dialog to revoke
      _showRevokePermissionDialog(permission);
    } else {
      // Permission is not granted, request it
      await _requestPermission(permission);
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();

    if (status.isPermanentlyDenied) {
      _showPermissionDialog(permission);
    } else {
      _permissionStatuses[permission] = status;
      if (mounted) setState(() {});
    }
  }

  void _showRevokePermissionDialog(Permission permission) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Revoke Permission',
            style: TextStyle(fontFamily: 'Irina', fontWeight: FontWeight.bold),
          ),
          content: Text(
            'To revoke this permission, you need to go to your device settings. This will disable the related features in the app.',
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

  void _showPermissionDialog(Permission permission) {
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
            'This permission has been permanently denied. Please enable it in your device settings.',
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

  String _getPermissionStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.restricted:
        return 'Restricted';
      case PermissionStatus.limited:
        return 'Limited';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      case PermissionStatus.provisional:
        return 'Provisional';
    }
  }

  Color _getPermissionStatusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Color.fromARGB(255, 86, 201, 46);
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
        return Color.fromARGB(255, 255, 87, 87);
      case PermissionStatus.restricted:
      case PermissionStatus.limited:
      case PermissionStatus.provisional:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header
          Container(
            width: screenWidth,
            height: screenHeight * 0.16,
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
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'App permissions',
                          style: TextStyle(
                            fontSize: screenWidth * 0.095,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Irina',
                            color: Colors.black,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: 0,
                          ),
                          child: Text(
                            'Manage app permissions',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'Irina',
                              color: Color.fromARGB(255, 94, 94, 94),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 39,
                  left: 8,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
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
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.only(
                      left: screenWidth * 0.04,
                      right: screenWidth * 0.04,
                      top: screenWidth * 0.04,
                      bottom: screenHeight * 0.04,
                    ),
                    itemCount: _permissions.length,
                    itemBuilder: (context, index) {
                      final permission = _permissions[index];
                      final status =
                          _permissionStatuses[permission.permission] ??
                          PermissionStatus.denied;

                      return Container(
                        margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.asset(
                              permission.iconAsset,
                              width: 24,
                              height: 24,
                            ),
                          ),
                          title: Text(
                            permission.name,
                            style: TextStyle(
                              fontFamily: 'Irina',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                permission.description,
                                style: TextStyle(
                                  fontFamily: 'Irina',
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPermissionStatusColor(
                                    status,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getPermissionStatusText(status),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _getPermissionStatusColor(status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Switch(
                            value: status.isGranted,
                            onChanged: (_) =>
                                _togglePermission(permission.permission),
                            activeThumbColor: Color.fromARGB(255, 86, 201, 46),
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.grey.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class AppPermissionSetting {
  final String name;
  final String description;
  final String iconAsset;
  final Permission permission;

  AppPermissionSetting({
    required this.name,
    required this.description,
    required this.iconAsset,
    required this.permission,
  });
}
