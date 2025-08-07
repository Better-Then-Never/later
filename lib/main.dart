import 'package:flutter/material.dart';
import 'package:later/views/widget_tree.dart';
import 'package:later/views/pages/welcome_page.dart';
import 'package:later/views/pages/camera_page.dart';

void main() {
  runApp(const Application());
}

class Application extends StatelessWidget {
  const Application({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/widgetTree': (context) => const WidgetTree(),
        '/welcome': (context) => const WelcomePage(),
        '/camera': (context) => const CameraPage(),
      },
      home: WelcomePage(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
      ),
    );
  }
}
