import 'package:flutter/material.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:provider/provider.dart';
import '../../features/messages/chats_store.dart';
import '../../shared/widgets/count_badge.dart';
import '../../core/theme/app_motion.dart';
import '../../shared/motion/app_motion_widgets.dart';
import 'package:later/app/router/app_routes.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:later/core/theme/app_dimens.dart';
import 'package:later/core/theme/app_palette.dart';

/// Tab pictures (F-34: they were 46 dp in an 80 dp bar).
const double navbarIconHeight = 40.0;

class NavbarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  const NavbarWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  /// The tabs' pictures, decoded before the first frame of home
  /// ([AuthGate]): the bar and its icons appear in the same frame.
  static const icons = [
    AppIcons.navbarMap,
    AppIcons.navbarHistory,
    AppIcons.navbarAdd,
    AppIcons.navbarMessages,
    AppIcons.navbarProfile,
  ];

  /// The pill's height (was 80, F-34).
  static const double barHeight = 68;

  /// Each tab's slot: fixed, so a tab growing when selected never pushes
  /// its neighbours (they shifted a few dp at every switch), and a 48 dp
  /// tap target.
  static const double _slot = 48;

  /// How much of the bottom of the screen the floating bar covers, system
  /// navigation included (the map keeps its logo and controls above it).
  static double coveredHeight(BuildContext context) {
    final media = MediaQuery.of(context);
    return barHeight + media.size.height * 0.01 + media.viewPadding.bottom;
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.01),
      child: Container(
        height: barHeight,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(30),
          border: context.palette.isDark
              ? Border.all(color: context.palette.cardBorder)
              : null,
          boxShadow: AppShadows.raised(context),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildIcon(context, 0, AppIcons.navbarMap, l10n.navMap),
            _buildIcon(context, 1, AppIcons.navbarHistory, l10n.navMyCapsules),
            _buildAddIcon(context, AppIcons.navbarAdd),
            Stack(
              clipBehavior: Clip.none,
              children: [
                _buildIcon(
                  context,
                  2,
                  AppIcons.navbarMessages,
                  l10n.navMessages,
                ),
                const Positioned(top: -4, right: -6, child: _UnreadMessages()),
              ],
            ),
            _buildIcon(context, 3, AppIcons.navbarProfile, l10n.navProfile),
          ],
        ),
      ),
    );
  }

  /// [label] is what screen readers say (F-34: the tabs had no names).
  Widget _buildIcon(
    BuildContext context,
    int index,
    String assetPath,
    String label,
  ) {
    final isSelected = index == selectedIndex;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: AppPressable(
        child: GestureDetector(
          onTap: () => onItemTapped(index),
          behavior: HitTestBehavior.opaque,
          child: SizedBox.square(
            dimension: _slot,
            child: Center(
              child: AnimatedScale(
                scale: isSelected ? 1.25 : 1.0,
                duration: AppMotion.of(context, AppMotion.standard),
                curve: AppMotion.emphasizedCurve,
                child: Image.asset(
                  assetPath,
                  width: navbarIconHeight,
                  height: navbarIconHeight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddIcon(BuildContext context, String assetPath) {
    return Semantics(
      button: true,
      label: context.l10n.navNewCapsule,
      excludeSemantics: true,
      child: AppPressable(
        child: GestureDetector(
          onTap: () => AppRoutes.toCamera(context),
          child: Image.asset(assetPath, height: navbarIconHeight * 1.5),
        ),
      ),
    );
  }
}

/// Unread messages over all chats that are not muted.
class _UnreadMessages extends StatelessWidget {
  const _UnreadMessages();

  @override
  Widget build(BuildContext context) {
    final count = context.select<ChatsStore, int>((s) => s.totalUnread);
    return IgnorePointer(child: CountBadge(count: count, size: 18));
  }
}
