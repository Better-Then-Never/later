import 'package:flutter/material.dart';
import 'package:later/app/shell/selected_page.dart';
import 'package:later/features/history/history_page.dart';
import 'package:later/features/map/map_page.dart';
import 'package:later/features/messages/messages_page.dart';
import 'package:later/features/profile/profile_page.dart';
import 'package:later/app/shell/navbar_widget.dart';
import 'package:later/core/theme/app_colors.dart';

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
          backgroundColor: AppColors.pageBackground,
          body: Stack(
            children: [
              IndexedStack(index: selectedPage, children: pages),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: NavbarWidget(
                    selectedIndex: selectedPage,
                    onItemTapped: (index) {
                      selectedPageNotifier.value = index;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
