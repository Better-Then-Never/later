import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/session/session_controller.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/capsule.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../opening/capsule_locks.dart';
import '../opening/capsule_openings.dart';
import '../opening/capsule_wrap.dart';
import 'capsule_comments_sheet.dart';
import 'capsule_sheet.dart';
import 'capsule_social_controller.dart';

/// An opened capsule over the current screen (capsule v3): a sheet from the
/// bottom with the photo, the words, reactions and comments (when the capsule
/// is open and allows them) and its actions. The first time, it arrives
/// wrapped (D1); not when it is opened for its comments (from a comment
/// notification, so it was seen before).
abstract final class CapsuleDetailDialog {
  static Future<void> show(
    BuildContext context,
    Capsule capsule, {
    SheetOrigin? from,
    VoidCallback? onPlaceTap,
    bool openComments = false,
  }) async {
    // A locked capsule's photo and words once it may open (capsule v3 B3):
    // at once when this phone has them already.
    final locks = CapsuleLocks.maybeOf(context, listen: false);
    final shown = locks == null ? capsule : await locks.fill(capsule);
    if (!context.mounted) return;
    return _show(
      context,
      shown,
      open:
          locks?.mayOpen(shown, DateTime.now()) ?? shown.isOpen(DateTime.now()),
      from: from,
      onPlaceTap: onPlaceTap,
      openComments: openComments,
    );
  }

  static Future<void> _show(
    BuildContext context,
    Capsule capsule, {
    required bool open,
    SheetOrigin? from,
    VoidCallback? onPlaceTap,
    bool openComments = false,
  }) {
    final uid = context.read<SessionController>().uid;
    final social = context.read<SocialRepository>();
    final withSocial =
        uid != null && open && CapsuleSheet.showsAnything(capsule);
    // Someone else's open capsule counts for "Curious" (B7), once.
    if (FeatureFlags.achievements &&
        uid != null &&
        capsule.ownerId != uid &&
        !capsule.coAuthors.contains(uid) &&
        open) {
      unawaited(social.markViewed(uid, capsule.id));
    }
    final openings = context.read<CapsuleOpenings>();
    final wrapped =
        !openComments && openings.isWrapped(capsule, uid, DateTime.now());
    // The sheet route: rises from the bottom edge, or grows out of the
    // tapped photo [from] (not under the wrapping); closes on a tap above it
    // or a drag down (MOTION_CATALOG.md).
    return Navigator.of(context).push(
      AppSheetRoute<void>(
        origin: wrapped ? null : from,
        barrierColor: context.palette.scrim,
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
        builder: (sheetContext) {
          final onPlace = onPlaceTap == null
              ? null
              : () {
                  Navigator.of(sheetContext).pop();
                  onPlaceTap();
                };
          final sheet = withSocial
              ? _social(capsule, uid, social, openComments, onPlace)
              : CapsuleSheet(capsule: capsule, onPlaceTap: onPlace);
          if (!wrapped) return sheet;
          return CapsuleWrapHost(
            capsule: capsule,
            radius: CapsuleSheet.radius,
            onOpened: () => unawaited(openings.markOpened(uid!, capsule.id)),
            child: sheet,
          );
        },
      ),
    );
  }

  /// The sheet with its reactions and comments.
  static Widget _social(
    Capsule capsule,
    String uid,
    SocialRepository social,
    bool openComments,
    VoidCallback? onPlace,
  ) => ChangeNotifierProvider(
    create: (_) =>
        CapsuleSocialController(capsule: capsule, uid: uid, social: social),
    child: Builder(
      builder: (context) => _CommentsOnOpen(
        open: openComments,
        child: CapsuleSheet(
          capsule: capsule,
          controller: context.read<CapsuleSocialController>(),
          onPlaceTap: onPlace,
        ),
      ),
    ),
  );
}

/// Opens the comments once the dialog is up, when it was opened for them
/// (a tap on a comment or reply notification).
class _CommentsOnOpen extends StatefulWidget {
  const _CommentsOnOpen({required this.open, required this.child});

  final bool open;
  final Widget child;

  @override
  State<_CommentsOnOpen> createState() => _CommentsOnOpenState();
}

class _CommentsOnOpenState extends State<_CommentsOnOpen> {
  bool _started = false;

  // Not initState: the wait reads the motion setting from MediaQuery.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !widget.open) return;
    _started = true;
    final controller = context.read<CapsuleSocialController>();
    if (!(FeatureFlags.comments && controller.capsule.allowComments)) return;
    // After the card has risen (its route animation).
    Future<void>.delayed(AppMotion.of(context, AppMotion.emphasized), () {
      if (mounted) CapsuleCommentsSheet.show(context, controller);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
