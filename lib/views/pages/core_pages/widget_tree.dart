import 'package:flutter/material.dart';
import 'package:later/data/notifiers.dart';
import 'package:later/views/pages/navbar_pages/history_page.dart';
import 'package:later/views/pages/navbar_pages/map_page.dart';
import 'package:later/views/pages/navbar_pages/messages_page.dart';
import 'package:later/views/pages/navbar_pages/profile_page.dart';
import 'package:later/views/widgets/_common/default_elements/navbar_widget.dart';

List<Widget> pages = [
  const MapPage(),
  const HistoryPage(),
  const MessagesPage(),
  const ProfilePage(),
];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F6F6),
          body: Stack(
            children: [
              IndexedStack(index: selectedPage, children: pages),
              Positioned(
                left: 0,
                right: 0,
                bottom: 25,
                child: NavbarWidget(
                  selectedIndex: selectedPage,
                  onItemTapped: (index) {
                    selectedPageNotifier.value = index;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
