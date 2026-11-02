import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/models/social.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/push_messaging_service.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/motion/idle_float.dart';
import '../../../shared/widgets/v2/card_v2.dart';
import '../../settings/settings_store.dart';
import '../notification_groups.dart';
import '../notification_router.dart';
import '../notifications_selection_controller.dart';
import '../notifications_store.dart';
import 'friend_requests_card.dart';
import 'notification_item.dart';
import 'notification_leading.dart';
import 'notification_timestamp.dart';

export '../notification_groups.dart' show NotificationFilter;

/// One row of a card: a notification or a word from the team.
sealed class _Entry {
  const _Entry();
}

class _Note extends _Entry {
  const _Note(this.notification);
  final AppNotification notification;
}

class _News extends _Entry {
  const _News(this.announcement);
  final Announcement announcement;
}

/// The notifications of [filter] (Profile v4): the waiting friend requests
/// in one card on top (All and Friends), then Today and Earlier, each a
/// card of rows, newest first. On "All" the Later team's announcements join
/// them (unless the user turned News off). A swipe right marks one read,
/// left deletes it; a long press starts selecting.
class NotificationsList extends StatefulWidget {
  const NotificationsList({
    super.key,
    required this.filter,
    required this.selection,
    this.onOpenRequests,
  });

  final NotificationFilter filter;
  final NotificationsSelectionController selection;

  /// Instead of opening the friend requests page (tests).
  final VoidCallback? onOpenRequests;

  @override
  State<NotificationsList> createState() => _NotificationsListState();
}

class _NotificationsListState extends State<NotificationsList> {
  NotificationFilter get filter => widget.filter;
  NotificationsSelectionController get selection => widget.selection;

  late final Stream<List<Announcement>> _news = context
      .read<SocialRepository>()
      .watchAnnouncements(limit: 10);

  /// [notes] and [news] in their day's group, newest first.
  static Map<NotificationDay, List<_Entry>> _groups(
    List<AppNotification> notes,
    List<Announcement> news,
    DateTime now,
  ) {
    final timed = <(DateTime?, _Entry)>[
      for (final n in notes) (n.timestamp, _Note(n)),
      for (final a in news) (a.createdAt, _News(a)),
    ]..sort((a, b) => (b.$1 ?? now).compareTo(a.$1 ?? now));
    final out = <NotificationDay, List<_Entry>>{};
    for (final (time, entry) in timed) {
      (out[NotificationDay.of(time, now)] ??= []).add(entry);
    }
    return out;
  }

