import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_page_route.dart';
import '../../../app/session/session_controller.dart';
import '../../../app/shell/selected_page.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/v2/card_v2.dart';
import '../../history/own_capsules_store.dart';
import '../../world/world_page.dart';

/// Places on the profile (Profile v4, Figma 7182:4354): a small map with
/// the pins of the user's latest capsules (a tap opens the map) and the
/// Passport row (countries and towns; a tap opens the Passport).
class ProfilePlacesCard extends StatelessWidget {
  const ProfilePlacesCard({super.key});

  /// The pins drawn on the small map, newest first.
  static const maxPins = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = context.read<SessionController>();
    final (countries, towns) = context.select<SessionController, (int, int)>(
      (s) => (s.profile?.stats.countries ?? 0, s.profile?.stats.cities ?? 0),
    );
    final colours = context.select<OwnCapsulesStore, List<String>>(
      (s) => [for (final c in s.capsules.take(maxPins)) c.color.name],
    );
    return CardV2(
      child: Column(
        children: [
          Semantics(
            button: true,
            label: l10n.profileOpenMap,
            child: GestureDetector(
              onTap: () => selectedPageNotifier.value = AppTabs.map,
              child: SizedBox(
                height: 104,
                width: double.infinity,
                child: _MiniMap(colours: colours),
              ),
            ),
          ),
          RowV2(
            iconPath: AppIcons.capsuleLocation,
            title: l10n.worldTitle,
            subtitle: countries == 0
                ? l10n.profileStampsHint
                : l10n.profileCountriesTowns(
                    l10n.profileCountries(countries),
                    l10n.profileTowns(towns),
                  ),
            onTap: () {
              final uid = session.uid;
              if (uid == null) return;
              Navigator.of(context).push(appRoute<void>(WorldPage(uid: uid)));
            },
          ),
        ],
      ),
    );
  }
}

/// A drawn map: ground, a few streets, a park, and the pins.
class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.colours});

  final List<String> colours;

  /// Where the pins stand, as fractions of the map (from the design).
  static const _spots = [
    Offset(0.16, 0.38),
    Offset(0.41, 0.63),
    Offset(0.56, 0.24),
    Offset(0.76, 0.71),
    Offset(0.93, 0.31),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return LayoutBuilder(
      builder: (context, c) => Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _StreetsPainter(
                ground: palette.isDark
                    ? AppColors.mapGroundDark
                    : AppColors.mapGroundLight,
                street: palette.surface,
              ),
            ),
          ),
          for (final (i, colour) in colours.indexed)
            Positioned(
              left: _spots[i].dx * c.maxWidth - 14,
              top: _spots[i].dy * c.maxHeight - 14,
              child: Image.asset(
                AppIcons.mapPin(colour),
                width: 28,
                height: 28,
              ),
            ),
        ],
      ),
    );
  }
}

class _StreetsPainter extends CustomPainter {
  _StreetsPainter({required this.ground, required this.street});

  final Color ground;
  final Color street;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    final park = Paint()..color = AppColors.brandGreen.withValues(alpha: 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.64, h * 0.42, w * 0.21, h * 0.38),
        const Radius.circular(12),
      ),
      park,
    );
    final road = Paint()..color = street;
    canvas
      ..drawRect(Rect.fromLTWH(0, h * 0.33, w, 7), road)
      ..drawRect(Rect.fromLTWH(0, h * 0.81, w, 9), road)
      ..drawRect(Rect.fromLTWH(w * 0.21, 0, 7, h), road)
      ..drawRect(Rect.fromLTWH(w * 0.6, 0, 9, h), road)
      ..drawRect(Rect.fromLTWH(w * 0.82, 0, 6, h), road);
  }

  @override
  bool shouldRepaint(_StreetsPainter old) =>
      old.ground != ground || old.street != street;
}
