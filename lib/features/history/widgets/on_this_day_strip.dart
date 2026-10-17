import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../on_this_day.dart';

/// "On this day" above the user's capsules: the ones made on today's date in
/// earlier years, each with how long ago. Tapping one does what tapping it
/// in the list does.
class OnThisDayStrip extends StatelessWidget {
  const OnThisDayStrip({
    super.key,
    required this.capsules,
    required this.onTap,
    required this.now,
  });

  final List<Capsule> capsules;
  final void Function(Capsule capsule) onTap;
  final DateTime now;

  static const _cardWidth = 104.0;
  static const _photoHeight = 132.0;

  /// The strip's height: the photo and its two lines (14 and 13 sp) at the
  /// phone's text size. A fixed 44 dp for the lines overflowed at 130 %
  /// (D-21; each size scaled on its own, as Android 14+ scales nonlinearly).
  static double heightFor(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    const lineHeight = 1.35;
    return _photoHeight +
        4 +
        (scaler.scale(14) + scaler.scale(13)) * lineHeight +
        6;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.historyOnThisDay,
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: heightFor(context),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: capsules.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final capsule = capsules[i];
                final url = capsule.thumbUrl ?? capsule.imageUrl;
                return AppPressable(
                  child: GestureDetector(
                    onTap: () => onTap(capsule),
                    child: SizedBox(
                      width: _cardWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppRadii.thumbnail,
                            ),
                            child: SizedBox(
                              width: _cardWidth,
                              height: _photoHeight,
                              child: url == null
                                  ? ColoredBox(color: palette.skeleton)
                                  : AppNetworkImage(url: url),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.historyYearsAgo(
                              OnThisDay.yearsAgo(capsule, now),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary,
                            ),
                          ),
                          Text(
                            capsule.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 13,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
