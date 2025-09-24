import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/_common/default_elements/default_search_bar.dart';

class PageHeader extends StatelessWidget {
  final String mainText;
  final String? description;
  final Widget? leadingButton;
  final Widget? trailingButton;
  final DefaultSearchBar? searchBar;

  const PageHeader({
    super.key,
    required this.mainText,
    this.description,
    this.leadingButton,
    this.trailingButton,
    this.searchBar,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: screenWidth,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: screenHeight * 0.04,
          bottom: screenHeight * 0.02,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: screenWidth,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  DefaultText(
                    mainText,
                    fontSize: screenHeight * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                  if (leadingButton != null)
                    Positioned(
                      left: 16,
                      top: 0,
                      bottom: 0,
                      child: leadingButton!,
                    ),
                  if (trailingButton != null)
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: trailingButton!,
                    ),
                ],
              ),
            ),
            if (description != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07),
                child: DefaultText(
                  description!,
                  color: Color.fromARGB(255, 94, 94, 94),
                  fontWeight: FontWeight.bold,
                  fontSize: screenHeight * 0.017,
                ),
              ),

            if (searchBar != null)
              Padding(
                padding: EdgeInsets.only(
                  left: screenWidth * 0.04,
                  right: screenWidth * 0.04,
                  top: screenHeight * 0.01,
                ),
                child: searchBar!,
              ),
          ],
        ),
      ),
    );
  }
}
