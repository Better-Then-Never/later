import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/router/app_page_route.dart';
import '../../app/session/session_controller.dart';
import '../../core/l10n/app_dates.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/capsule.dart';
import '../../data/services/country_names.dart';
import '../../shared/widgets/app_sheets.dart';
import '../../shared/widgets/pill_v2.dart';
import '../capsules/opening/capsule_wrap.dart';
import '../world/world_page.dart';
import 'guilloche.dart';
import 'ink_stamp.dart';
import 'stamps.dart';

/// The moment a capsule lands in a new town (Figma "Passport / New stamp"
/// 7039:1165, capsule v3 E1): a passport page with the town's stamp in the
/// capsule's pin colour, "New stamp", "Gdańsk, your 22nd town", and Open
/// passport (at its stamps) or Later. The stamp drops from 1.4×
/// and lands with a small wobble (280 ms), its ink darkening as it settles,
/// with one medium haptic.
class NewStampMoment extends StatefulWidget {
  const NewStampMoment({
    super.key,
    required this.town,
    required this.number,
    required this.color,
    required this.countryCode,
    required this.day,
  });

  final String town;

  /// The town's number among the user's towns (22: "your 22nd town").
  final int number;
  final CapsuleColor color;
  final String? countryCode;
  final DateTime day;

  static Future<void> show(
    BuildContext context, {
    required String town,
    required int number,
    required CapsuleColor color,
    String? countryCode,
  }) => showCenteredSheet<void>(
    context,
    NewStampMoment(
      town: town,
      number: number,
      color: color,
      countryCode: countryCode,
      day: DateTime.now(),
    ),
  );

  /// Stamps on a passport page (Figma: seven on page 2); page 1 is the
  /// photo page.
  static const stampsPerPage = 7;

  @override
  State<NewStampMoment> createState() => _NewStampMomentState();
}

class _NewStampMomentState extends State<NewStampMoment>
    with SingleTickerProviderStateMixin {
  late final AnimationController _land = AnimationController(
    vsync: this,
    duration: AppMotion.stampLand,
  );
  String? _country;

  @override
  void initState() {
    super.initState();
    // Lands once the page is up.
    Future<void>.delayed(AppMotion.emphasized, () {
      if (!mounted) return;
      if (AppMotion.reduced(context)) {
        _land.value = 1;
      } else {
        unawaited(
          _land.forward().whenComplete(() => HapticFeedback.mediumImpact()),
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = widget.countryCode;
    if (code == null || _country != null) return;
    final language = context.l10n.localeName;
    unawaited(
      CountryNames().of([code], language).then((names) {
        if (mounted) setState(() => _country = names[code] ?? code);
      }),
    );
  }

  @override
  void dispose() {
    _land.dispose();
    super.dispose();
  }

  void _openPassport() {
    final uid = context.read<SessionController>().uid;
    Navigator.of(context).pop();
    if (uid == null) return;
    final root = Navigator.of(context, rootNavigator: true);
    unawaited(
      root.push(appRoute<void>(WorldPage(uid: uid, focusTown: widget.town))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ink = CapsuleWrap.pinColorOf(widget.color);
    final page = 2 + (widget.number - 1) ~/ NewStampMoment.stampsPerPage;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 280,
        height: 330,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.passportPaper,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: AppColors.passportShadow,
              offset: Offset(0, 6),
              blurRadius: 18,
            ),
          ],
        ),
        child: Stack(
          children: [
            // The security print, faint behind the page.
            const Positioned(
              left: -10,
              top: 15,
              width: 300,
              height: 300,
              child: Opacity(
                opacity: 0.12,
                child: CustomPaint(painter: GuillochePainter()),
              ),
            ),
            // The spine's shade.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.mediaBlack.withValues(alpha: 0.22),
                      AppColors.mediaBlack.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 14,
              child: Text(
                l10n.stampsPageLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 9,
                  height: 1.1,
                  letterSpacing: 0.72,
                  color: AppColors.passportInk,
                ),
              ),
            ),
            Positioned(
              left: 254,
              top: 304,
              child: Text(
                '$page',
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 13,
                  height: 1.25,
                  color: AppColors.passportInk,
                ),
              ),
            ),
            Positioned(
              left: 38.22,
              top: 60,
              width: 186.9,
              height: 136.35,
              child: AnimatedBuilder(
                animation: _land,
                builder: (context, child) {
                  final t = _land.value;
                  // From 1.4× to a touch under, then settling (the wobble).
                  final scale = t < 0.7
                      ? 1.4 - 0.44 * Curves.easeIn.transform(t / 0.7)
                      : 0.96 +
                            0.04 *
                                Curves.easeOut.transform(
                                  ((t - 0.7) / 0.3).clamp(0.0, 1.0),
                                );
                  final wobble = math.sin(t * math.pi * 2) * (1 - t) * 0.05;
                  return Opacity(
                    // Hidden until it drops; the ink darkens as it lands.
                    opacity: t == 0 ? 0 : 0.55 + 0.35 * t,
                    child: Transform.rotate(
                      angle: 8 * math.pi / 180 + wobble,
                      child: Transform.scale(scale: scale, child: child),
                    ),
                  );
                },
                child: Center(
                  child: InkStamp(
                    ink: ink,
                    top: widget.town.toUpperCase(),
                    middle: AppDates.medium(
                      widget.day,
                      l10n.localeName,
                    ).toUpperCase(),
                    bottom: (_country ?? '').toUpperCase(),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 214,
              child: Column(
                children: [
                  Text(
                    l10n.stampsNew,
                    style: AppTextStyles.sectionTitle.copyWith(
                      height: 1.2,
                      color: AppColors.passportText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.stampsTownNumber(
                      widget.town,
                      Stamps.ordinal(widget.number, l10n.localeName),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 13,
                      height: 1.25,
                      color: AppColors.passportInk,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Long words or a large text size: smaller, never cut.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PillV2(
                            label: l10n.stampsOpenPassport,
                            size: PillV2Size.small,
                            onTap: _openPassport,
                          ),
                          const SizedBox(width: 10),
                          PillV2(
                            label: l10n.stampsLater,
                            kind: PillV2Kind.outline,
                            size: PillV2Size.small,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
