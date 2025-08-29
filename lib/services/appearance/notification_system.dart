import 'package:flutter/material.dart';
import 'dart:async';

enum NotificationPosition { top, center, bottom }

class UnifiedNotification {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;
  static GlobalKey<_UnifiedNotificationWidgetState>? _currentKey;
  
  /// Main notification method with full customization
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
    _currentKey = GlobalKey<_UnifiedNotificationWidgetState>();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => _UnifiedNotificationWidget(
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
  
  /// Success notification preset
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
  
  /// Error notification preset
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
  
  /// Info notification preset
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
      _currentKey!.currentState!._startExitAnimation();
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

class _UnifiedNotificationWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final IconData? icon;
  final NotificationPosition position;
  final double topOffset;
  final double bottomOffset;
  final bool enableExitAnimation;
  final VoidCallback onDismiss;
  
  const _UnifiedNotificationWidget({
    super.key,
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    this.icon,
    required this.position,
    required this.topOffset,
    required this.bottomOffset,
    required this.enableExitAnimation,
    required this.onDismiss,
  });
  
  @override
  State<_UnifiedNotificationWidget> createState() => _UnifiedNotificationWidgetState();
}

class _UnifiedNotificationWidgetState extends State<_UnifiedNotificationWidget>
    with TickerProviderStateMixin { 
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isExiting = false;
  AnimationController? _exitController; 
  
  @override
  void initState() {
    super.initState();
    _setupEntryAnimations();
    _controller.forward();
  }
  
  void _setupEntryAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Entry animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _slideAnimation = _createSlideAnimation(false);
  }
  
  Animation<Offset> _createSlideAnimation(bool isExit) {
    Offset startOffset, endOffset;
    
    switch (widget.position) {
      case NotificationPosition.top:
        startOffset = isExit ? Offset.zero : const Offset(0, -1);
        endOffset = isExit ? const Offset(0, -1) : Offset.zero;
        break;
      case NotificationPosition.center:
        startOffset = isExit ? Offset.zero : const Offset(0, 0.3);
        endOffset = isExit ? const Offset(0, -0.3) : Offset.zero;
        break;
      case NotificationPosition.bottom:
        startOffset = isExit ? Offset.zero : const Offset(0, 1);
        endOffset = isExit ? const Offset(0, 1) : Offset.zero;
        break;
    }
    
    return Tween<Offset>(
      begin: startOffset,
      end: endOffset,
    ).animate(CurvedAnimation(
      parent: _controller, 
      curve: isExit ? Curves.easeIn : Curves.easeOut,
    ));
  }
  
  void _startExitAnimation() {
    if (_isExiting || !mounted) return;
    
    _isExiting = true;
    
    // Exit animations
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    final exitFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _exitController!, curve: Curves.easeIn));
    
    final exitSlideAnimation = _createExitSlideAnimation(_exitController!);
    
    setState(() {
      _fadeAnimation = exitFadeAnimation;
      _slideAnimation = exitSlideAnimation;
    });
    
    _exitController!.forward().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }
  
  Animation<Offset> _createExitSlideAnimation(AnimationController controller) {
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
    
    return Tween<Offset>(
      begin: Offset.zero,
      end: endOffset,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeIn));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _exitController?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return _buildPositionedNotification(context);
  }
  
  Widget _buildPositionedNotification(BuildContext context) {
    final notificationContent = SlideTransition(
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
                  color: Colors.black.withAlpha((0.2 * 255).round()),
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
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: widget.iconColor, size: 20),
                  const SizedBox(width: 8),
                ],
                widget.position == NotificationPosition.center
                    ? Flexible(
                        child: _buildMessageText(),
                      )
                    : Expanded(
                        child: _buildMessageText(),
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
          left: 0,
          right: 0,
          child: notificationContent,
        );
      case NotificationPosition.center:
        return Center(child: notificationContent);
      case NotificationPosition.bottom:
        return Positioned(
          bottom: MediaQuery.of(context).padding.bottom + widget.bottomOffset,
          left: 0,
          right: 0,
          child: notificationContent,
        );
    }
  }
  
  Widget _buildMessageText() {
    return Text(
      widget.message,
      style: TextStyle(
        fontFamily: 'Irina',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: widget.textColor,
      ),
    );
  }
}