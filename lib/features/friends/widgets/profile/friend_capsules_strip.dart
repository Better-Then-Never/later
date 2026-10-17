import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/shell/selected_page.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/capsule.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../shared/motion/app_motion_widgets.dart';
import '../../../../shared/styles/box_decorations.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../capsules/social/capsule_detail_dialog.dart';
import '../../../map/map_focus.dart';

/// A friend's public and friends-only capsules, newest first (F-54: the
/// section used to be a fixed placeholder). Open ones open in place; locked
/// ones are shown on the map with their countdown.
class FriendCapsulesStrip extends StatefulWidget {
  const FriendCapsulesStrip({super.key, required this.friendUid});

  final String friendUid;

  @override
  State<FriendCapsulesStrip> createState() => _FriendCapsulesStripState();
}

class _FriendCapsulesStripState extends State<FriendCapsulesStrip> {
  late final Future<List<Capsule>> _capsules = context
      .read<CapsuleRepository>()
      .sharedBy(widget.friendUid)
      .catchError((Object _) => const <Capsule>[]);

  static const _cardWidth = 112.0;
  static const _height = 150.0;

  void _open(Capsule capsule) {
    if (capsule.isOpen(DateTime.now())) {
      CapsuleDetailDialog.show(context, capsule);
      return;
    }
    if (capsule.location == null) return;
    context.read<MapFocus>().focus(capsule);
    AppRoutes.backToRoot();
    selectedPageNotifier.value = AppTabs.map;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return FutureBuilder<List<Capsule>>(
      future: _capsules,
      builder: (context, snap) {
        if (!snap.hasData) {
          return SizedBox(
            height: _height,
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: _cardWidth,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: palette.skeleton,
                      borderRadius: BorderRadius.circular(AppRadii.thumbnail),
                    ),
                  ),
              ],
            ),
          );
        }
        final capsules = snap.data!;
        if (capsules.isEmpty) {
          return Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecorations.whiteCard(context),
            alignment: Alignment.center,
            child: Text(
              context.l10n.friendsFriendCapsulesEmpty,
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                color: palette.textMuted,
              ),
            ),
          );
        }
        return SizedBox(
          height: _height + 24,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: capsules.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _Card(
              capsule: capsules[i],
              width: _cardWidth,
              height: _height,
              onTap: () => _open(capsules[i]),
            ),
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.capsule,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final Capsule capsule;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locked = !capsule.isOpen(DateTime.now());
    final url = capsule.thumbUrl ?? capsule.imageUrl;
    return AppPressable(
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.thumbnail),
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (url != null)
                        AppNetworkImage(url: url)
                      else
                        ColoredBox(color: palette.skeleton),
                      if (locked)
                        const ColoredBox(
                          color: AppColors.mediaScrim,
                          child: Icon(
                            Icons.lock_clock,
                            color: AppColors.onMedia,
                            size: 32,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                capsule.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
