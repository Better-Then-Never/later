import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../../../shared/widgets/default_text.dart';
import '../../../shared/widgets/options/options_section.dart';
import '../../../shared/widgets/options/options_settings_row.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../settings/app_info.dart';
import '../map_credits.dart';

/// The map's credit (docs/map/ATTRIBUTION.md), bottom left: an (i) button
/// in the style of the map's other controls, opening the credits sheet,
/// and a tiny credit line next to it, always or for the first seconds of a
/// session ([FeatureFlags.mapCreditCollapses]). Replaces MapLibre's own
/// button.
class MapCreditsControl extends StatefulWidget {
  const MapCreditsControl({super.key, required this.maxWidth});

  /// The room it has (the line never runs under the buttons on the right).
  final double maxWidth;

  @override
  State<MapCreditsControl> createState() => _MapCreditsControlState();
}

class _MapCreditsControlState extends State<MapCreditsControl> {
  final _credits = MapCredits.load();

  /// The line collapsed this session (only when it collapses).
  static bool _collapsed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (FeatureFlags.mapCreditCollapses && !_collapsed) {
      _timer = Timer(const Duration(seconds: 5), () {
        _collapsed = true;
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final showLine = !FeatureFlags.mapCreditCollapses || !_collapsed;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MapCreditsButton(onTap: () => showMapCredits(context)),
          Flexible(
            child: AnimatedOpacity(
              opacity: showLine ? 1 : 0,
              duration: AppMotion.of(context, AppMotion.slow),
              child: FutureBuilder<List<MapCredit>>(
                future: _credits,
                builder: (context, snapshot) {
                  final credits = snapshot.data ?? const [];
                  if (credits.isEmpty) return const SizedBox.shrink();
                  // Excluded: the button says the same to a screen reader.
                  return ExcludeSemantics(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        MapCredits.line(credits),
                        maxLines: 1,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 10,
                          height: 1.2,
                          color: palette.textSecondary,
                          shadows: [
                            Shadow(color: palette.background, blurRadius: 3),
                            Shadow(color: palette.background, blurRadius: 1),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The (i) of the map's credit: a small disc in the style of the map's
/// controls (surface, border in dark, raised shadow), its glyph painted like
/// the zoom buttons' signs; a 44 dp tap target.
class MapCreditsButton extends StatelessWidget {
  const MapCreditsButton({super.key, required this.onTap});

  final VoidCallback onTap;

  /// The visible disc (the tap target is [AppSizes.mapControl]).
  static const disc = 26.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: context.l10n.mapCreditsButton,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: AppSizes.mapControl,
          child: Center(
            child: Container(
              width: disc,
              height: disc,
              decoration: BoxDecoration(
                color: palette.surface,
                shape: BoxShape.circle,
                border: palette.isDark
                    ? Border.all(color: palette.cardBorder)
                    : null,
                boxShadow: AppShadows.raised(context),
              ),
              child: CustomPaint(painter: _InfoPainter(palette.icon)),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPainter extends CustomPainter {
  const _InfoPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final c = size.center(Offset.zero);
    final unit = size.shortestSide;
    canvas
      ..drawCircle(c - Offset(0, unit * 0.2), unit * 0.065, paint)
      ..drawLine(c - Offset(0, unit * 0.04), c + Offset(0, unit * 0.22), paint);
  }

  @override
  bool shouldRepaint(_InfoPainter old) => old.color != color;
}

/// The credits sheet: each source with its link, OpenStreetMap's "improve
/// this map", and the library that draws the map. Also opened from
/// Settings > About.
Future<void> showMapCredits(BuildContext context) => showEdgeSheet<void>(
  context,
  (context) => EdgeSheet(
    height: MediaQuery.sizeOf(context).height * 0.6,
    child: const _MapCreditsSheet(),
  ),
);

class _MapCreditsSheet extends StatelessWidget {
  const _MapCreditsSheet();

  Future<void> _open(BuildContext context, String url) async {
    if (await AppInfo.openUrl(url) || !context.mounted) return;
    PopupNotificationService.showError(
      context: context,
      message: context.l10n.settingsAboutOpenFailed,
      position: NotificationPosition.bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<List<MapCredit>>(
      future: MapCredits.load(),
      builder: (context, snapshot) {
        final credits = snapshot.data ?? const <MapCredit>[];
        Widget link(String text, String? url, {bool last = false}) =>
            OptionsSettingsRow(
              title: text,
              withDivider: !last,
              onTap: url == null ? null : () => _open(context, url),
            );
        return ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: Text(
                l10n.mapCreditsTitle,
                style: AppTextStyles.pageTitle(context).copyWith(fontSize: 20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: DefaultText(
                l10n.mapCreditsDescription,
                textAlign: TextAlign.left,
              ),
            ),
            OptionsSection(
              children: [
                for (var i = 0; i < credits.length; i++)
                  link(credits[i].text, credits[i].url),
                link(l10n.mapCreditsImprove, MapCredits.improveUrl),
                link(
                  l10n.mapCreditsRenderer,
                  MapCredits.rendererUrl,
                  last: true,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
