import 'package:flutter/material.dart';
import '../../core/theme/app_motion.dart';
import '../../shared/motion/app_motion_widgets.dart';
import 'package:later/app/router/app_routes.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:later/core/theme/app_colors.dart';

const double navbarIconHeight = 46.0;

class NavbarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  const NavbarWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.01),
      child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowRaised,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildIcon(context, 0, AppIcons.navbarMap),
            _buildIcon(context, 1, AppIcons.navbarHistory),
            _buildAddIcon(context, AppIcons.navbarAdd),
            _buildIcon(context, 2, AppIcons.navbarMessages),
            _buildIcon(context, 3, AppIcons.navbarProfile),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, int index, String assetPath) {
    final isSelected = index == selectedIndex;

    return AppPressable(
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
    );
  }

  Widget _buildAddIcon(BuildContext context, String assetPath) {
    return AppPressable(
      child: GestureDetector(
        onTap: () => AppRoutes.toCamera(context),
        child: Image.asset(assetPath, height: navbarIconHeight * 1.5),
      ),
    );
  }
}
