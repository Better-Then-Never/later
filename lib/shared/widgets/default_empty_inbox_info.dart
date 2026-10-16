import 'package:flutter/material.dart';
import 'package:later/shared/widgets/buttons/default_green_button.dart';
import 'package:later/shared/widgets/default_text.dart';
import '../../core/theme/app_palette.dart';

/// The app's empty and error state: icon (72 px), bold title, grey subtitle
/// and, when [actionText] is set, a small green button (e.g. "Retry").
class DefaultEmptyInboxInfo extends StatelessWidget {
  final String message;
  final String? subtitle;
  final String assetPath;
  final String? actionText;
  final VoidCallback? onAction;

  const DefaultEmptyInboxInfo({
    super.key,
    required this.message,
    this.subtitle,
    required this.assetPath,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final action = onAction;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screen.width * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(assetPath, width: 72, height: 72),
            const SizedBox(height: 5),
            DefaultText(
              message,
              fontSize: screen.width * 0.048,
              fontWeight: FontWeight.w900,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            if (subtitle != null)
              DefaultText(
                subtitle!,
                textAlign: TextAlign.center,
                fontSize: screen.width * 0.033,
                color: context.palette.textMuted,
              ),
            if (actionText != null && action != null) ...[
              const SizedBox(height: 16),
              DefaultGreenButton(
                onTap: action,
                text: actionText!,
                textFontSize: 18,
                width: screen.width * 0.35,
                height: screen.height * 0.05,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
