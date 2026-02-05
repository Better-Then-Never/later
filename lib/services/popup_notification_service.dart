import 'package:flutter/material.dart';
import 'dart:async';
import 'package:later/views/widgets/_common/default_elements/popup_notification.dart';

enum NotificationPosition { top, center, bottom }

class PopupNotificationService {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;
  static GlobalKey<PopupNotificationState>? _currentKey;

  static void show({
    required BuildContext context,
    required String message,
    Color? backgroundColor,
    Color textColor = Colors.white,
    Color iconColor = Colors.white,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
    double topOffset = 50,
    double bottomOffset = 20,
    NotificationPosition position = NotificationPosition.bottom,
    bool enableExitAnimation = true,
  }) {
    if (!context.mounted) return;

    hide();

    final overlay = Overlay.of(context);
    _currentKey = GlobalKey<PopupNotificationState>();

    _overlayEntry = OverlayEntry(
      builder: (context) => PopupNotification(
        key: _currentKey,
        message: message,
        backgroundColor: backgroundColor ?? Colors.grey[800]!,
        textColor: textColor,
        iconColor: iconColor,
        icon: icon,
        position: position,
        topOffset: topOffset,
        bottomOffset: bottomOffset,
        enableExitAnimation: enableExitAnimation,
        onDismiss: hide,
      ),
    );

    overlay.insert(_overlayEntry!);

    _timer = Timer(duration, () {
      if (enableExitAnimation) {
        _hideWithAnimation();
      } else {
        hide();
      }
    });
  }

  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    NotificationPosition position = NotificationPosition.bottom,
    bool enableExitAnimation = true,
  }) {
    show(
      context: context,
      message: message,
      backgroundColor: const Color.fromARGB(255, 86, 201, 46),
      icon: Icons.check_circle,
      duration: duration,
      position: position,
      enableExitAnimation: enableExitAnimation,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    NotificationPosition position = NotificationPosition.bottom,
    bool enableExitAnimation = true,
  }) {
    show(
      context: context,
      message: message,
      backgroundColor: const Color.fromARGB(255, 255, 87, 87),
      icon: Icons.error,
      duration: duration,
      position: position,
      enableExitAnimation: enableExitAnimation,
    );
  }

  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    NotificationPosition position = NotificationPosition.bottom,
    bool enableExitAnimation = true,
  }) {
    show(
      context: context,
      message: message,
      backgroundColor: const Color.fromARGB(255, 33, 150, 243),
      icon: Icons.info,
      duration: duration,
      position: position,
      enableExitAnimation: enableExitAnimation,
    );
  }

  static void _hideWithAnimation() {
    if (_currentKey?.currentState != null) {
      _currentKey!.currentState!.startExitAnimation();
    } else {
      hide();
    }
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _currentKey = null;
  }
}
