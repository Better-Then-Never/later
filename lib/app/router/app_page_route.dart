import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// The app's page transition: a short fade (AppMotion.fast), used for every
/// push so all screens move the same way. Instant when motion is reduced.
Route<T> fadeRoute<T>(Widget page, {RouteSettings? settings}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: AppMotion.fast,
    reverseTransitionDuration: AppMotion.fast,
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (context, animation, _, child) {
      if (AppMotion.reduced(context)) return child;
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: AppMotion.enter,
          reverseCurve: AppMotion.exit,
        ),
        child: child,
      );
    },
  );
}

/// Bottom-to-top slide for pages that open like a sheet ("Add friends"),
/// with the same timing as [fadeRoute].
Route<T> slideUpRoute<T>(Widget page, {RouteSettings? settings}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: AppMotion.fast,
    reverseTransitionDuration: AppMotion.fast,
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (context, animation, _, child) {
      if (AppMotion.reduced(context)) return child;
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: animation,
                curve: AppMotion.enter,
                reverseCurve: AppMotion.exit,
              ),
            ),
        child: child,
      );
    },
  );
}
