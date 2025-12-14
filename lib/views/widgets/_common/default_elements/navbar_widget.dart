import 'package:flutter/material.dart';

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
    double screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.01),
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
            _buildIcon(0, 'assets/images/icons/navbar/icon-map.png'),
            _buildIcon(1, 'assets/images/icons/navbar/icon-history.png'),
            _buildAddIcon(context, 'assets/images/icons/navbar/icon-add.png'),
            _buildIcon(2, 'assets/images/icons/navbar/icon-messages.png'),
            _buildIcon(3, 'assets/images/icons/navbar/icon-profile.png'),
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
        Navigator.pushNamed(context, '/camera');
      },
      child: Image.asset(assetPath, height: navbarIconHeight * 1.5),
    );
  }
}
