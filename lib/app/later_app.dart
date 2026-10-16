import 'package:flutter/material.dart';
import 'package:snow_fall_animation/snow_fall_animation.dart';

import '../core/theme/app_theme.dart';
import 'router/app_routes.dart';
import 'session/auth_gate.dart';

/// Snow falls from December 31st through the end of February.
bool isSnowSeason(DateTime now) =>
    (now.month == 12 && now.day >= 31) || now.month == 1 || now.month == 2;

class LaterApp extends StatelessWidget {
  const LaterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final snow = isSnowSeason(DateTime.now());
    return MaterialApp(
      navigatorKey: AppRoutes.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Seasonal snowfall drawn over every screen (part of the design).
      builder: (context, child) => Stack(
        children: [
          child ?? const SizedBox(),
          if (snow)
            const IgnorePointer(
              child: SnowFallAnimation(
                config: SnowfallConfig(
                  numberOfSnowflakes: 15,
                  speed: 0.5,
                  useEmoji: true,
                  customEmojis: ['❄️', '❅', '❆'],
                ),
              ),
            ),
        ],
      ),
      home: const AuthGate(),
    );
  }
}
