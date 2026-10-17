import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_page_route.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/session/session_controller.dart';
import '../../../app/shell/selected_page.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/styles/box_decorations.dart';
import '../../history/own_capsules_store.dart';
import '../../world/world_page.dart';

/// What the user's capsules add up to: how many, in how many places, how
/// many made with friends (a tap opens My capsules); and a new capsule for
/// friends or for everyone.
class ProfileCapsulesCard extends StatelessWidget {
  const ProfileCapsulesCard({super.key});

  /// (capsules, places, made with friends) of [uid] in [capsules]. Places
  /// are cells of about 5 km, as for the Explorer achievement.
  static (int, int, int) countsFor(List<Capsule> capsules, String? uid) {
    var own = 0;
    var together = 0;
    final places = <String>{};
    for (final c in capsules) {
      final mine = c.ownerId == uid;
      if (mine) {
        own++;
        final at = c.location;
        if (at != null) {
          places.add(
            '${(at.latitude * 20).round()}:${(at.longitude * 20).round()}',
          );
        }
      }
      if (c.coAuthors.isNotEmpty) together++;
    }
    return (own, places.length, together);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final uid = context.read<SessionController>().uid;
    final (own, places, together) = context
        .select<OwnCapsulesStore, (int, int, int)>(
          (s) => countsFor(s.capsules, uid),
        );
    return Container(
      width: double.infinity,
      decoration: BoxDecorations.whiteCard(context),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        children: [
          Semantics(
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => selectedPageNotifier.value = AppTabs.history,
              child: Row(
                children: [
                  _Stat(value: own, label: l10n.profileStatCapsules(own)),
                  _Stat(value: places, label: l10n.profileStatPlaces(places)),
                  _Stat(value: together, label: l10n.profileStatTogether),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const _PassportRow(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NewButton(
                  text: l10n.profileNewForFriends,
                  onTap: () => AppRoutes.toCamera(
                    context,
                    privacy: CapsulePrivacy.friends,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NewButton(
                  text: l10n.profileNewForEveryone,
                  onTap: () => AppRoutes.toCamera(
                    context,
                    privacy: CapsulePrivacy.public,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "🌍 Passport · 3 countries · 7 towns ›": opens the world view (B7).
class _PassportRow extends StatelessWidget {
  const _PassportRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final session = context.read<SessionController>();
    final (countries, towns) = context.select<SessionController, (int, int)>(
      (s) => (s.profile?.stats.countries ?? 0, s.profile?.stats.cities ?? 0),
    );
    final detail = countries == 0
        ? ''
        : '$countries ${l10n.worldCountriesLabel(countries)} · '
              '$towns ${l10n.worldTownsLabel(towns)}';
    return Semantics(
      button: true,
      label: detail.isEmpty ? l10n.worldTitle : '${l10n.worldTitle}: $detail',
      excludeSemantics: true,
      child: AppPressable(
        child: GestureDetector(
          onTap: () {
            final uid = session.uid;
            if (uid == null) return;
            Navigator.of(context).push(appRoute<void>(WorldPage(uid: uid)));
          },
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecorations.greyCard(context, borderRadius: 22),
            child: Row(
              children: [
                const Text('🌍', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  l10n.worldTitle,
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '›',
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 20,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "+ For friends": a light green pill (the camera opens with that
/// visibility chosen).
class _NewButton extends StatelessWidget {
  const _NewButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${context.l10n.profileNewCapsule}: $text',
      child: AppPressable(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brandGreen,
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CustomPaint(
                    size: Size.square(14),
                    painter: _PlusPainter(),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The plus of the new-capsule buttons, in the icons' rounded stroke.
class _PlusPainter extends CustomPainter {
  const _PlusPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onAccent
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final c = size.center(Offset.zero);
    canvas
      ..drawLine(Offset(c.dx, 1), Offset(c.dx, size.height - 1), paint)
      ..drawLine(Offset(1, c.dy), Offset(size.width - 1, c.dy), paint);
  }

  @override
  bool shouldRepaint(_PlusPainter old) => false;
}
