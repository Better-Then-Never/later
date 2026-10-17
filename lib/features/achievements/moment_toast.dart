import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/router/app_page_route.dart';
import '../../app/router/app_routes.dart';
import '../../app/session/session_controller.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/motion/reaction_burst.dart';
import '../../shared/styles/box_decorations.dart';
import 'achievement_icon.dart';
import 'achievements_view.dart';
import 'moments.dart';
import 'streak_flame.dart';

/// Shows [Moment]s one at a time at the top of the screen (B7, Part A's
/// "unlock animation and toast" and "milestone celebration"): a card drops
/// in from above, then the badge (or the flame) pops in a burst of dots. It
/// leaves after [stay], on a swipe up, or opens the achievements on a tap.
/// Reduced motion: it appears and leaves without moving.
abstract final class MomentToast {
  static const stay = Duration(seconds: 4);

  static final _queue = Queue<Moment>();
  static OverlayEntry? _entry;
  static int _waits = 0;

  /// Where the card goes; the root navigator's overlay by default.
  @visibleForTesting
  static OverlayState? Function() overlay = () =>
      AppRoutes.navigatorKey.currentState?.overlay;

  static void show(Moment moment) {
    _queue.add(moment);
    if (_entry == null) _next();
  }

  static void _next() {
    if (_queue.isEmpty) return;
    final target = overlay();
    if (target == null) {
      // Nothing on screen yet (starting): try again shortly, for a while.
      if (_waits++ < 20) {
        Timer(const Duration(milliseconds: 500), _next);
      } else {
        _queue.clear();
      }
      return;
    }
    _waits = 0;
    final moment = _queue.removeFirst();
    HapticFeedback.lightImpact();
    final entry = OverlayEntry(
      builder: (_) => MomentCard(moment: moment, onDone: _done),
    );
    _entry = entry;
    target.insert(entry);
  }

  static void _done() {
    _entry?.remove();
    _entry = null;
    _next();
  }

  @visibleForTesting
  static void reset() {
    _entry?.remove();
    _entry = null;
    _queue.clear();
    _waits = 0;
  }
}

/// The card of one [Moment] (see [MomentToast]).
class MomentCard extends StatefulWidget {
  const MomentCard({super.key, required this.moment, required this.onDone});

  final Moment moment;
  final VoidCallback onDone;

  @override
  State<MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends State<MomentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drop;
  Timer? _timer;
  bool _popped = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _drop = AnimationController(vsync: this, duration: AppMotion.emphasized);
    _timer = Timer(MomentToast.stay, _leave);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_drop.isAnimating || _drop.value > 0) return;
    if (AppMotion.reduced(context)) {
      _drop.value = 1;
      return;
    }
    // The badge pops once the card is down.
    _drop.forward().whenComplete(() {
      if (mounted && !_leaving) setState(() => _popped = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _drop.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_leaving || !mounted) return;
    _leaving = true;
    _timer?.cancel();
    if (!AppMotion.reduced(context)) await _drop.reverse();
    widget.onDone();
  }

  void _open() {
    final profile = context.read<SessionController>().profile;
    unawaited(_leave());
    final navigator = AppRoutes.navigatorKey.currentState;
    if (profile == null || navigator == null) return;
    unawaited(
      navigator.push(appRoute<void>(AchievementsPage(profile: profile))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final (
      Widget badge,
      Color accent,
      String label,
      String title,
      String body,
    ) = switch (widget.moment) {
      AchievementMoment(:final def, :final tier, :final more) => (
        AchievementIcon(
          id: def.id,
          icon: def.icon,
          tier: tier,
          tiers: def.tiers.length,
          size: 52,
        ),
        AppColors.brandGreen,
        l10n.momentsAchievementLabel,
        def.title(l10n),
        [
          def.tiers.length > 1
              ? l10n.achievementsTier(tier + 1, def.tiers.length)
              : def.goal(l10n, def.tiers[tier]),
          if (more > 0) l10n.momentsAchievementMore(more),
        ].join(' · '),
      ),
      StreakMoment(:final days) => (
        SizedBox(
          width: 52,
          height: 52,
          child: Center(child: StreakFlame(key: ValueKey(_popped), size: 34)),
        ),
        AppColors.warningOrange,
        l10n.momentsStreakLabel,
        l10n.achievementsStreakDays(days),
        l10n.momentsStreakBody,
      ),
    };
    return Positioned(
      top: MediaQuery.viewPaddingOf(context).top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, -1.6),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _drop, curve: AppMotion.enter)),
        child: Semantics(
          liveRegion: true,
          button: true,
          child: GestureDetector(
            onTap: _open,
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) < -100) unawaited(_leave());
            },
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                decoration: BoxDecorations.whiteCard(context, borderRadius: 25),
                child: Row(
                  children: [
                    ReactionBurst(active: _popped, color: accent, child: badge),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                          ),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary,
                            ),
                          ),
                          Text(
                            body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 13,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
