import 'package:flutter/material.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

class NotificationFilterTabs extends StatelessWidget {
  final TabController controller;

  const NotificationFilterTabs({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final List<String> filters = [
      l10n.notificationsTabAll,
      l10n.notificationsTabReplies,
      l10n.notificationsTabComments,
    ];

    return Center(
      child: IntrinsicWidth(
        child: TabBar(
          controller: controller,
          isScrollable: false,
          indicator: BoxDecoration(
            color: AppColors.brandGreen,
            borderRadius: BorderRadius.circular(25),
          ),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          labelColor: AppColors.onAccent,
          unselectedLabelColor: context.palette.textPrimary,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          padding: EdgeInsets.zero,
          indicatorPadding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 8,
          ),
          tabs: filters.map((filter) {
            return Tab(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                // Longer translations shrink instead of overflowing on
                // narrow phones; English always fits at full size.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(filter, maxLines: 1),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
