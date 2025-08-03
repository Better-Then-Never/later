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
    return ValueListenableBuilder(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Later', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            centerTitle: true,
            backgroundColor: isDarkMode ? const Color.fromARGB(217, 1, 14, 49) : Colors.blueAccent[100],
            actions: [
              IconButton(
                onPressed: () {
                  isDarkModeNotifier.value = !isDarkModeNotifier.value;
                },
                icon: isDarkMode
                    ? Icon(Icons.light_mode)
                    : Icon(Icons.dark_mode),
              ),
            ],
          ),
          body: ValueListenableBuilder(
            valueListenable: selectedPageNotifier,
            builder: (context, selectedPage, child) {
              return pages.elementAt(selectedPage);
            },
          ),
          bottomNavigationBar: NavbarWidget(),
        );
      },
    );
  }
}
