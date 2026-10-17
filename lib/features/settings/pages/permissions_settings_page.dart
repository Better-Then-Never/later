import 'package:flutter/material.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/core/theme/app_colors.dart';
import 'package:later/core/theme/app_palette.dart';
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
      name: (l10n) => l10n.settingsPermissionCamera,
      description: (l10n) => l10n.settingsPermissionCameraDescription,
      permission: Permission.camera,
      iconAsset: AppIcons.cameraFull,
    ),
    AppPermissionSetting(
      name: (l10n) => l10n.settingsPermissionMicrophone,
      description: (l10n) => l10n.settingsPermissionMicrophoneDescription,
      permission: Permission.microphone,
      iconAsset: AppIcons.capsuleMicrophone,
    ),
    AppPermissionSetting(
      name: (l10n) => l10n.settingsPermissionLocation,
      description: (l10n) => l10n.settingsPermissionLocationDescription,
      permission: Platform.isIOS
          ? Permission.locationWhenInUse
          : Permission.location,
      iconAsset: AppIcons.capsuleLocation,
    ),
    AppPermissionSetting(
      name: (l10n) => l10n.settingsNotifications,
      description: (l10n) => l10n.settingsPermissionNotificationsDescription,
      permission: Permission.notification,
      iconAsset: AppIcons.notificationsBlackFull,
    ),
    AppPermissionSetting(
      name: (l10n) => l10n.settingsPermissionContacts,
      description: (l10n) => l10n.settingsPermissionContactsDescription,
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
          title: Text(
            context.l10n.settingsPermissionRevokeTitle,
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            context.l10n.settingsPermissionRevokeBody,
            style: const TextStyle(fontFamily: kAppFontFamily),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                context.l10n.commonCancel,
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  color: context.palette.iconMuted,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text(
                context.l10n.settingsPermissionOpenSettings,
                style: const TextStyle(
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
          title: Text(
            context.l10n.settingsPermissionRequiredTitle,
            style: const TextStyle(
              fontFamily: kAppFontFamily,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            context.l10n.settingsPermissionRequiredBody,
            style: const TextStyle(fontFamily: kAppFontFamily),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                context.l10n.commonCancel,
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  color: context.palette.iconMuted,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text(
                context.l10n.settingsPermissionOpenSettings,
                style: const TextStyle(
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

  String _getPermissionStatusText(
    AppLocalizations l10n,
    PermissionStatus status,
  ) {
    switch (status) {
      case PermissionStatus.granted:
        return l10n.settingsPermissionGranted;
      case PermissionStatus.denied:
        return l10n.settingsPermissionDenied;
      case PermissionStatus.restricted:
        return l10n.settingsPermissionRestricted;
      case PermissionStatus.limited:
        return l10n.settingsPermissionLimited;
      case PermissionStatus.permanentlyDenied:
        return l10n.settingsPermissionPermanentlyDenied;
      case PermissionStatus.provisional:
        return l10n.settingsPermissionProvisional;
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
    final palette = context.palette;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: palette.backgroundAlt,
      body: Column(
        children: [
          PageHeader(
            mainText: l10n.settingsAppPermissions,
            description: l10n.settingsPermissionsDescription,
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
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(15),
                          // A hairline edge in dark, where shadows do not
                          // show (as on every card); nothing in light.
                          border: palette.isDark
                              ? Border.all(color: palette.cardBorder)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: palette.shadowCard.withValues(alpha: 0.05),
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
                            permission.name(l10n),
                            style: TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                permission.description(l10n),
                                style: TextStyle(
                                  fontFamily: kAppFontFamily,
                                  fontSize: 14,
                                  color: palette.textMuted,
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
                                  _getPermissionStatusText(l10n, status),
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
  /// The name and what it is for, in the app's language.
  final String Function(AppLocalizations l10n) name;
  final String Function(AppLocalizations l10n) description;
  final String iconAsset;
  final Permission permission;

  AppPermissionSetting({
    required this.name,
    required this.description,
    required this.iconAsset,
    required this.permission,
  });
}
