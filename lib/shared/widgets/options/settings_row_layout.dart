import 'package:flutter/material.dart';

/// The layout every settings row shares: an optional [leading] picture, the
/// [title] over an optional [subtitle], and an optional [trailing] widget,
/// at least 44 dp tall (D-24) and tappable as a whole.
///
/// It replaces Material's `ListTile` in the settings lists. A `ListTile`
/// measures its parts' intrinsic sizes, laying their text out more than
/// once, and the rows also built a fresh `ThemeData` each to hide the
/// splash: opening Settings spent ~9 ms of its first frame on text layout
/// (docs/feel/PERFORMANCE.md). The text styles inherited from the theme are
/// the ones `ListTile` used, so the rows look the same.
class SettingsRowLayout extends StatelessWidget {
  const SettingsRowLayout({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    required this.padding,
    this.verticalPadding = 10,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Left and right insets of the row.
  final EdgeInsets padding;

  /// Space above and below the text.
  final double verticalPadding;

  /// The smallest height of a row (a tap target, D-24).
  static const minHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final colors = theme.colorScheme;
    final row = Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minHeight),
        child: Row(
          children: [
            if (leading case final leading?) ...[
              leading,
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The text styles a dense ListTile gave its parts.
                    DefaultTextStyle.merge(
                      style: text.bodyLarge?.copyWith(fontSize: 13),
                      child: title,
                    ),
                    if (subtitle case final subtitle?)
                      DefaultTextStyle.merge(
                        style: text.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                        child: subtitle,
                      ),
                  ],
                ),
              ),
            ),
            if (trailing case final trailing?) ...[
              const SizedBox(width: 16),
              // Centred, and never taller than a plain row.
              SizedBox(
                height: minHeight,
                child: Center(widthFactor: 1, child: trailing),
              ),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      child: row,
    );
  }
}
