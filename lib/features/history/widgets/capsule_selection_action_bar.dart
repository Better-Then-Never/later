import 'package:flutter/material.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/core/theme/app_palette.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/shared/widgets/profile_page_divider.dart';
import 'package:later/core/theme/app_colors.dart';

class SelectionActionBar extends StatelessWidget {
  final int count;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const SelectionActionBar({
    super.key,
    required this.count,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          SizedBox(height: screenHeight * 0.01),
          const ProfilePageDivider(width: double.infinity),
          Row(
            children: [
              // Takes the free space (pushing the buttons right, like a
              // Spacer) and shrinks when a translation would not fit.
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: DefaultText(
                      l10n.historySelectedCount(count),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onCancel,
                icon: Icon(Icons.close, color: context.palette.icon),
                label: DefaultText(l10n.commonCancel),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, color: AppColors.redAccent),
                label: Text(
                  l10n.historyDeleteSelected(count),
                  style: const TextStyle(color: AppColors.redAccent),
                ),
              ),
            ],
          ),

          const ProfilePageDivider(width: double.infinity),
        ],
      ),
    );
  }
}
