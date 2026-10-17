import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/buttons/default_green_button.dart';
import '../../../shared/widgets/buttons/go_back_button.dart';
import '../../../shared/widgets/default_text.dart';
import '../../../shared/widgets/options/settings_row_layout.dart';
import '../../../shared/widgets/page_header.dart';

/// Frame of every settings page: the white header with a back button, a
/// scrolling body and an optional green button at the bottom.
class SettingsScaffold extends StatelessWidget {
  const SettingsScaffold({
    super.key,
    required this.title,
    this.description,
    required this.children,
    this.buttonText,
    this.onButton,
    this.busy = false,
    this.destructive = false,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  /// The bottom button (e.g. "Save"); none when null.
  final String? buttonText;
  final VoidCallback? onButton;
  final bool busy;

  /// The bottom button deletes something (red).
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: context.palette.backgroundAlt,
      body: Column(
        children: [
          PageHeader(
            mainText: title,
            description: description,
            leadingButton: GoBackButton(context: context),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                top: screenHeight * 0.02,
                bottom: screenHeight * 0.04,
              ),
              children: children,
            ),
          ),
        ],
      ),
      bottomNavigationBar: buttonText == null
          ? null
          : SafeArea(
              minimum: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.15,
                vertical: screenWidth * 0.08,
              ),
              child: DefaultGreenButton(
                onTap: onButton ?? () {},
                text: buttonText!,
                isLoading: busy,
                destructive: destructive,
              ),
            ),
    );
  }
}

/// Grey explanatory text between the cards of a settings page.
class SettingsNote extends StatelessWidget {
  const SettingsNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return DefaultText(
      text,
      textAlign: TextAlign.left,
      color: context.palette.textSecondary,
      padding: EdgeInsets.only(
        left: screenWidth * 0.09,
        right: screenWidth * 0.09,
        bottom: screenHeight * 0.015,
      ),
    );
  }
}

/// One option of a single choice (map look, starting camera): a green check
/// marks the selected one.
class SettingsChoiceRow extends StatelessWidget {
  const SettingsChoiceRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.withDivider = true,
  });

  final String title;

  /// A grey line under the title (what the option means).
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool withDivider;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Semantics(
          selected: selected,
          button: true,
          child: SettingsRowLayout(
            verticalPadding: 6,
            padding: EdgeInsets.only(
              left: screenWidth * 0.05,
              right: screenWidth * 0.05,
            ),
            title: DefaultText(
              title,
              textAlign: TextAlign.start,
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.045,
            ),
            subtitle: subtitle == null
                ? null
                : DefaultText(
                    subtitle!,
                    textAlign: TextAlign.start,
                    color: context.palette.textSecondary,
                  ),
            trailing: selected
                ? Icon(
                    Icons.check_circle,
                    color: AppColors.brandGreen,
                    size: screenWidth * 0.065,
                  )
                : null,
            onTap: onTap,
          ),
        ),
        if (withDivider)
          Divider(height: 1, thickness: 1, color: context.palette.divider),
      ],
    );
  }
}
