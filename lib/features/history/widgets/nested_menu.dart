import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/options_menu.dart';
import 'menu_item_node.dart';

/// A drill-down menu (sort, filter) in the centred card style of every
/// other menu (F-32): a green title, rows like [OptionsMenuItem] with a
/// chevron when they open a submenu, a back arrow inside one, the current
/// choice in green. The card resizes smoothly between levels.
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
    final items = _currentItems;
    return OptionsMenu(
      children: [
        Stack(
          children: [
            OptionsMenuTitle(widget.title),
            if (_history.isNotEmpty)
              Positioned(
                left: 4,
                top: 0,
                height: 37,
                child: IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: _goBack,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.brandGreen,
                    size: 22,
                  ),
                ),
              ),
          ],
        ),
        AnimatedSize(
          duration: AppMotion.standard,
          curve: AppMotion.emphasizedCurve,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: AppMotion.fast,
            child: Column(
              key: ValueKey(_history.length),
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const OptionsMenuDivider(),
                  OptionsMenuItem(
                    text: items[i].label,
                    textColor: items[i].isSelected
                        ? AppColors.brandGreen
                        : null,
                    isLast: i == items.length - 1,
                    trailing: items[i].hasChildren
                        ? Icon(
                            Icons.chevron_right,
                            color: context.palette.iconMuted,
                          )
                        : null,
                    onPressed: () {
                      final item = items[i];
                      if (item.hasChildren) {
                        _openSubmenu(item.children!);
                      } else {
                        item.onTap?.call();
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
