import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';

class FriendRequestsToggleButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isSelected;
  final EdgeInsetsGeometry? contentPadding;
  final String text;

  const FriendRequestsToggleButton({
    super.key,
    required this.onTap,
    required this.text,
    required this.isSelected,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 35,
          decoration: BoxDecoration(
            color: isSelected ? Color.fromARGB(255, 86, 201, 46) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color.fromARGB(255, 86, 201, 46),
              width: 2,
            ),
          ),
          child: Center(
            child: DefaultText(
              text,
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : Color.fromARGB(255, 86, 201, 46),
            ),
          ),
        ),
      ),
    );
  }
}
