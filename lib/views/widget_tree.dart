import 'package:flutter/material.dart';
import 'package:later/data/notifiers.dart';
import 'package:later/views/pages/map_page.dart';
import 'package:later/views/pages/welcome_page.dart';
import 'package:later/views/pages/profile_page.dart';
import 'package:later/views/widgets/navbar_widget.dart';

List<Widget> pages = [
  const WelcomePage(),
  const MapPage(),
  const ProfilePage(),
];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        return ValueListenableBuilder<int>(
          valueListenable: selectedPageNotifier,
          builder: (context, selectedPage, child) {
            final isShowingNavBar = selectedPage == 0;

            return Scaffold(
              appBar: isShowingNavBar
                  ? null
                  : AppBar(
                      title: Text(
                        'Later',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      centerTitle: true,
                      backgroundColor: isDarkMode
                          ? const Color.fromARGB(217, 1, 14, 49)
                          : Colors.blueAccent[100],
                      actions: [
                        IconButton(
                          onPressed: () {
                            isDarkModeNotifier.value =
                                !isDarkModeNotifier.value;
                          },
                          icon: isDarkMode
                              ? const Icon(Icons.light_mode)
                              : const Icon(Icons.dark_mode),
                        ),
                      ],
                    ),
              body: pages[selectedPage],
              bottomNavigationBar: isShowingNavBar
                  ? null
                  : const NavbarWidget(),
            );
          },
        );
      },
    );
  }
}
