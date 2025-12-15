import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/history_page/menu_item_node.dart';
import 'package:later/views/widgets/my_profile_page/profile_page_divider.dart';

class NestedMenu extends StatefulWidget {
  final String title;
  final List<MenuItemNode> rootItems;

  const NestedMenu({super.key, required this.title, required this.rootItems});

  @override
  State<NestedMenu> createState() => _NestedMenuState();
}

class _NestedMenuState extends State<NestedMenu> {
  late List<MenuItemNode> _currentItems;
  final List<List<MenuItemNode>> _history = [];

  @override
  void initState() {
    super.initState();
    _currentItems = widget.rootItems;
  }

  void _openSubmenu(List<MenuItemNode> items) {
    _history.add(_currentItems);
    setState(() => _currentItems = items);
  }

  void _goBack() {
    setState(() => _currentItems = _history.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color(0xFFEAEAEA),
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (_history.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _goBack,
                    ),
                  DefaultText(widget.title, fontWeight: FontWeight.bold),
                ],
              ),
            ),
            const ProfilePageDivider(width: double.infinity),

            ..._currentItems.map(
              (item) => ListTile(
                title: DefaultText(item.label, textAlign: TextAlign.left,),
                trailing: item.hasChildren
                    ? const Icon(Icons.chevron_right)
                    : null,
                onTap: () {
                  if (item.hasChildren) {
                    _openSubmenu(item.children!);
                  } else {
                    item.onTap?.call();
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
