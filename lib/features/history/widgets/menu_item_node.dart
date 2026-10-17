import 'package:flutter/foundation.dart';

class MenuItemNode {
  final String label;
  final VoidCallback? onTap;
  final List<MenuItemNode>? children;

  /// The current choice (shown in green).
  final bool selected;

  const MenuItemNode({
    required this.label,
    this.onTap,
    this.children,
    this.selected = false,
  });

  bool get hasChildren => children != null && children!.isNotEmpty;

  /// Selected itself or somewhere in its submenu.
  bool get isSelected =>
      selected || (children?.any((c) => c.isSelected) ?? false);
}
