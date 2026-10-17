import 'package:flutter/material.dart';
import 'package:later/shared/widgets/default_search_bar.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/core/theme/app_colors.dart';
import 'package:later/core/l10n/l10n.dart';

class PinnedFriendSelectionDialogHeader extends StatelessWidget {
  final TextEditingController searchController;
  final void Function(String value)? onSearchControllerChanged;

  const PinnedFriendSelectionDialogHeader({
    super.key,
    required this.onSearchControllerChanged,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          DefaultText(
            l10n.profilePinnedTitle,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.brandGreen,
          ),
          const SizedBox(height: 4),
          DefaultText(
            l10n.profilePinnedHint,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          DefaultSearchBar(
            controller: searchController,
            onChanged: onSearchControllerChanged,
          ),
        ],
      ),
    );
  }
}
