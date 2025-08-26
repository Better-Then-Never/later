import 'package:flutter/material.dart';

enum NotificationPosition { top, center, bottom }

class OverlayNotification {
  static OverlayEntry? _overlayEntry;
  static AnimationController? _exitController;

  static void show({
    required BuildContext context,
    required String message,
    Color backgroundColor = const Color.fromARGB(255, 255, 87, 87),
    Color textColor = Colors.white,
    Color iconColor = Colors.white,
    IconData icon = Icons.warning_amber_rounded,
    Duration duration = const Duration(seconds: 2),
    double topOffset = 50,
    double bottomOffset = 50,
    NotificationPosition position = NotificationPosition.top,
    @Deprecated('Use position parameter instead') bool center = false,
  }) {
    // Check if context is still valid
    if (!context.mounted) return;

    try {
      // Handle backward compatibility
      NotificationPosition finalPosition = position;
      if (center) {
        finalPosition = NotificationPosition.center;
      }

      // Remove any existing overlay
      hide();

      // Get overlay state with null check
      final overlay = Overlay.of(context, rootOverlay: true);

      _overlayEntry = OverlayEntry(
        builder: (context) {
          return _NotificationWidget(
            message: message,
            backgroundColor: backgroundColor,
            textColor: textColor,
            iconColor: iconColor,
            icon: icon,
            position: finalPosition,
            topOffset: topOffset,
            bottomOffset: bottomOffset,
            duration: duration,
          );
        },
      );

      overlay.insert(_overlayEntry!);

      // Auto remove after duration with exit animation
      Future.delayed(duration, () {
        _hideWithAnimation(context, finalPosition, message, backgroundColor, textColor, iconColor, icon, topOffset, bottomOffset);
      });
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  static void _hideWithAnimation(
    BuildContext context,
    NotificationPosition position,
    String message,
    Color backgroundColor,
    Color textColor,
    Color iconColor,
    IconData icon,
    double topOffset,
    double bottomOffset,
  ) async {
    if (_overlayEntry == null || !context.mounted) return;

    try {
      // Remove current overlay
      _overlayEntry?.remove();

      // Create exit animation overlay
      final overlay = Overlay.of(context, rootOverlay: true);
      
      _overlayEntry = OverlayEntry(
        builder: (context) {
          return _ExitNotificationWidget(
            message: message,
            backgroundColor: backgroundColor,
            textColor: textColor,
            iconColor: iconColor,
            icon: icon,
            position: position,
            topOffset: topOffset,
            bottomOffset: bottomOffset,
            onComplete: () {
              hide();
            },
          );
        },
      );

      overlay.insert(_overlayEntry!);
    } catch (e) {
      print('Error in exit animation: $e');
      hide();
    }
  }

  static void hide() {
    try {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _exitController?.dispose();
      _exitController = null;
    } catch (e) {
      print('Error hiding notification: $e');
      _overlayEntry = null;
      _exitController = null;
    }
  }

  // Success notification preset
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    NotificationPosition position = NotificationPosition.top,
    @Deprecated('Use position parameter instead') bool center = false,
  }) {
    show(
      context: context,
      message: message,
      backgroundColor: const Color.fromARGB(255, 86, 201, 46),
      icon: Icons.check_circle,
      duration: duration,
      position: position,
      center: center,
    );
  }

  // Error notification preset
  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    NotificationPosition position = NotificationPosition.top,
    @Deprecated('Use position parameter instead') bool center = false,
  }) {
    show(
      context: context,
      message: message,
      backgroundColor: const Color.fromARGB(255, 255, 87, 87),
      icon: Icons.warning_amber_rounded,
      duration: duration,
      position: position,
      center: center,
    );
  }

  // Info notification preset
  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    NotificationPosition position = NotificationPosition.top,
    @Deprecated('Use position parameter instead') bool center = false,
  }) {
    show(
      context: context,
      message: message,
      backgroundColor: const Color.fromARGB(255, 33, 150, 243),
      icon: Icons.info,
      duration: duration,
      position: position,
      center: center,
    );
  }
}

class _NotificationWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final IconData icon;
  final NotificationPosition position;
  final double topOffset;
  final double bottomOffset;
  final Duration duration;

  const _NotificationWidget({
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    required this.icon,
    required this.position,
    required this.topOffset,
    required this.bottomOffset,
    required this.duration,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Define slide animation based on position
    Offset startOffset;
    switch (widget.position) {
      case NotificationPosition.top:
        startOffset = const Offset(0, -1);
        break;
      case NotificationPosition.center:
        startOffset = const Offset(0, 0.3);
        break;
      case NotificationPosition.bottom:
        startOffset = const Offset(0, 1);
        break;
    }

    _slideAnimation = Tween<Offset>(
      begin: startOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildNotificationContent();
  }

  Widget _buildNotificationContent() {
    Widget notificationWidget = SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: widget.position == NotificationPosition.center
                  ? MainAxisSize.min
                  : MainAxisSize.max,
              children: [
                Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                widget.position == NotificationPosition.center
                    ? Flexible(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            fontFamily: 'Irina',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.textColor,
                          ),
                        ),
                      )
                    : Expanded(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            fontFamily: 'Irina',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.textColor,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );

    switch (widget.position) {
      case NotificationPosition.top:
        return Positioned(
          top: MediaQuery.of(context).padding.top + widget.topOffset,
          left: 16,
          right: 16,
          child: notificationWidget,
        );
      case NotificationPosition.center:
        return Center(child: notificationWidget);
      case NotificationPosition.bottom:
        return Positioned(
          bottom: MediaQuery.of(context).padding.bottom + widget.bottomOffset,
          left: 16,
          right: 16,
          child: notificationWidget,
        );
    }
  }
}

class _ExitNotificationWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final IconData icon;
  final NotificationPosition position;
  final double topOffset;
  final double bottomOffset;
  final VoidCallback onComplete;

  const _ExitNotificationWidget({
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    required this.icon,
    required this.position,
    required this.topOffset,
    required this.bottomOffset,
    required this.onComplete,
  });

  @override
  State<_ExitNotificationWidget> createState() => _ExitNotificationWidgetState();
}

class _ExitNotificationWidgetState extends State<_ExitNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    // Define exit slide animation based on position
    Offset endOffset;
    switch (widget.position) {
      case NotificationPosition.top:
        endOffset = const Offset(0, -1);
        break;
      case NotificationPosition.center:
        endOffset = const Offset(0, -0.3);
        break;
      case NotificationPosition.bottom:
        endOffset = const Offset(0, 1);
        break;
    }

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: endOffset,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    // Start exit animation
    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget notificationWidget = SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: widget.position == NotificationPosition.center
                  ? MainAxisSize.min
                  : MainAxisSize.max,
              children: [
                Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                widget.position == NotificationPosition.center
                    ? Flexible(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            fontFamily: 'Irina',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.textColor,
                          ),
                        ),
                      )
                    : Expanded(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            fontFamily: 'Irina',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.textColor,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );

    switch (widget.position) {
      case NotificationPosition.top:
        return Positioned(
          top: MediaQuery.of(context).padding.top + widget.topOffset,
          left: 16,
          right: 16,
          child: notificationWidget,
        );
      case NotificationPosition.center:
        return Center(child: notificationWidget);
      case NotificationPosition.bottom:
        return Positioned(
          bottom: MediaQuery.of(context).padding.bottom + widget.bottomOffset,
          left: 16,
          right: 16,
          child: notificationWidget,
        );
    }
  }
}