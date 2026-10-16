import 'package:flutter/material.dart';
import 'package:later/shared/widgets/default_search_bar.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/core/theme/app_colors.dart';

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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const DefaultText(
            'Choose up to 3 pinned friends',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.brandGreen,
          ),
          const SizedBox(height: 4),
          const DefaultText(
            'If you choose fewer than 3, random friends from your list will be shown',
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
