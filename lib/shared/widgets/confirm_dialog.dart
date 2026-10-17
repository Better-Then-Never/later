import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:later/core/theme/app_text_styles.dart';
import '../../core/theme/app_palette.dart';
import '../../core/l10n/l10n.dart';
import 'app_sheets.dart';

/// A centred confirmation card: [title], an optional [message], one
/// coloured button and Cancel. Opened with [ConfirmDialog.show].
class ConfirmDialog extends StatelessWidget {
  final String title;

  /// A sentence under the title, when the title alone does not say enough.
  final String? message;

  /// "Confirm" / "Cancel" in the app's language when null.
  final String? confirmText;
  final String? cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmButtonColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmText,
    this.cancelText,
    required this.onConfirm,
    this.onCancel,
    this.confirmButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    return Container(
      width: AppSheets.cardWidth,
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppSheets.radius),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title,
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Text(
                message,
                style: TextStyle(
                  color: context.palette.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 6),
          SizedBox(
            width: 160,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmButtonColor ?? AppColors.danger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
                padding: EdgeInsets.zero,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text(
                confirmText ?? context.l10n.commonConfirm,
                style: const TextStyle(
                  color: AppColors.onAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 0),
          TextButton(
            onPressed: onCancel ?? () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: context.palette.textSecondary,
              textStyle: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              padding: EdgeInsets.zero,
            ),
            child: Text(cancelText ?? context.l10n.commonCancel),
          ),
        ],
      ),
    );
  }

  static Future<void> show({
    required BuildContext context,
    required String title,
    String? message,
    String? confirmText,
    String? cancelText,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    Color? confirmButtonColor,
  }) {
    return showCenteredSheet<void>(
      context,
      ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmButtonColor: confirmButtonColor,
      ),
    );
  }
}
