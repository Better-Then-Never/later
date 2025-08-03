import 'package:flutter/material.dart';
import 'package:later/views/widget_tree.dart';

void main() {
  runApp(const Application());
}

class Application extends StatelessWidget {
  const Application({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WidgetTree(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF55a3ec),
          brightness: Brightness.light,
        ),
      ),
    );
  }
}
