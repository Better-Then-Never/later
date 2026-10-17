import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/world.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/country_names.dart';
import '../../shared/motion/app_motion_widgets.dart';
import '../../shared/motion/idle_float.dart';
import '../../shared/styles/box_decorations.dart';
import '../../shared/widgets/buttons/go_back_button.dart';
import '../../shared/widgets/page_header.dart';

/// The world view (B7): a passport of the countries and towns where [uid]
/// left capsules, one stamp per country. One read (the summary the
/// functions keep); country names come from the phone in the app's language.
class WorldPage extends StatelessWidget {
  const WorldPage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.backgroundAlt,
      body: Column(
        children: [
          PageHeader(
            mainText: l10n.worldTitle,
            description: l10n.worldDescription,
            leadingButton: GoBackButton(context: context),
          ),
          Expanded(
            child: StreamBuilder<WorldSummary>(
              stream: context.read<SocialRepository>().watchWorld(uid),
              builder: (context, snap) {
                final world = snap.data;
                if (world == null) return const SizedBox.shrink();
                return _Passport(world: world);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Passport extends StatefulWidget {
  const _Passport({required this.world});

  final WorldSummary world;

  @override
  State<_Passport> createState() => _PassportState();
}

class _PassportState extends State<_Passport> {
  Map<String, String> _names = const {};
  String? _asked;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _askNames();
  }

  @override
  void didUpdateWidget(_Passport old) {
    super.didUpdateWidget(old);
    _askNames();
  }

  void _askNames() {
    final language = context.l10n.localeName;
    final codes = [for (final c in widget.world.countries) c.code];
    final key = '$language:${codes.join(',')}';
    if (key == _asked) return;
    _asked = key;
    context.read<CountryNames>().of(codes, language).then((names) {
      if (mounted && _asked == key) setState(() => _names = names);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final world = widget.world;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecorations.whiteCard(context),
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  _Total(
                    value: world.countryCount,
                    label: l10n.worldCountriesLabel(world.countryCount),
                  ),
                  _Total(
                    value: world.cityCount,
                    label: l10n.worldTownsLabel(world.cityCount),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (world.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const IdleFloat(
                    child: Text('🌍', style: TextStyle(fontSize: 56)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.worldEmpty,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 15,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: world.countries.length,
              itemBuilder: (context, i) {
                final visit = world.countries[i];
                return AppStaggerItem(
                  key: ValueKey(visit.code),
                  index: i,
                  child: Stamp(
                    visit: visit,
                    name: _names[visit.code] ?? visit.code,
                    index: i,
                  ),
                );
              },
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
          sliver: SliverToBoxAdapter(
            child: Text(
              l10n.worldNote,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                color: palette.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// One country's stamp: paper with a perforated edge and an inked frame,
/// the flag, the name, the capsules and towns, the first visit. Each stamp
/// leans a little, as if pressed by hand (a fixed tilt, never animated).
class Stamp extends StatelessWidget {
  const Stamp({
    super.key,
    required this.visit,
    required this.name,
    required this.index,
  });

  final CountryVisit visit;
  final String name;
  final int index;

  /// Inks from the app's accents (yellow is too light on paper).
  static const _inks = [
    AppColors.brandGreen,
    AppColors.infoBlue,
    AppColors.warningOrange,
    AppColors.danger,
  ];
  static const _tilts = [-0.035, 0.025, -0.015, 0.03];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final ink = _inks[index % _inks.length];
    final towns = visit.towns;
    final shown = towns.take(2).join(', ');
    final more = towns.length - 2;
    final first = visit.first;
    final small = AppTextStyles.body.copyWith(
      fontSize: 12,
      color: palette.textSecondary,
    );
    return Semantics(
      label: [
        name,
        l10n.worldCapsules(visit.capsules),
        if (towns.isNotEmpty) towns.join(', '),
      ].join('. '),
      excludeSemantics: true,
      child: Transform.rotate(
        angle: _tilts[index % _tilts.length],
        child: CustomPaint(
          painter: _StampPainter(
            paper: palette.surface,
            hole: palette.backgroundAlt,
            ink: ink,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  CountryNames.flag(visit.code),
                  style: const TextStyle(fontSize: 30),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(l10n.worldCapsules(visit.capsules), style: small),
                if (towns.isNotEmpty)
                  Text(
                    more > 0 ? '$shown +$more' : shown,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: small,
                  ),
                if (first != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.worldFirst(
                      DateFormat.yMMM(l10n.localeName).format(first),
                    ),
                    style: AppTextStyles.body.copyWith(
                      fontSize: 11,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paper, holes punched along the edge in the page colour, and an inked
/// frame inside. Static: painted once per size.
class _StampPainter extends CustomPainter {
  const _StampPainter({
    required this.paper,
    required this.hole,
    required this.ink,
  });

  final Color paper;
  final Color hole;
  final Color ink;

  static const _radius = 4.0;
  static const _gap = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = paper);
    final holes = Paint()..color = hole;
    void edge(Offset from, Offset to) {
      final length = (to - from).distance;
      final count = math.max(1, (length / _gap).floor());
      for (var i = 0; i <= count; i++) {
        canvas.drawCircle(Offset.lerp(from, to, i / count)!, _radius, holes);
      }
    }

    edge(rect.topLeft, rect.topRight);
    edge(rect.bottomLeft, rect.bottomRight);
    edge(rect.topLeft, rect.bottomLeft);
    edge(rect.topRight, rect.bottomRight);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(9), const Radius.circular(6)),
      Paint()
        ..color = ink.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_StampPainter old) =>
      old.paper != paper || old.hole != hole || old.ink != ink;
}
