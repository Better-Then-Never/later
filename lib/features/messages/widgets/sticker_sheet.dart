import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/session/session_controller.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/preferences_store.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../../../shared/widgets/buttons/default_icon_button.dart';

/// Big emoji to send in one tap, like stickers: the ones used lately, then
/// five groups. Resolves to the chosen emoji, or null.
class StickerSheet extends StatefulWidget {
  const StickerSheet({super.key});

  static Future<String?> show(BuildContext context) =>
      showEdgeSheet<String>(context, (_) => const StickerSheet());

  /// The groups, in order: faces, hands, hearts and parties, places and
  /// things, nature.
  static const groups = [
    [
      '😀',
      '😂',
      '🥹',
      '😍',
      '🥰',
      '😘',
      '😎',
      '🤩',
      '🥳',
      '😴',
      '🤔',
      '😅',
      '😭',
      '😡',
      '😱',
      '🤯',
      '🙃',
      '😇',
    ],
    ['👍', '👎', '👏', '🙌', '🙏', '💪', '🤝', '👋', '✌️', '🤞', '👌', '🫶'],
    [
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🖤',
      '💔',
      '🎉',
      '🎂',
      '🎁',
      '🎈',
      '✨',
      '🔥',
      '⭐',
      '💯',
    ],
    [
      '📸',
      '🗺️',
      '📍',
      '⏳',
      '🕰️',
      '🏖️',
      '🏔️',
      '🌅',
      '🌃',
      '✈️',
      '🚗',
      '🏠',
      '☕',
      '🍕',
      '🍿',
      '🎵',
    ],
    ['🌸', '🌻', '🌈', '☀️', '🌙', '❄️', '🌊', '🍀', '🐶', '🐱', '🦊', '🐻'],
  ];

  static const _recentKey = 'recent_stickers';
  static const _recentMax = 16;

  @override
  State<StickerSheet> createState() => _StickerSheetState();
}

class _StickerSheetState extends State<StickerSheet> {
  List<String> _recent = const [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final uid = context.read<SessionController>().uid;
    if (uid == null) return;
    final saved = await context.read<PreferencesStore>().string(
      uid,
      StickerSheet._recentKey,
    );
    if (!mounted || saved == null || saved.isEmpty) return;
    setState(() => _recent = saved.split('\n'));
  }

  void _pick(String emoji) {
    HapticFeedback.selectionClick();
    final uid = context.read<SessionController>().uid;
    if (uid != null) {
      final recent = [
        emoji,
        ..._recent.where((e) => e != emoji),
      ].take(StickerSheet._recentMax).join('\n');
      context.read<PreferencesStore>().setString(
        uid,
        StickerSheet._recentKey,
        recent,
      );
    }
    Navigator.of(context).pop(emoji);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final palette = context.palette;
    final l10n = context.l10n;
    final titles = [
      l10n.messagesStickersFaces,
      l10n.messagesStickersHands,
      l10n.messagesStickersHearts,
      l10n.messagesStickersPlaces,
      l10n.messagesStickersNature,
    ];
    final sections = [
      if (_recent.isNotEmpty) (l10n.messagesStickersRecent, _recent),
      for (var i = 0; i < StickerSheet.groups.length; i++)
        (titles[i], StickerSheet.groups[i]),
    ];

    return Container(
      height: screen.height * 0.6,
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
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(width: double.infinity, height: 48),
                    Text(
                      l10n.messagesStickers,
                      style: AppTextStyles.pageTitle(
                        context,
                      ).copyWith(fontSize: screen.height * 0.026),
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
                const SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                for (final (title, emoji) in sections) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        title,
                        style: AppTextStyles.body.copyWith(
                          color: palette.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverGrid.count(
                      crossAxisCount: 6,
                      children: [
                        for (final e in emoji)
                          Semantics(
                            button: true,
                            label: e,
                            child: AppPressable(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _pick(e),
                                child: Center(
                                  child: ExcludeSemantics(
                                    child: Text(
                                      e,
                                      style: const TextStyle(fontSize: 34),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.paddingOf(context).bottom + 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
