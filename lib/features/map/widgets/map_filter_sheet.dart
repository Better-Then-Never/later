import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../map_filter.dart';

/// What the map shows (B5): whose capsules, open or opening later, which
/// pin colours. Every change applies at once; "Show everything" resets.
class MapFilterSheet extends StatefulWidget {
  const MapFilterSheet({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final MapFilter initial;
  final ValueChanged<MapFilter> onChanged;

  static Future<void> show(
    BuildContext context, {
    required MapFilter filter,
    required ValueChanged<MapFilter> onChanged,
  }) => showEdgeSheet<void>(
    context,
    (_) => MapFilterSheet(initial: filter, onChanged: onChanged),
  );

  @override
  State<MapFilterSheet> createState() => _MapFilterSheetState();
}

class _MapFilterSheetState extends State<MapFilterSheet> {
  late MapFilter _filter = widget.initial;

  void _apply(MapFilter next) {
    HapticFeedback.selectionClick();
    setState(() => _filter = next);
    widget.onChanged(next);
  }

  /// Toggles [value] in [set]; the last one of a kind cannot be turned off
  /// (an empty map would look broken).
  Set<T> _toggle<T>(Set<T> set, T value, {bool mayEmpty = false}) {
    final next = {...set};
    if (next.contains(value)) {
      if (next.length == 1 && !mayEmpty) return set;
      next.remove(value);
    } else {
      next.add(value);
    }
    return next;
  }

  static String _colorName(AppLocalizations l10n, CapsuleColor c) =>
      switch (c) {
        CapsuleColor.red => l10n.capsulesColorRed,
        CapsuleColor.blue => l10n.capsulesColorBlue,
        CapsuleColor.green => l10n.capsulesColorGreen,
        CapsuleColor.yellow => l10n.capsulesColorYellow,
        CapsuleColor.orange => l10n.capsulesColorOrange,
        CapsuleColor.purple => l10n.capsulesColorPurple,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final f = _filter;
    Widget section(String title, List<Widget> chips) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSheets.radius),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: SheetHandle()),
            Center(
              child: Text(
                l10n.mapFilterTitle,
                style: AppTextStyles.pageTitle(context).copyWith(fontSize: 20),
              ),
            ),
            section(l10n.mapFilterWhose, [
              for (final (owner, label) in [
                (MapOwner.mine, l10n.mapFilterMine),
                (MapOwner.friends, l10n.mapFilterFriends),
                (MapOwner.others, l10n.mapFilterOthers),
              ])
                _Chip(
                  label: label,
                  selected: f.owners.contains(owner),
                  onTap: () =>
                      _apply(f.copyWith(owners: _toggle(f.owners, owner))),
                ),
            ]),
            section(l10n.mapFilterState, [
              for (final (state, label) in [
                (MapOpenState.open, l10n.mapFilterOpen),
                (MapOpenState.locked, l10n.mapFilterLocked),
              ])
                _Chip(
                  label: label,
                  selected: f.states.contains(state),
                  onTap: () =>
                      _apply(f.copyWith(states: _toggle(f.states, state))),
                ),
            ]),
            section(l10n.mapFilterColors, [
              for (final color in CapsuleColor.values)
                _Chip(
                  label: _colorName(l10n, color),
                  icon: AppIcons.capsulePin(color.name),
                  selected: f.colors.contains(color),
                  onTap: () => _apply(
                    f.copyWith(
                      colors: _toggle(f.colors, color, mayEmpty: true),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: f.isDefault ? null : () => _apply(MapFilter.all),
                child: Text(
                  l10n.mapFilterReset,
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: f.isDefault
                        ? palette.textMuted
                        : AppColors.brandGreen,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A choice that is on (green) or off (muted).
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.fast),
          curve: AppMotion.standardCurve,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandGreen : palette.surfaceMuted,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon case final path?) ...[
                Image.asset(path, width: 20, height: 20),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: selected ? AppColors.onAccent : palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
