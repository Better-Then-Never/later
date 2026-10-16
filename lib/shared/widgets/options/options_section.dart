import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../styles/box_decorations.dart';
import '../default_text.dart';
import '../../../core/theme/app_palette.dart';

/// A titled white card of settings rows, as on the Settings page.
class OptionsSection extends StatelessWidget {
  const OptionsSection({
    super.key,
    this.title,
    this.footer,
    required this.children,
  });

  /// Upper-case label above the card; none for a card on its own.
  final String? title;

  /// Grey explanation under the card.
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            DefaultText(
              title!,
              textAlign: TextAlign.left,
              padding: EdgeInsets.only(
                left: screenWidth * 0.09,
                bottom: screenHeight * 0.01,
              ),
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.045,
            ),
          Center(
            child: Container(
              width: screenWidth * 0.92,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecorations.whiteCard(context),
              child: Column(children: children),
            ),
          ),
          if (footer != null)
            DefaultText(
              footer!,
              textAlign: TextAlign.left,
              color: context.palette.textSecondary,
              padding: EdgeInsets.only(
                left: screenWidth * 0.09,
                right: screenWidth * 0.09,
                top: screenHeight * 0.008,
              ),
            ),
        ],
      ),
    );
  }
}

/// A settings row with an on/off switch.
class OptionsSwitchRow extends StatelessWidget {
  const OptionsSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.withDivider = true,
  });

  final String title;
  final String? subtitle;
  final bool value;

  /// Null disables the row.
  final ValueChanged<bool>? onChanged;
  final bool withDivider;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final enabled = onChanged != null;
    return Column(
      children: [
        MergeSemantics(
          child: ListTile(
            dense: true,
            enabled: enabled,
            minVerticalPadding: 6,
            visualDensity: const VisualDensity(vertical: -3),
            contentPadding: EdgeInsets.only(
              left: screenWidth * 0.05,
              right: screenWidth * 0.03,
            ),
            title: DefaultText(
              title,
              textAlign: TextAlign.start,
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.045,
              color: enabled
                  ? context.palette.textPrimary
                  : context.palette.iconMuted,
            ),
            subtitle: subtitle == null
                ? null
                : DefaultText(
                    subtitle!,
                    textAlign: TextAlign.start,
                    color: enabled
                        ? context.palette.textSecondary
                        : context.palette.iconMuted,
                  ),
            trailing: AppSwitch(value: value, onChanged: onChanged),
            onTap: enabled ? () => onChanged!(!value) : null,
          ),
        ),
        if (withDivider)
          Divider(height: 1, thickness: 1, color: context.palette.divider),
      ],
    );
  }
}

/// The app's switch: brand green when on, grey when off.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.onAccent,
      activeTrackColor: AppColors.brandGreen,
      inactiveThumbColor: AppColors.onAccent,
      inactiveTrackColor: context.palette.disabled,
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }
}
