import 'package:flutter/material.dart';

enum NotificationPosition { top, center, bottom }

class OverlayNotification {
  static OverlayEntry? _overlayEntry;

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
    // Handle backward compatibility
    NotificationPosition finalPosition = position;
    if (center) {
      finalPosition = NotificationPosition.center;
    }

    // Remove any existing overlay
    _overlayEntry?.remove();

    // Create an animation controller
    late AnimationController animationController;
    late Animation<double> fadeAnimation;
    late Animation<Offset> slideAnimation;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        animationController = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: Overlay.of(context),
        );

        fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animationController,
          curve: Curves.easeOut,
        ));

        // Define slide animation based on position
        Offset startOffset;
        switch (finalPosition) {
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

        slideAnimation = Tween<Offset>(
          begin: startOffset,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animationController,
          curve: Curves.easeOut,
        ));

        // Start the animation
        animationController.forward();

        return AnimatedBuilder(
          animation: animationController,
          builder: (context, child) {
            Widget notificationWidget = SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
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
                      mainAxisSize: finalPosition == NotificationPosition.center
                          ? MainAxisSize.min
                          : MainAxisSize.max,
                      children: [
                        Icon(
                          icon,
                          color: iconColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        finalPosition == NotificationPosition.center
                            ? Flexible(
                                child: Text(
                                  message,
                                  style: TextStyle(
                                    fontFamily: 'Irina',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              )
                            : Expanded(
                                child: Text(
                                  message,
                                  style: TextStyle(
                                    fontFamily: 'Irina',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            );

            switch (finalPosition) {
              case NotificationPosition.top:
                return Positioned(
                  top: MediaQuery.of(context).padding.top + topOffset,
                  left: 16,
                  right: 16,
                  child: notificationWidget,
                );
              case NotificationPosition.center:
                return Center(child: notificationWidget);
              case NotificationPosition.bottom:
                return Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + bottomOffset,
                  left: 16,
                  right: 16,
                  child: notificationWidget,
                );
            }
          },
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);

    // Auto remove after duration with smooth exit animation
    Future.delayed(duration, () async {
      if (_overlayEntry != null) {
        // Get the animation controller from the overlay
        final overlayState = _overlayEntry!.mounted ? Overlay.of(context) : null;
        if (overlayState != null) {
          // Create exit animations
          final exitController = AnimationController(
            duration: const Duration(milliseconds: 300),
            vsync: overlayState,
          );

          final exitFadeAnimation = Tween<double>(
            begin: 1.0,
            end: 0.0,
          ).animate(CurvedAnimation(
            parent: exitController,
            curve: Curves.easeIn,
          ));

          // Define exit slide animation based on position
          Offset endOffset;
          switch (finalPosition) {
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

          final exitSlideAnimation = Tween<Offset>(
            begin: Offset.zero,
            end: endOffset,
          ).animate(CurvedAnimation(
            parent: exitController,
            curve: Curves.easeIn,
          ));

          // Update the overlay with exit animation
          _overlayEntry?.remove();
          _overlayEntry = OverlayEntry(
            builder: (context) => AnimatedBuilder(
              animation: exitController,
              builder: (context, child) {
                Widget notificationWidget = SlideTransition(
                  position: exitSlideAnimation,
                  child: FadeTransition(
                    opacity: exitFadeAnimation,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: backgroundColor,
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
                          mainAxisSize: finalPosition == NotificationPosition.center
                              ? MainAxisSize.min
                              : MainAxisSize.max,
                          children: [
                            Icon(
                              icon,
                              color: iconColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            finalPosition == NotificationPosition.center
                                ? Flexible(
                                    child: Text(
                                      message,
                                      style: TextStyle(
                                        fontFamily: 'Irina',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  )
                                : Expanded(
                                    child: Text(
                                      message,
                                      style: TextStyle(
                                        fontFamily: 'Irina',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                switch (finalPosition) {
                  case NotificationPosition.top:
                    return Positioned(
                      top: MediaQuery.of(context).padding.top + topOffset,
                      left: 16,
                      right: 16,
                      child: notificationWidget,
                    );
                  case NotificationPosition.center:
                    return Center(child: notificationWidget);
                  case NotificationPosition.bottom:
                    return Positioned(
                      bottom: MediaQuery.of(context).padding.bottom + bottomOffset,
                      left: 16,
                      right: 16,
                      child: notificationWidget,
                    );
                }
              },
            ),
          );

          overlayState.insert(_overlayEntry!);
          
          // Start exit animation
          exitController.forward();
          
          // Remove after animation completes
          await Future.delayed(const Duration(milliseconds: 300));
        }
        
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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