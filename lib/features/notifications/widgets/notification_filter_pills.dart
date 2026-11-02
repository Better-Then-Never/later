import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../shared/widgets/pill_v2.dart';
import '../notification_groups.dart';

/// All, Friends, Capsules, Places under the page title: the chosen pill
/// solid, the others outlined.
class NotificationFilterPills extends StatelessWidget {
  const NotificationFilterPills({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final NotificationFilter selected;
  final ValueChanged<NotificationFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final filter in NotificationFilter.values) ...[
            if (filter != NotificationFilter.values.first)
              const SizedBox(width: 8),
            Semantics(
              selected: filter == selected,
              child: PillV2(
                label: filter.label(l10n),
                size: PillV2Size.small,
                kind: filter == selected
                    ? PillV2Kind.solid
                    : PillV2Kind.outline,
                onTap: () => onSelected(filter),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