  bool get _showsRequests =>
      filter == NotificationFilter.all || filter == NotificationFilter.friends;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NotificationsStore>();
    final showNews =
        filter == NotificationFilter.all &&
        context.select<SettingsStore, bool>((s) => s.notifications.news);
    return StreamBuilder<List<Announcement>>(
      stream: _news,
      builder: (context, snapshot) => _list(
        context,
        store,
        showNews ? snapshot.data ?? const [] : const [],
      ),
    );
  }

  Widget _list(
    BuildContext context,
    NotificationsStore store,
    List<Announcement> news,
  ) {
    final items = store.notifications.where(filter.accepts).toList();
    final requests = _showsRequests
        ? FriendRequestsCard(onTap: widget.onOpenRequests)
        : null;
    const padding = EdgeInsets.fromLTRB(16, 8, 16, 24);

    // The list is live; pulling listens again from scratch (a fresh read,
    // and the way out of a failed stream).
    Widget refreshable(Widget child) => RefreshIndicator(
      color: context.palette.icon,
      onRefresh: () => context.read<NotificationsStore>().refresh(),
      child: child,
    );

    if (items.isEmpty && news.isEmpty) {
      // Pullable too: an empty list is when a fresh look helps most.
      return refreshable(
        ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          children: [
            ?requests,
            const SizedBox(height: 16),
            _EmptyState(filter: filter),
          ],
        ),
      );
    }

    final groups = _groups(items, news, DateTime.now());
    return ListenableBuilder(
      listenable: selection,
      builder: (context, _) => refreshable(
        AppStaggerScope(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: padding,
            children: [
              if (requests != null) AppStaggerItem(index: 0, child: requests),
              for (final day in NotificationDay.values)
                if (groups[day] case final entries?)
                  AppStaggerItem(
                    key: ValueKey('group-${day.name}'),
                    index: day.index + 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: GroupLabelV2(day.label(context.l10n)),
                        ),
                        CardV2Rows(
                          indent: NotificationItem.hairlineIndent,
                          children: [
                            for (var i = 0; i < entries.length; i++)
                              _row(context, entries[i], i),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, _Entry entry, int index) => switch (entry) {
    _News(:final announcement) => _NewsItem(
      key: ValueKey('news-${announcement.id}'),
      announcement: announcement,
    ),
    _Note(notification: final n) => _Swipe(
      key: ValueKey(n.id),
      enabled: !selection.isSelectionMode,
      notification: n,
      child: NotificationItem(
        notification: n,
        index: index,
        isSelected: selection.isSelected(n.id),
        selectionMode: selection.isSelectionMode,
        onTap: () {
          if (selection.isSelectionMode) {
            selection.toggleSelection(n.id);
          } else {
            _open(context, n);
          }
        },
        onLongPress: () => selection.toggleSelection(n.id),
      ),
    ),
  };

  void _open(BuildContext context, AppNotification n) {
    context.read<NotificationsStore>().markRead([n.id]);
    context.read<NotificationRouter>().handle(
      NotificationTap.fromNotification(n),
    );
  }
}

/// A word from the Later team, in the app's language (English otherwise).
class _NewsItem extends StatelessWidget {
  const _NewsItem({super.key, required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final lang = l10n.localeName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 28, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: Image.asset(
              AppImages.laterLogo,
              width: NotificationLeading.size,
              height: NotificationLeading.size,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.notificationsFromLater,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: palette.accentText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  announcement.titleIn(lang),
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  announcement.bodyIn(lang),
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15,
                    height: 1.3,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                NotificationTimestamp(
                  timestamp: announcement.createdAt ?? DateTime.now(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A notification that swipes: right marks it read (it springs back), left
/// deletes it.
class _Swipe extends StatelessWidget {
  const _Swipe({
    super.key,
    required this.enabled,
    required this.notification,
    required this.child,
  });

  final bool enabled;
  final AppNotification notification;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final l10n = context.l10n;
    Widget side(String text, Color color, Alignment alignment) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      color: color,
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.onAccent,
        ),
      ),
    );
    return Dismissible(
      key: ValueKey('swipe-${notification.id}'),
      direction: notification.isRead
          ? DismissDirection.endToStart
          : DismissDirection.horizontal,
      background: side(
        l10n.notificationsSwipeRead,
        AppColors.brandGreen,
        Alignment.centerLeft,
      ),
      secondaryBackground: side(
        l10n.notificationsSwipeDelete,
        AppColors.danger,
        Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        final store = context.read<NotificationsStore>();
        unawaited(HapticFeedback.selectionClick());
        if (direction == DismissDirection.startToEnd) {
          await store.markRead([notification.id]);
          return false; // stays, now read
        }
        return true;
      },
      onDismissed: (_) =>
          context.read<NotificationsStore>().delete([notification.id]),
      child: child,
    );
  }
}

/// Nothing here yet: what will appear under this filter, on a card.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final NotificationFilter filter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final (title, subtitle, icon) = switch (filter) {
      NotificationFilter.all => (
        l10n.notificationsTitle,
        l10n.notificationsEmptyAll,
        AppIcons.notificationsBlack,
      ),
      NotificationFilter.friends => (
        l10n.notificationsFilterFriends,
        l10n.notificationsEmptyFriends,
        AppIcons.profileMyFriends,
      ),
      NotificationFilter.capsules => (
        l10n.notificationsFilterCapsules,
        l10n.notificationsEmptyCapsules,
        AppIcons.profileMyCapsules,
      ),
      NotificationFilter.places => (
        l10n.notificationsFilterPlaces,
        l10n.notificationsEmptyPlaces,
        AppIcons.capsuleLocation,
      ),
    };
    return CardV2(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        children: [
          IdleFloat(child: Image.asset(icon, width: 56, height: 56)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              height: 1.3,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
