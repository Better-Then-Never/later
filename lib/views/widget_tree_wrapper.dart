import 'package:flutter/material.dart';
import 'package:later/data/notifiers.dart';
import 'package:later/views/widget_tree.dart';

class WidgetTreeWrapper extends StatefulWidget {
  const WidgetTreeWrapper({super.key});

  @override
  State<WidgetTreeWrapper> createState() => _WidgetTreeWrapperState();
}

class _WidgetTreeWrapperState extends State<WidgetTreeWrapper> {
  @override
  void initState() {
    super.initState();
    selectedPageNotifier.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return const WidgetTree();
  }
}
