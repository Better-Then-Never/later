import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:later/core/theme/app_text_styles.dart';
import '../../core/theme/app_palette.dart';
import '../../core/l10n/l10n.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;

  /// "Confirm" / "Cancel" in the app's language when null.
  final String? confirmText;
  final String? cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmButtonColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    this.confirmText,
    this.cancelText,
    required this.onConfirm,
    this.onCancel,
    this.confirmButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Center(
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: 264,
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: BorderRadius.circular(25),
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
          ),
        ),
      ),
    );
  }

  static Future<void> show({
    required BuildContext context,
    required String title,
    String? confirmText,
    String? cancelText,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    Color? confirmButtonColor,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: context.palette.scrim,
      builder: (BuildContext context) {
        return ConfirmDialog(
          title: title,
          confirmText: confirmText,
          cancelText: cancelText,
          onConfirm: onConfirm,
          onCancel: onCancel,
          confirmButtonColor: confirmButtonColor,
        );
      },
    );
  }
}
