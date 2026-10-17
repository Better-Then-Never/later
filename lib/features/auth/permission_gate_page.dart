import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/assets/app_assets.dart';
import '../../shared/widgets/later_loading_bar.dart';
import '../../core/theme/app_colors.dart';
import 'package:later/core/theme/app_text_styles.dart';
import 'package:later/core/theme/app_motion.dart';

class AppPermission {
  final String name;
  final String description;
  final String iconAsset;
  final Permission permission;

  AppPermission({
    required this.name,
    required this.description,
    required this.permission,
    required this.iconAsset,
  });
}

class PermissionGatePage extends StatefulWidget {
  final VoidCallback onAllGranted;

  const PermissionGatePage({super.key, required this.onAllGranted});

  @override
  State<PermissionGatePage> createState() => _PermissionGatePageState();
}

class _PermissionGatePageState extends State<PermissionGatePage>
    with WidgetsBindingObserver {
  final Map<Permission, PermissionStatus> _statuses = {};
  bool _loaded = false;
  bool _navigated = false;
  late final PageController _pageController;
  int _currentPage = 0;

  final List<AppPermission> _permissionsList = [
    AppPermission(
      name: 'Share Camera access with Later',
      description: 'And you will be able to create time capsules!',
      permission: Permission.camera,
      iconAsset: AppIcons.cameraFull,
    ),
    AppPermission(
      name: 'Provide Later with microphone access',
      description: "Camera won't work without it",
      permission: Permission.microphone,
      iconAsset: AppIcons.capsuleMicrophone,
    ),
    AppPermission(
      name: 'Share geolocation with us',
      description: 'And you will be able to find capsules nearby you!',
      permission: Platform.isIOS
          ? Permission.locationWhenInUse
          : Permission.location,
      iconAsset: AppIcons.capsuleLocation,
    ),
    AppPermission(
      name: 'Enable notifications',
      description: 'Stay updated with new followers and capsules!',
      permission: Permission.notification,
      iconAsset: AppIcons.notificationsBlackFull,
    ),
    AppPermission(
      name: 'Access contacts',
      description: 'Find and invite friends from your contacts!',
      permission: Permission.contacts,
      iconAsset: AppIcons.friendsBook,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_loaded) _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may have granted a permission in the system settings.
    if (state == AppLifecycleState.resumed && _loaded) _refreshStatuses();
  }

  Future<void> _readStatuses() async {
    for (final item in _permissionsList) {
      _statuses[item.permission] = await item.permission.status;
    }
  }

  bool _isGranted(AppPermission p) =>
      _statuses[p.permission]?.isGranted ?? false;

  /// First page whose permission is still missing (0 when none).
  int _firstPendingIndex({int from = 0}) {
    for (var i = from; i < _permissionsList.length; i++) {
      if (!_isGranted(_permissionsList[i])) return i;
    }
    for (var i = 0; i < from && i < _permissionsList.length; i++) {
      if (!_isGranted(_permissionsList[i])) return i;
    }
    return 0;
  }

  Future<void> _checkPermissions() async {
    await _readStatuses();
    if (!mounted) return;

    if (_permissionsList.every(_isGranted)) {
      _navigated = true;
      widget.onAllGranted();
    } else {
      _currentPage = _firstPendingIndex();
      _pageController = PageController(initialPage: _currentPage);
      setState(() => _loaded = true);
    }
  }

  Future<void> _refreshStatuses() async {
    await _readStatuses();
    if (!mounted) return;
    setState(() {});
    _checkIfAllGranted();
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    _statuses[permission] = status;
    if (!mounted) return;
    setState(() {});
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }

    if (status.isGranted && !_permissionsList.every(_isGranted)) {
      // Skip pages that are already granted.
      final next = _firstPendingIndex(from: _currentPage + 1);
      await _pageController.animateToPage(
        next,
        duration: AppMotion.reveal,
        curve: AppMotion.enter,
      );
    }

    _checkIfAllGranted();
  }

  void _checkIfAllGranted() {
    if (_navigated || !_loaded) return;

    if (_statuses.length != _permissionsList.length) return;

    final allRequiredGranted = _permissionsList.every(
      (p) => _statuses[p.permission]?.isGranted ?? false,
    );

    if (allRequiredGranted && mounted) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onAllGranted();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Center(child: LaterLoadingBar(width: 150, height: 150)),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: screenHeight * 0.6,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _permissionsList.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final item = _permissionsList[index];
                  final granted =
                      _statuses[item.permission]?.isGranted ?? false;

                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Card(
                      color: AppColors.pageBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              item.iconAsset,
                              width: 150,
                              height: 150,
                              fit: BoxFit.contain,
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 50,
                                    fontFamily: kAppFontFamily,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              item.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: 250,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: granted
                                    ? null
                                    : () => _requestPermission(item.permission),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25.0),
                                  ),
                                ),
                                child: Text(
                                  granted ? 'Granted' : 'Enable',
                                  style: const TextStyle(
                                    fontFamily: kAppFontFamily,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                    fontSize: 25.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_permissionsList.length, (index) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  width: _currentPage == index ? 16 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.brandGreen
                        : AppColors.grey400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
