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

const double navbarIconHeight = 46.0;

class NavbarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  const NavbarWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  static const double barHeight = 80;

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
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.standard),
            curve: AppMotion.standardCurve,
            height: navbarIconHeight * (isSelected ? 1.2 : 1.0),
            width: navbarIconHeight * (isSelected ? 1.2 : 1.0),
            child: AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: AppMotion.of(context, AppMotion.quick),
              curve: AppMotion.standardCurve,
              child: Image.asset(assetPath),
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
