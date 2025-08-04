import 'package:flutter/material.dart';
import 'package:later/data/notifiers.dart';
import 'package:later/views/pages/map_page.dart';
import 'package:later/views/pages/profile_page.dart';
import 'package:later/views/widgets/navbar_widget.dart';

//Placeholder for the pages
//TODO: Replace with actual pages

List<Widget> pages = [
  const MapPage(),
  const ProfilePage(),
  const MapPage(),
  const ProfilePage(),
  const MapPage(),
];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        return Scaffold(
          backgroundColor: Color(0xFFF6F6F6),
          body: pages[selectedPage],
          bottomNavigationBar: NavbarWidget(
            selectedIndex: selectedPage,
            onItemTapped: (index) {
              selectedPageNotifier.value = index;
            },
          ),
        );
      },
    );
  }
}
