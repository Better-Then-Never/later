import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/assets/app_assets.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/world.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/page_header.dart';
import '../passport/passport_book.dart';
import '../users/user_directory.dart';

/// The Passport (B7, Profile v4): a booklet of the places where [uid] left
/// capsules, from the summary the functions keep (one read; with
/// [viewerUid], the viewer's too). Country names come from the phone in
/// the app's language. The share button sends the open page as a picture.
class WorldPage extends StatefulWidget {
  const WorldPage({
    super.key,
    required this.uid,
    this.viewerUid,
    this.focusTown,
  });

  final String uid;

  /// The signed-in user when [uid] is a friend: the Passport then opens at
  /// "You and" the friend.
  final String? viewerUid;

  /// A town just stamped (the new-stamp moment): the Passport opens at the
  /// page of its stamp.
  final String? focusTown;

  @override
  State<WorldPage> createState() => _WorldPageState();
}

class _WorldPageState extends State<WorldPage> {
  final _book = GlobalKey<PassportBookState>();
  late final Stream<WorldSummary> _world;
  Stream<WorldSummary>? _mine;

  /// The viewer when this is a friend's Passport.
  String? get _viewer {
    final viewer = widget.viewerUid;
    return viewer == null || viewer == widget.uid ? null : viewer;
  }

  @override
  void initState() {
    super.initState();
    final social = context.read<SocialRepository>();
    _world = social.watchWorld(widget.uid);
    final viewer = _viewer;
    if (viewer != null) _mine = social.watchWorld(viewer);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final viewer = _viewer;
    final first = context.select<UserDirectory, String>(
      (d) => (d.profile(widget.uid)?.name ?? '').trim().split(' ').first,
    );
    final title = viewer == null || first.isEmpty
        ? l10n.worldTitle
        : l10n.profileFriendPassport(first);
    return Scaffold(
      backgroundColor: palette.backgroundAlt,
      body: Column(
        children: [
          Stack(
            children: [
              PageHeaderV2(
                title: title,
                onBack: () => Navigator.of(context).maybePop(),
                backLabel: l10n.commonBack,
              ),
              Positioned(
                right: 11,
                top: MediaQuery.viewPaddingOf(context).top + 6,
                height: 44,
                child: Semantics(
                  button: true,
                  label: l10n.passportShare,
                  excludeSemantics: true,
                  child: InkResponse(
                    onTap: () => _book.currentState?.share(),
                    radius: 24,
                    child: SizedBox(
                      width: 44,
                      child: Center(
                        child: Image.asset(AppIcons.shareBlack, width: 26),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<WorldSummary>(
              stream: _world,
              builder: (context, snap) {
                final world = snap.data;
                if (world == null) return const SizedBox.shrink();
                final mine = _mine;
                if (mine == null || viewer == null) {
                  return PassportBook(
                    key: _book,
                    uid: widget.uid,
                    world: world,
                    focusTown: widget.focusTown,
                  );
                }
                return StreamBuilder<WorldSummary>(
                  stream: mine,
                  builder: (context, snap) {
                    final myWorld = snap.data;
                    if (myWorld == null) return const SizedBox.shrink();
                    return PassportBook(
                      key: _book,
                      uid: widget.uid,
                      world: world,
                      viewerUid: viewer,
                      viewerWorld: myWorld,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
