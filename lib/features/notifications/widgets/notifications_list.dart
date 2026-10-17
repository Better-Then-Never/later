import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/services/push_messaging_service.dart';
import '../../../shared/widgets/default_empty_inbox_info.dart';
import '../notification_router.dart';
import '../notifications_selection_controller.dart';
import '../notifications_store.dart';
import 'notification_item.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/social.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/styles/box_decorations.dart';
import '../../messages/chat_time.dart';
import '../../settings/settings_store.dart';
import 'notification_timestamp.dart';

/// The tabs of the notifications page. "Replies" and "Comments" exist in the
/// design but no feature produces those types yet (see IDEAS_NOT_DONE.md).
enum NotificationFilter {
  all,
  replies,
  comments;

  bool accepts(AppNotification n) => switch (this) {
    NotificationFilter.all => true,
    NotificationFilter.replies => n.type == NotificationType.reply,
    NotificationFilter.comments => n.type == NotificationType.comment,
  };
}

/// One row of the list: a day, a notification, or a word from the team.
sealed class _Entry {
  const _Entry();
}

class _Day extends _Entry {
  const _Day(this.label);
  final String label;
}

class _Note extends _Entry {
  const _Note(this.notification);
  final AppNotification notification;
}

class _News extends _Entry {
  const _News(this.announcement);
  final Announcement announcement;
}

/// The notifications of [filter], newest first under day headers (B6); on
/// "All" the Later team's announcements join them (unless the user turned
/// News off). A swipe right marks one read, left deletes it.
class NotificationsList extends StatefulWidget {
  const NotificationsList({
    super.key,
    required this.filter,
    required this.selection,
  });

  final NotificationFilter filter;
  final NotificationsSelectionController selection;

  @override
  State<NotificationsList> createState() => _NotificationsListState();
}

class _NotificationsListState extends State<NotificationsList> {
  NotificationFilter get filter => widget.filter;
  NotificationsSelectionController get selection => widget.selection;

  late final Stream<List<Announcement>> _news = context
      .read<SocialRepository>()
      .watchAnnouncements(limit: 10);

  static List<_Entry> entries(
    List<AppNotification> notes,
    List<Announcement> news,
    DateTime now,
    AppLocalizations l10n,
  ) {
    final timed = <(DateTime, _Entry)>[
      for (final n in notes) (n.timestamp ?? now, _Note(n)),
      for (final a in news) (a.createdAt ?? now, _News(a)),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    final out = <_Entry>[];
    String? day;
    for (final (time, entry) in timed) {
      final label = ChatTime.dayLabel(time, now, l10n: l10n);
      if (label != day) {
        out.add(_Day(label));
        day = label;
      }
      out.add(entry);
    }
    return out;
  }

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

    if (items.isEmpty && news.isEmpty) {
      // Pullable too: an empty list is when a fresh look helps most.
      return RefreshIndicator(
        color: context.palette.icon,
        onRefresh: () => context.read<NotificationsStore>().refresh(),
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: box.maxHeight,
              child: _EmptyState(filter: filter),
            ),
          ),
        ),
      );
    }

    final rows = entries(items, news, DateTime.now(), context.l10n);
    return ListenableBuilder(
      listenable: selection,
      builder: (context, _) {
        return RefreshIndicator(
          color: context.palette.icon,
          // The list is live; pulling listens again from scratch (a fresh
          // read, and the way out of a failed stream).
          onRefresh: () => context.read<NotificationsStore>().refresh(),
          child: AppStaggerScope(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: rows.length,
              itemBuilder: (context, index) => switch (rows[index]) {
                _Day(:final label) => _DayHeader(
                  key: ValueKey('day-$label'),
                  label: label,
                ),
                _News(:final announcement) => AppStaggerItem(
                  key: ValueKey('news-${announcement.id}'),
                  index: index,
                  child: _NewsItem(announcement: announcement),
                ),
                _Note(notification: final n) => AppStaggerItem(
                  key: ValueKey(n.id),
                  index: index,
                  child: _Swipe(
                    enabled: !selection.isSelectionMode,
                    notification: n,
                    child: NotificationItem(
                      notification: n,
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
                ),
              },
            ),
          ),
        );
      },
    );
  }

  void _open(BuildContext context, AppNotification n) {
    context.read<NotificationsStore>().markRead([n.id]);
    context.read<NotificationRouter>().handle(
      NotificationTap.fromNotification(n),
    );
  }
}

/// "Today", "Yesterday", or the date, above that day's rows.
class _DayHeader extends StatelessWidget {
  const _DayHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 2),
      child: Text(
        label,
        style: AppTextStyles.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: context.palette.textSecondary,
        ),
      ),
    ),
  );
}

/// A word from the Later team, in the app's language (English otherwise).
class _NewsItem extends StatelessWidget {
  const _NewsItem({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final lang = l10n.localeName;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecorations.whiteCard(context, borderRadius: 25),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(
              child: Image.asset(AppImages.laterLogo, width: 44, height: 44),
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
                      color: AppColors.brandGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    announcement.titleIn(lang),
                    style: AppTextStyles.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    announcement.bodyIn(lang),
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  NotificationTimestamp(
                    timestamp: announcement.createdAt ?? DateTime.now(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A notification that swipes: right marks it read (it springs back), left
/// deletes it.
class _Swipe extends StatelessWidget {
  const _Swipe({
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: kAppFontFamily,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final NotificationFilter filter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (filter) {
      NotificationFilter.replies => DefaultEmptyInboxInfo(
        message: l10n.notificationsTabReplies,
        subtitle: l10n.notificationsEmptyReplies,
        assetPath: AppIcons.reply,
      ),
      NotificationFilter.comments => DefaultEmptyInboxInfo(
        message: l10n.notificationsTabComments,
        subtitle: l10n.notificationsEmptyComments,
        assetPath: AppIcons.sendMessage,
      ),
      NotificationFilter.all => DefaultEmptyInboxInfo(
        message: l10n.notificationsTitle,
        subtitle: l10n.notificationsEmptyAll,
        assetPath: AppIcons.notificationsBlack,
      ),
    };
  }
}
