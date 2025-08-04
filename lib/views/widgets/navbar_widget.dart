import 'package:flutter/material.dart';

const double NAVBAR_ICON_HEIGHT = 46.0;

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildIcon(
              0,
              'assets/images/icons/navbar/icon-map.png',
              NAVBAR_ICON_HEIGHT,
            ),
            _buildIcon(
              1,
              'assets/images/icons/navbar/icon-history.png',
              NAVBAR_ICON_HEIGHT,
            ),
            _buildIcon(
              2,
              'assets/images/icons/navbar/icon-add.png',
              NAVBAR_ICON_HEIGHT,
            ),
            _buildIcon(
              3,
              'assets/images/icons/navbar/icon-messages.png',
              NAVBAR_ICON_HEIGHT,
            ),
            _buildIcon(
              4,
              'assets/images/icons/navbar/icon-profile.png',
              NAVBAR_ICON_HEIGHT,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(int index, String assetPath, double height) {
    final isSelected = index == selectedIndex;
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Image.asset(assetPath, height: isSelected ? height * 1.2 : height),
    );
  }
}
