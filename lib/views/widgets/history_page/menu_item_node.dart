import 'package:flutter/foundation.dart';

class MenuItemNode {
  final String label;
  final VoidCallback? onTap;
  final List<MenuItemNode>? children;

  const MenuItemNode({
    required this.label,
    this.onTap,
    this.children,
  });

  bool get hasChildren => children != null && children!.isNotEmpty;
}
