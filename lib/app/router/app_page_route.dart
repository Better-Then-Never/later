import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';

/// The app's standard transition: a 10 ms fade (visually an instant swap),
/// identical to the `PageTransitionType.fade` routes it replaces.
Route<T> fadeRoute<T>(Widget page, {RouteSettings? settings}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: AppDurations.pageFade,
    reverseTransitionDuration: AppDurations.pageFade,
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// Bottom-to-top slide (100 ms), used for the "Add friends" entry point.
Route<T> slideUpRoute<T>(Widget page, {RouteSettings? settings}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: AppDurations.pageSlideUp,
    reverseTransitionDuration: AppDurations.pageSlideUp,
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    ),
  );
}
