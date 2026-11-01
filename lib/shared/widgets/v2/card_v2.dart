import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';

/// A card of the v2 design: the surface, 20 dp corners, the card shadow.
class CardV2 extends StatelessWidget {
  const CardV2({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(AppRadii.m),
      boxShadow: AppShadows.card(context),
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

/// The rows of a [CardV2], with hairlines between them from the text on.
class CardV2Rows extends StatelessWidget {
  const CardV2Rows({super.key, required this.children, this.indent = 58});

  final List<Widget> children;

  /// Where the hairlines start (past the icons).
  final double indent;

  @override
  Widget build(BuildContext context) => CardV2(
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              thickness: 1,
              indent: indent,
              color: context.palette.divider,
            ),
          children[i],
        ],
      ],
    ),
  );
}

/// "MY CAPSULES", "TODAY": a small grey label above a card.
class GroupLabelV2 extends StatelessWidget {
  const GroupLabelV2(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              height: 1.2,
              letterSpacing: 0.96,
              fontWeight: FontWeight.bold,
              color: context.palette.textSecondary,
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// "My capsules", "Friends": the centred title of a profile section.
class SectionTitleV2 extends StatelessWidget {
  const SectionTitleV2(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 18, 0, 10),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: AppTextStyles.body.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: context.palette.textPrimary,
      ),
    ),
  );
}

/// A row of the v2 design (Figma "Row v2", regular): an icon or [leading],
/// the title (a grey line under it), a value in grey, an arrow.
class RowV2 extends StatelessWidget {
  const RowV2({
    super.key,
    required this.title,
    this.onTap,
    this.iconPath,
    this.leading,
    this.subtitle,
    this.value,
    this.trailing,
    this.tint = false,
    this.danger = false,
    this.arrow = true,
  });

  final String title;
  final VoidCallback? onTap;
  final String? iconPath;
  final Widget? leading;
  final String? subtitle;
  final String? value;

  /// Instead of the value (a badge, a switch).
  final Widget? trailing;

  /// The icon is drawn in colour: shown in the icons' ink instead.
  final bool tint;

  /// Red words (Log out, Block).
  final bool danger;
  final bool arrow;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final titleColor = danger ? AppColors.danger : palette.textPrimary;
    TextStyle row(Color color) =>
        AppTextStyles.body.copyWith(fontSize: 16, height: 1.25, color: color);
    final lead =
        leading ??
        (iconPath == null
            ? null
            : Image.asset(
                iconPath!,
                width: 28,
                height: 28,
                color: tint ? palette.icon : null,
              ));
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            child: Row(
              children: [
                if (lead != null) ...[lead, const SizedBox(width: 14)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: row(titleColor)),
                      if (subtitle case final line?)
                        Text(
                          line,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 13,
                            height: 1.25,
                            color: palette.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (value case final words?) ...[
                  const SizedBox(width: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      words,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: row(palette.textMuted),
                    ),
                  ),
                ],
                if (trailing != null) ...[const SizedBox(width: 10), trailing!],
                if (arrow && onTap != null) ...[
                  const SizedBox(width: 14),
                  Image.asset(AppIcons.goHere, width: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
