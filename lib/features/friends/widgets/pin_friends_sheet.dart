import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../../../shared/widgets/default_search_bar.dart';
import '../../../shared/widgets/pill_v2.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../users/user_directory.dart';
import '../pinned_friends_controller.dart';
import 'friend_stamp.dart';

/// "Pin to your profile" (Figma page 14, `7190:1239`): a grid of the
/// friends' stamps; tapping one pins it at the end or unpins it, a pinned
/// one carries its place in the order. Pops with the chosen uids on Done
/// (null when dismissed).
class PinFriendsSheet extends StatefulWidget {
  const PinFriendsSheet({
    super.key,
    required this.pinned,
    required this.friends,
    this.limit = PinnedFriendsController.maxPinned,
  });

  /// The pins when the sheet opens, in their order.
  final List<String> pinned;
  final List<String> friends;
  final int limit;

  /// Opens the sheet for [controller]'s friends and saves the choice.
  static Future<void> open(
    BuildContext context,
    PinnedFriendsController controller,
  ) async {
    final friends = controller.allFriends.toList();
    // One batched lookup for the names shown in the sheet.
    await context.read<UserDirectory>().resolveAll(friends);
    if (!context.mounted) return;
    final before = controller.pinnedUids;
    final chosen = await showEdgeSheet<List<String>>(
      context,
      (_) => PinFriendsSheet(pinned: before, friends: friends),
    );
    if (chosen == null || listEquals(chosen, before) || !context.mounted) {
      return;
    }
    final failure = await controller.setPinnedFriends(chosen);
    if (!context.mounted) return;
    reportPinResult(context, failure, context.l10n.profilePinnedUpdated);
  }

  @override
  State<PinFriendsSheet> createState() => _PinFriendsSheetState();
}

/// The success or error toast after pins changed.
void reportPinResult(BuildContext context, AppFailure? failure, String done) {
  failure == null
      ? PopupNotificationService.showSuccess(
          context: context,
          message: done,
          position: NotificationPosition.top,
        )
      : PopupNotificationService.showError(
          context: context,
          message: failure.message,
          position: NotificationPosition.top,
        );
}

/// Pins or unpins [uid] from anywhere (a friend's menu) and says so.
Future<void> togglePinnedFriend(
  BuildContext context,
  PinnedFriendsController controller,
  String uid,
) async {
  final l10n = context.l10n;
  final name = context.read<UserDirectory>().profile(uid)?.name ?? '';
  final pinned = controller.isPinned(uid);
  unawaited(HapticFeedback.selectionClick());
  final failure = await controller.togglePin(uid);
  if (!context.mounted) return;
  reportPinResult(
    context,
    failure,
    pinned ? l10n.profileUnpinned(name) : l10n.profilePinned(name),
  );
}

class _PinFriendsSheetState extends State<PinFriendsSheet> {
  late final List<String> _pinned = List.of(widget.pinned);
  final _search = TextEditingController();
  String _query = '';

  /// Pinned first in their order, then everyone A to Z; the order stays put
  /// while the user taps.
  late final List<String> _order = _initialOrder();

  List<String> _initialOrder() {
    final directory = context.read<UserDirectory>();
    String name(String uid) =>
        (directory.profile(uid)?.name ?? '').toLowerCase();
    final rest =
        widget.friends.where((uid) => !widget.pinned.contains(uid)).toList()
          ..sort((a, b) => name(a).compareTo(name(b)));
    return [
      for (final uid in widget.pinned)
        if (widget.friends.contains(uid)) uid,
      ...rest,
    ];
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(String uid) {
    if (_pinned.contains(uid)) {
      setState(() => _pinned.remove(uid));
      return;
    }
    if (_pinned.length >= widget.limit) {
      PopupNotificationService.showError(
        context: context,
        message: context.l10n.profilePinLimit(widget.limit),
        position: NotificationPosition.top,
      );
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    setState(() => _pinned.add(uid));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final directory = context.watch<UserDirectory>();
    final shown = _order.where((uid) {
      if (_query.isEmpty) return true;
      final p = directory.profile(uid);
      if (p == null) return false;
      return p.name.toLowerCase().contains(_query) ||
          p.username.toLowerCase().contains(_query);
    }).toList();
    final screen = MediaQuery.sizeOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        height: screen.height * 0.72,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: SheetHandle.v2()),
                Text(
                  l10n.friendsPinSheetTitle,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: palette.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.friendsPinSheetCount(_pinned.length, widget.limit),
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                DefaultSearchBar(
                  controller: _search,
                  hintText: l10n.friendsPinSheetSearch,
                  onChanged: (q) =>
                      setState(() => _query = q.trim().toLowerCase()),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 8,
                          mainAxisExtent: 100,
                        ),
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final uid = shown[i];
                      final at = _pinned.indexOf(uid);
                      return _PinTile(
                        key: ValueKey(uid),
                        uid: uid,
                        name: directory.profile(uid)?.name ?? '',
                        order: at < 0 ? null : at + 1,
                        tilt: FriendStamp.tiltAt(i),
                        onTap: () => _toggle(uid),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: PillV2(
                    label: l10n.friendsDone,
                    onTap: () => Navigator.pop(context, List.of(_pinned)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinTile extends StatelessWidget {
  const _PinTile({
    super.key,
    required this.uid,
    required this.name,
    required this.order,
    required this.tilt,
    required this.onTap,
  });

  final String uid;
  final String name;

  /// The place among the pins (1 is first); null when not pinned.
  final int? order;
  final double tilt;
  final VoidCallback onTap;

  static const _stamp = 58.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final first = name.trim().split(RegExp(r'\s+')).first;
    final pinned = order != null;
    return Semantics(
      button: true,
      selected: pinned,
      label: name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ExcludeSemantics(
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  FriendStamp(userId: uid, size: _stamp, tilt: tilt),
                  if (order case final n?)
                    Positioned(
                      top: -2,
                      right: -6,
                      child: _OrderBadge(number: n),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  fontWeight: pinned ? FontWeight.bold : FontWeight.normal,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The green round number on a pinned stamp.
class _OrderBadge extends StatelessWidget {
  const _OrderBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.brandGreen,
      shape: BoxShape.circle,
      border: Border.all(color: context.palette.surface, width: 2),
    ),
    child: Text(
      '$number',
      style: AppTextStyles.body.copyWith(
        fontSize: 11,
        height: 1,
        fontWeight: FontWeight.bold,
        color: AppColors.onAccent,
      ),
    ),
  );
}
