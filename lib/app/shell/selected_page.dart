import 'package:flutter/material.dart';

/// Indexes of the bottom navigation tabs (`pages` in widget_tree.dart).
abstract final class AppTabs {
  static const map = 0;
  static const history = 1;
  static const messages = 2;
  static const profile = 3;
}

ValueNotifier<int> selectedPageNotifier = ValueNotifier(AppTabs.map);
