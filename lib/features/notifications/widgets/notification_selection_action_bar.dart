import 'package:flutter/material.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/core/theme/app_palette.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/shared/widgets/buttons/default_icon_button.dart';
import 'package:later/core/theme/app_colors.dart';

class NotificationSelectionActionBar extends StatelessWidget {
  final int count;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onMarkAsRead;

  const NotificationSelectionActionBar({
    super.key,
    required this.count,
    required this.onCancel,
    required this.onDelete,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final (number, label) = _split(l10n.notificationsSelectedCount(count));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(25),
        // Like the cards: a hairline edge in dark, where shadows vanish.
        border: palette.isDark ? Border.all(color: palette.cardBorder) : null,
        boxShadow: [
          BoxShadow(
            color: palette.shadowCard.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          DefaultText(number, fontSize: 18, fontWeight: FontWeight.bold),
          const SizedBox(width: 4),
          DefaultText(label, fontSize: 14, color: palette.textMuted),
          const Spacer(),
          Semantics(
            button: true,
            label: l10n.notificationsMarkAsRead,
            child: DefaultIconButton(
              onTap: onMarkAsRead,
              child: const Icon(
                Icons.mark_email_read,
                color: AppColors.infoBlue,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: l10n.commonDelete,
            child: DefaultIconButton(
              onTap: onDelete,
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.redAccent,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: l10n.commonCancel,
            child: DefaultIconButton(
              onTap: onCancel,
              child: Icon(Icons.close, color: palette.icon, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  /// "3 selected" as the large bold number and the rest of the phrase, so
  /// each language words it its own way ("3 выбрано", "3 seleccionadas").
  (String, String) _split(String text) {
    final number = '$count';
    final at = text.indexOf(number);
    if (at < 0) return (number, text);
    final rest = (text.substring(0, at) + text.substring(at + number.length))
        .trim();
    return (number, rest);
  }
}
