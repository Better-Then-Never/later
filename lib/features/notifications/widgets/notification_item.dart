import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/models/friend_request.dart';
import '../../../shared/widgets/pill_v2.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../friends/friend_actions.dart';
import '../../friends/friends_store.dart';
import '../../users/user_directory.dart';
import '../notification_texts.dart';
import 'notification_leading.dart';
import 'notification_thumbnail.dart';
import 'notification_timestamp.dart';
import 'notification_unread_indicator.dart';

/// One row of a notifications card (Profile v4): who or what it is about,
/// the sentence with the name in bold, the time, the capsule's photo on the
/// right. Unread rows are tinted and carry a blue dot.
class NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// The row's place in its card: stamps tilt -4 and +3 degrees in turn.
  final int index;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    this.index = 0,
  });

  /// Where the hairlines between rows start: past the 44 dp stamp.
  static const hairlineIndent = 16.0 + NotificationLeading.size + 12;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final n = notification;
    final thumbnail = n.thumbnailImageUrl;
    final followBack =
        !selectionMode &&
        n.type == NotificationType.follow &&
        (n.fromUserId?.isNotEmpty ?? false);
    return Material(
      color: isSelected
          ? palette.selectedHighlight
          : n.isRead
          ? Colors.transparent
          : palette.unreadHighlight,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              NotificationLeading(notification: n, tilt: index.isEven ? -4 : 3),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Sentence(notification: n),
                    const SizedBox(height: 2),
                    NotificationTimestamp(
                      // Null only while the server timestamp is pending.
                      timestamp: n.timestamp ?? DateTime.now(),
                    ),
                    // A friend request: answered right here (B6).
                    if (!selectionMode &&
                        n.type == NotificationType.friendRequest &&
                        n.fromUserId != null)
                      _RequestAnswer(from: n.fromUserId!),
                  ],
                ),
              ),
              if (followBack) ...[
                const SizedBox(width: 8),
                _FollowBack(userId: n.fromUserId!),
              ] else if (thumbnail != null &&
                  thumbnail.isNotEmpty &&
                  !NotificationLeading.showsCapsulePhoto(n)) ...[
                const SizedBox(width: 12),
                NotificationThumbnail(thumbnailImage: thumbnail, size: 40),
              ],
              if (selectionMode)
                const SizedBox(width: 8)
              else
                NotificationUnreadIndicator(isRead: n.isRead),
            ],
          ),
        ),
      ),
    );
  }
}

/// The sentence in the app's language with the sender's name in bold
/// wherever the language puts it.
class _Sentence extends StatelessWidget {
  const _Sentence({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final sentence = NotificationTexts.sentence(n, l10n: context.l10n);
    // Newer notifications store only the sender's id: their current name.
    final senderId = n.fromUserId;
    final looked = context.select<UserDirectory, String?>(
      (d) => n.fromUserName.isEmpty && senderId != null
          ? d.profile(senderId)?.name
          : null,
    );
    final name = n.fromUserName.isNotEmpty ? n.fromUserName : looked ?? '';
    return RichText(
      textScaler: MediaQuery.textScalerOf(context),
      text: TextSpan(
        style: AppTextStyles.body.copyWith(
          fontSize: 15,
          height: 1.3,
          color: context.palette.textPrimary,
        ),
        children: [
          if (sentence.before.isNotEmpty) TextSpan(text: sentence.before),
          TextSpan(
            text: name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: sentence.after),
        ],
      ),
    );
  }
}

/// "Follow back" on a "started following you" row while this user does not
/// follow them; "Following" once they do from here.
class _FollowBack extends StatefulWidget {
  const _FollowBack({required this.userId});

  final String userId;

  @override
  State<_FollowBack> createState() => _FollowBackState();
}

class _FollowBackState extends State<_FollowBack> {
  /// Null until known.
  bool? _following;
  bool _followedHere = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final following = await context.read<FriendsStore>().isFollowing(
      widget.userId,
    );
    if (mounted) setState(() => _following = following);
  }

  Future<void> _follow() async {
    final store = context.read<FriendsStore>();
    if (store.isBusy(widget.userId)) return;
    final failure = await store.follow(widget.userId);
    if (!mounted) return;
    if (failure != null) {
      PopupNotificationService.showError(
        context: context,
        message: failure.message,
        position: NotificationPosition.bottom,
      );
      return;
    }
    setState(() {
      _following = true;
      _followedHere = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_followedHere) {
      return PillV2(
        label: l10n.friendsFollowing,
        kind: PillV2Kind.outline,
        size: PillV2Size.small,
      );
    }
    if (_following != false) return const SizedBox.shrink();
    return PillV2(
      label: l10n.notificationsFollowBack,
      kind: PillV2Kind.soft,
      size: PillV2Size.small,
      onTap: _follow,
    );
  }
}

/// Accept or reject a friend request from its notification; afterwards
/// what came of it.
class _RequestAnswer extends StatelessWidget {
  const _RequestAnswer({required this.from});

  final String from;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final relation = context.select<FriendsStore, FriendRelation>(
      (s) => s.relationTo(from),
    );
    final busy = context.select<FriendsStore, bool>((s) => s.isBusy(from));
    if (relation == FriendRelation.friends) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          l10n.notificationsNowFriends,
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: context.palette.accentText,
          ),
        ),
      );
    }
    if (relation != FriendRelation.requestReceived) return const SizedBox();
    final actions = FriendActions(
      context,
      position: NotificationPosition.bottom,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          PillV2(
            label: l10n.friendsAccept,
            size: PillV2Size.small,
            onTap: busy ? null : () => actions.acceptRequest(from),
          ),
          PillV2(
            label: l10n.friendsReject,
            kind: PillV2Kind.outline,
            size: PillV2Size.small,
            onTap: busy ? null : () => actions.rejectRequest(from),
          ),
        ],
      ),
    );
  }
}
