import 'package:flutter/material.dart';
import 'package:later/data/notifiers.dart';
import 'package:later/views/pages/map_page.dart';
import 'package:later/views/pages/profile_page.dart';
import 'package:later/views/widgets/navbar_widget.dart';

List<Widget> pages = [const MapPage(), const ProfilePage()];

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
          bottomNavigationBar: const NavbarWidget(),
        );
      },
    );
  }
}
