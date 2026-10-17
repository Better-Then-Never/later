import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/chat.dart';
import '../../../data/models/user_profile.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/styles/box_decorations.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../../../shared/widgets/buttons/default_icon_button.dart';
import '../../../shared/widgets/default_empty_inbox_info.dart';
import '../../../shared/widgets/default_search_bar.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../../shared/widgets/user/user_list_tile.dart';
import '../../friends/friends_store.dart';
import '../../users/user_directory.dart';

/// What [GroupFriendsPicker] resolves to: the group's name (empty when not
/// asked for) and the friends picked.
typedef GroupPick = ({String name, List<String> friends});

/// Friends to pick for a group: for a new one ([withName]: a name field
/// too), or to add to one ([exclude]: already in it; [room]: places left).
/// Also picks a capsule's co-authors ([initial], [allowEmpty]).
class GroupFriendsPicker extends StatefulWidget {
  const GroupFriendsPicker({
    super.key,
    required this.title,
    required this.actionText,
    this.withName = false,
    this.exclude = const {},
    this.room = Chat.maxGroupMembers - 1,
    this.initial = const {},
    this.allowEmpty = false,
    this.tooManyText,
  });

  final String title;
  final String actionText;
  final bool withName;
  final Set<String> exclude;
  final int room;

  /// Picked when the sheet opens.
  final Set<String> initial;

  /// Done with nobody picked is an answer (clears the pick).
  final bool allowEmpty;

  /// Said when [room] is full (the group's limit otherwise).
  final String? tooManyText;

  /// The pick, or null when the sheet is dismissed.
  static Future<GroupPick?> show(
    BuildContext context, {
    required String title,
    required String actionText,
    bool withName = false,
    Set<String> exclude = const {},
    int room = Chat.maxGroupMembers - 1,
    Set<String> initial = const {},
    bool allowEmpty = false,
    String? tooManyText,
  }) => showEdgeSheet<GroupPick>(
    context,
    (_) => GroupFriendsPicker(
      title: title,
      actionText: actionText,
      withName: withName,
      exclude: exclude,
      room: room,
      initial: initial,
      allowEmpty: allowEmpty,
      tooManyText: tooManyText,
    ),
  );

  @override
  State<GroupFriendsPicker> createState() => _GroupFriendsPickerState();
}

