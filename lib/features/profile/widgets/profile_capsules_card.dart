import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/session/session_controller.dart';
import '../../../app/shell/selected_page.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../history/own_capsules_store.dart';
import '../../../core/assets/app_assets.dart';
import '../../../shared/widgets/pill_v2.dart';
import '../../../shared/widgets/v2/card_v2.dart';

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
    final palette = context.palette;
    final uid = context.read<SessionController>().uid;
    final (own, places, together) = context
        .select<OwnCapsulesStore, (int, int, int)>(
          (s) => countsFor(s.capsules, uid),
        );
    // Profile v4 (Figma 7182:4354): the History icon, "102 capsules" with an
    // arrow to My capsules, where and with whom, and two new-capsule pills.
    return CardV2(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Image.asset(AppIcons.navbarHistory, width: 28, height: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => selectedPageNotifier.value = AppTabs.history,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            own == 0
                                ? l10n.profileNoCapsules
                                : l10n.profileCapsulesCount(own),
                            style: AppTextStyles.body.copyWith(
                              fontSize: 16,
                              height: 1.25,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        if (own > 0) Image.asset(AppIcons.goHere, width: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  own == 0
                      ? l10n.profileNoCapsulesHint
                      : l10n.profileCapsulesLine(places, together),
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    height: 1.25,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Semantics(
                      label:
                          '${l10n.profileNewCapsule}: ${l10n.profileNewForFriends}',
                      excludeSemantics: true,
                      child: PillV2(
                        label: '+  ${l10n.profileNewForFriends}',
                        kind: own == 0 ? PillV2Kind.solid : PillV2Kind.soft,
                        size: PillV2Size.small,
                        onTap: () => AppRoutes.toCamera(
                          context,
                          privacy: CapsulePrivacy.friends,
                        ),
                      ),
                    ),
                    Semantics(
                      label:
                          '${l10n.profileNewCapsule}: ${l10n.profileNewForEveryone}',
                      excludeSemantics: true,
                      child: PillV2(
                        label: '+  ${l10n.profileNewForEveryone}',
                        kind: own == 0 ? PillV2Kind.solid : PillV2Kind.soft,
                        size: PillV2Size.small,
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
          ),
        ],
      ),
    );
  }
}
