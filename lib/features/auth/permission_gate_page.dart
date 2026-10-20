import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/assets/app_assets.dart';
import '../../core/l10n/l10n.dart';
import '../../data/services/preferences_store.dart';
import '../../shared/widgets/splash_logo.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import 'package:later/core/theme/app_text_styles.dart';
import 'package:later/core/theme/app_motion.dart';

class AppPermission {
  /// Title and text in the app's language.
  final String Function(AppLocalizations l10n) name;
  final String Function(AppLocalizations l10n) description;
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

  const PermissionGatePage({
    super.key,
    required this.uid,
    required this.onAllGranted,
  });

  /// The signed-in user: the onboarding is shown once per account.
  final String uid;

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
      name: (l10n) => l10n.authPermissionCameraTitle,
      description: (l10n) => l10n.authPermissionCameraText,
      permission: Permission.camera,
      iconAsset: AppIcons.cameraFull,
    ),
    AppPermission(
      name: (l10n) => l10n.authPermissionLocationTitle,
      description: (l10n) => l10n.authPermissionLocationText,
      permission: Platform.isIOS
          ? Permission.locationWhenInUse
          : Permission.location,
      iconAsset: AppIcons.capsuleLocation,
    ),
    AppPermission(
      name: (l10n) => l10n.authPermissionNotificationsTitle,
      description: (l10n) => l10n.authPermissionNotificationsText,
      permission: Permission.notification,
      iconAsset: AppIcons.notificationsBlackFull,
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

  static const _seenKey = 'permission_onboarding';

  Future<void> _checkPermissions() async {
    final prefs = context.read<PreferencesStore>();
    final seen = await prefs.string(widget.uid, _seenKey) == 'done';
    await _readStatuses();
    if (!mounted) return;

    // Shown once per account on this phone: afterwards each feature asks
    // for its permission when it needs it (F-42).
    if (seen || _permissionsList.every(_isGranted)) {
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

    if (status.isGranted) await _next();
  }

  /// The next page still asking for something, or into the app after the
  /// last one: every permission is optional here.
  Future<void> _next() async {
    for (var i = _currentPage + 1; i < _permissionsList.length; i++) {
      if (!_isGranted(_permissionsList[i])) {
        await _pageController.animateToPage(
          i,
          duration: AppMotion.reveal,
          curve: AppMotion.enter,
        );
        return;
      }
    }
    await _finish();
  }

  Future<void> _finish() async {
    if (_navigated) return;
    _navigated = true;
    await context.read<PreferencesStore>().setString(
      widget.uid,
      _seenKey,
      'done',
    );
    if (mounted) widget.onAllGranted();
  }

  void _checkIfAllGranted() {
    if (_navigated || !_loaded) return;

    if (_statuses.length != _permissionsList.length) return;

    final allRequiredGranted = _permissionsList.every(
      (p) => _statuses[p.permission]?.isGranted ?? false,
    );

    if (allRequiredGranted && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _finish();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // At every start, for a few frames: the splash's picture, not a
    // loader on another colour (docs/map/COLD_START.md).
    if (!_loaded) return const SplashLogo();

    final screenHeight = MediaQuery.of(context).size.height;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: context.palette.background,
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
                      color: context.palette.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                        // Transparent in light; the card's edge in dark,
                        // where its shadow does not show.
                        side: BorderSide(color: context.palette.cardBorder),
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
                                  item.name(l10n),
                                  style: TextStyle(
                                    fontSize: 50,
                                    fontFamily: kAppFontFamily,
                                    fontWeight: FontWeight.bold,
                                    color: context.palette.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              item.description(l10n),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: 250,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: granted
                                    ? _next
                                    : () => _requestPermission(item.permission),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25.0),
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    granted
                                        ? l10n.commonContinue
                                        : l10n.authPermissionEnable,
                                    style: const TextStyle(
                                      fontFamily: kAppFontFamily,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onAccent,
                                      fontSize: 25.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (!granted)
                              TextButton(
                                onPressed: _next,
                                child: Text(
                                  l10n.authPermissionNotNow,
                                  style: TextStyle(
                                    fontFamily: kAppFontFamily,
                                    fontSize: 16,
                                    color: context.palette.textSecondary,
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
                        : context.palette.disabled,
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
