import 'package:flutter/material.dart';
import 'package:later/app/router/app_routes.dart';
import 'package:later/core/assets/app_assets.dart';

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildIcon(0, AppIcons.navbarMap),
            _buildIcon(1, AppIcons.navbarHistory),
            _buildAddIcon(context, AppIcons.navbarAdd),
            _buildIcon(2, AppIcons.navbarMessages),
            _buildIcon(3, AppIcons.navbarProfile),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(int index, String assetPath) {
    final isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () {
        onItemTapped(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: navbarIconHeight * (isSelected ? 1.2 : 1.0),
        width: navbarIconHeight * (isSelected ? 1.2 : 1.0),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 100),
          tween: Tween(begin: 1.0, end: 1.0),
          builder: (context, scale, child) {
            return AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 10),
              curve: Curves.easeInOut,
              child: child,
            );
          },
          child: Image.asset(assetPath),
        ),
      ),
    );
  }

  Widget _buildAddIcon(BuildContext context, String assetPath) {
    return GestureDetector(
      onTap: () {
        AppRoutes.toCamera(context);
      },
      child: Image.asset(assetPath, height: navbarIconHeight * 1.5),
    );
  }
}
