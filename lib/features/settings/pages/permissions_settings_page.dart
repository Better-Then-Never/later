import 'package:flutter/material.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:later/core/theme/app_colors.dart';
import 'package:later/core/theme/app_text_styles.dart';
import 'package:later/shared/widgets/buttons/go_back_button.dart';
import 'package:later/shared/widgets/options/options_section.dart';
import 'package:later/shared/widgets/page_header.dart';

class PermissionsSettingsPage extends StatefulWidget {
  const PermissionsSettingsPage({super.key});

  @override
  State<PermissionsSettingsPage> createState() =>
      _PermissionsSettingsPageState();
}

class _PermissionsSettingsPageState extends State<PermissionsSettingsPage>
    with WidgetsBindingObserver {
  final Map<Permission, PermissionStatus> _permissionStatuses = {};
  bool _isLoading = true;

  final List<AppPermissionSetting> _permissions = [
    AppPermissionSetting(
      name: 'Camera',
      description: 'Access camera to create time capsules',
      permission: Permission.camera,
      iconAsset: AppIcons.cameraFull,
    ),
    AppPermissionSetting(
      name: 'Microphone',
      description: 'Record audio for time capsules',
      permission: Permission.microphone,
      iconAsset: AppIcons.capsuleMicrophone,
    ),
    AppPermissionSetting(
      name: 'Location',
      description: 'Find capsules nearby and location-based features',
      permission: Platform.isIOS
          ? Permission.locationWhenInUse
          : Permission.location,
      iconAsset: AppIcons.capsuleLocation,
    ),
    AppPermissionSetting(
      name: 'Notifications',
      description: 'Receive updates about followers and capsules',
      permission: Permission.notification,
      iconAsset: AppIcons.notificationsBlackFull,
    ),
    AppPermissionSetting(
      name: 'Contacts',
      description: 'Invite friends and find people you know',
      permission: Permission.contacts,
      iconAsset: AppIcons.friendsBook,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPermissionStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from the system settings: show what the user changed there
  /// (BUG-091).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadPermissionStatuses();
  }

  Future<void> _loadPermissionStatuses() async {
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
    if (!mounted) return; // BUG-090

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
          title: const Text(
            'Revoke Permission',
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'To revoke this permission, you need to go to your device settings. This will disable the related features in the app.',
            style: TextStyle(fontFamily: kAppFontFamily),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  color: AppColors.grey500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text(
                'Open Settings',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  color: AppColors.infoBlue,
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
          title: const Text(
            'Permission Required',
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'This permission has been permanently denied. Please enable it in your device settings.',
            style: TextStyle(fontFamily: kAppFontFamily),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  color: AppColors.grey500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text(
                'Open Settings',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  color: AppColors.infoBlue,
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
        return AppColors.brandGreen;
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
        return AppColors.errorPopup;
      case PermissionStatus.restricted:
      case PermissionStatus.limited:
      case PermissionStatus.provisional:
        return AppColors.warningOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.pageBackgroundAlt,
      body: Column(
        children: [
          PageHeader(
            mainText: 'App permissions',
            description: 'What Later may use on this phone',
            leadingButton: GoBackButton(context: context),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
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
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
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
                            style: const TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                permission.description,
                                style: const TextStyle(
                                  fontFamily: kAppFontFamily,
                                  fontSize: 14,
                                  color: AppColors.grey600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
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
                          trailing: AppSwitch(
                            value: status.isGranted,
                            onChanged: (_) =>
                                _togglePermission(permission.permission),
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
