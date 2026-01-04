import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:later/views/widgets/_common/default_elements/later_loading_bar.dart';
import 'dart:io';

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

class _PermissionGatePageState extends State<PermissionGatePage> {
  final Map<Permission, PermissionStatus> _statuses = {};
  bool _loaded = false;
  bool _navigated = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<AppPermission> _permissionsList = [
    AppPermission(
      name: "Share Camera access with Later",
      description: "And you will be able to create time capsules!",
      permission: Permission.camera,
      iconAsset: "assets/images/icons/camera/Camerafull.png",
    ),
    AppPermission(
      name: "Provide Later with microphone access",
      description: "Camera won't work without it",
      permission: Permission.microphone,
      iconAsset: "assets/images/icons/capsule_creation/microphone_icon.png",
    ),
    AppPermission(
      name: "Share geolocation with us",
      description: "And you will be able to find capsules nearby you!",
      permission: Platform.isIOS
          ? Permission.locationWhenInUse
          : Permission.location,
      iconAsset: "assets/images/icons/capsule_creation/location_icon.png",
    ),
    AppPermission(
      name: "Enable notifications",
      description: "Stay updated with new followers and capsules!",
      permission: Permission.notification,
      iconAsset: "assets/images/icons/prof_page/notifications_button_black_full.png",
    ),
    AppPermission(
      name: "Access contacts",
      description: "Find and invite friends from your contacts!",
      permission: Permission.contacts,
      iconAsset: "assets/images/icons/friends_page/friend_book.png",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    for (var item in _permissionsList) {
      final status = await item.permission.status;
      _statuses[item.permission] = status;
    }

    if (!mounted) return;

    final allRequiredGranted = _permissionsList.every(
      (p) => _statuses[p.permission]?.isGranted ?? false,
    );

    if (allRequiredGranted) {
      widget.onAllGranted();
    } else {
      setState(() => _loaded = true);
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    _statuses[permission] = status;
    if (!mounted) return;
    setState(() {});
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }

    if (status.isGranted) {
      final nextPage = _currentPage + 1;

      if (nextPage < _permissionsList.length) {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
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
      return Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        body: Center(child: LaterLoadingBar(width: 150, height: 150)),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
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
                      color: const Color(0xFFF6F6F6),
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
                                    fontFamily: 'Irina',
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 0, 0, 0),
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
                                  backgroundColor: const Color(0xFF56C92E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25.0),
                                  ),
                                ),
                                child: Text(
                                  granted ? "Granted" : "Enable",
                                  style: const TextStyle(
                                    fontFamily: 'Irina',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
                        ? const Color(0xFF56C92E)
                        : Colors.grey.shade400,
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