class _GroupFriendsPickerState extends State<GroupFriendsPicker> {
  final _name = TextEditingController();
  final _search = TextEditingController();
  final Set<String> _picked = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _picked.addAll(widget.initial);
  }

  @override
  void dispose() {
    _name.dispose();
    _search.dispose();
    super.dispose();
  }

  bool _matches(UserProfile? p) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (p == null) return false;
    return p.name.toLowerCase().contains(q) ||
        p.username.toLowerCase().contains(q);
  }

  void _toggle(String uid) {
    final l10n = context.l10n;
    if (!_picked.contains(uid) && _picked.length >= widget.room) {
      PopupNotificationService.showError(
        context: context,
        message: widget.tooManyText ?? l10n.messagesGroupTooMany,
        position: NotificationPosition.top,
      );
      return;
    }
    HapticFeedback.selectionClick();
    setState(
      () => _picked.contains(uid) ? _picked.remove(uid) : _picked.add(uid),
    );
  }

  void _done() {
    final l10n = context.l10n;
    final name = _name.text.trim();
    final problem = widget.withName && name.isEmpty
        ? l10n.messagesGroupNeedsName
        : _picked.isEmpty && !widget.allowEmpty
        ? l10n.messagesGroupNeedsPeople
        : null;
    if (problem != null) {
      PopupNotificationService.showError(
        context: context,
        message: problem,
        position: NotificationPosition.top,
      );
      return;
    }
    Navigator.of(
      context,
    ).pop<GroupPick>((name: name, friends: _picked.toList()));
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final friends = context.watch<FriendsStore>();
    final directory = context.watch<UserDirectory>();
    final l10n = context.l10n;
    final palette = context.palette;

    final ids =
        [
          for (final id in friends.friendIds)
            if (!widget.exclude.contains(id) && _matches(directory.profile(id)))
              id,
        ]..sort(
          (a, b) => (directory.profile(a)?.name ?? '').toLowerCase().compareTo(
            (directory.profile(b)?.name ?? '').toLowerCase(),
          ),
        );

    return Container(
      height: screen.height * 0.85,
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSheets.radius),
        ),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppSheets.radius),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: screen.width * 0.04),
            child: Column(
              children: [
                const SheetHandle(),
                SizedBox(height: screen.height * 0.008),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(width: double.infinity),
                    Text(
                      widget.title,
                      style: AppTextStyles.pageTitle(
                        context,
                      ).copyWith(fontSize: screen.height * 0.03),
                    ),
                    Positioned(
                      right: 0,
                      child: DefaultIconButton(
                        onTap: () => Navigator.of(context).pop(),
                        assetPath: AppIcons.capsuleClose,
                        semanticLabel: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        size: screen.width * 0.08,
                      ),
                    ),
                  ],
                ),
                if (widget.withName) ...[
                  SizedBox(height: screen.height * 0.012),
                  _NameField(controller: _name),
                ],
                SizedBox(height: screen.height * 0.012),
                DefaultSearchBar(
                  controller: _search,
                  hintText: l10n.messagesNewChatSearchHint,
                  onChanged: (value) => setState(() => _query = value),
                ),
                SizedBox(height: screen.height * 0.012),
              ],
            ),
          ),
          // Under a name field it says who; otherwise the title already does.
          if (widget.withName)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.messagesGroupWho,
                  style: AppTextStyles.body.copyWith(
                    color: palette.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 12),
          Expanded(
            child: ids.isEmpty
                ? DefaultEmptyInboxInfo(
                    message: friends.friendIds.isEmpty
                        ? l10n.messagesNewChatNoFriends
                        : l10n.messagesNewChatNoMatch,
                    subtitle: friends.friendIds.isEmpty
                        ? l10n.messagesNewChatNoFriendsSubtitle
                        : l10n.messagesNothingMatches(_query),
                    assetPath: AppIcons.profileMyFriends,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    itemCount: ids.length,
                    itemBuilder: (context, index) {
                      final id = ids[index];
                      final profile = directory.profile(id);
                      final picked = _picked.contains(id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DecoratedBox(
                          decoration: BoxDecorations.whiteCard(context),
                          child: Semantics(
                            checked: picked,
                            child: UserListTile(
                              uid: id,
                              name: profile?.name ?? '',
                              username: profile?.username ?? '',
                              screenWidth: screen.width,
                              onTap: () => _toggle(id),
                              trailing: _PickMark(picked: picked),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: _ActionButton(
                text: _picked.isEmpty
                    ? widget.actionText
                    : '${widget.actionText} (${_picked.length})',
                onTap: _done,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSheets.radius),
      ),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.sentences,
        inputFormatters: [LengthLimitingTextInputFormatter(Chat.maxGroupName)],
        style: TextStyle(
          fontFamily: kAppFontFamily,
          fontSize: 17,
          color: palette.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: context.l10n.messagesGroupName,
          hintStyle: TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 17,
            color: palette.textMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 13,
          ),
        ),
      ),
    );
  }
}

/// A round mark: an empty ring, or filled green with a check when picked.
class _PickMark extends StatelessWidget {
  const _PickMark({required this.picked});

  final bool picked;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.fast),
      curve: AppMotion.standardCurve,
      width: 26,
      height: 26,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: picked ? AppColors.brandGreen : Colors.transparent,
        border: Border.all(
          color: picked ? AppColors.brandGreen : context.palette.iconMuted,
          width: 2,
        ),
      ),
      child: picked
          ? const CustomPaint(painter: _CheckPainter(color: AppColors.onAccent))
          : null,
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.27, h * 0.52)
        ..lineTo(w * 0.44, h * 0.68)
        ..lineTo(w * 0.74, h * 0.36),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: AppPressable(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brandGreen,
              borderRadius: BorderRadius.circular(AppSheets.radius),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
