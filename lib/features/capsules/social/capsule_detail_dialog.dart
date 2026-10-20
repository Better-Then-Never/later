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
import 'capsule_comments_sheet.dart';
import 'capsule_sheet.dart';
import 'capsule_social_controller.dart';

/// An opened capsule over the current screen (capsule v3): a sheet from the
/// bottom with the photo, the words, reactions and comments (when the capsule
/// is open and allows them) and its actions.
abstract final class CapsuleDetailDialog {
  static Future<void> show(
    BuildContext context,
    Capsule capsule, {
    VoidCallback? onPlaceTap,
    bool openComments = false,
  }) {
    final uid = context.read<SessionController>().uid;
    final social = context.read<SocialRepository>();
    final withSocial =
        uid != null &&
        capsule.isOpen(DateTime.now()) &&
        CapsuleSheet.showsAnything(capsule);
    // Someone else's open capsule counts for "Curious" (B7), once.
    if (FeatureFlags.achievements &&
        uid != null &&
        capsule.ownerId != uid &&
        !capsule.coAuthors.contains(uid) &&
        capsule.isOpen(DateTime.now())) {
      unawaited(social.markViewed(uid, capsule.id));
    }
    // The sheet route: rises from the bottom edge, closes on a tap above it
    // or a drag down (MOTION_CATALOG.md).
    return Navigator.of(context).push(
      AppSheetRoute<void>(
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
          if (!withSocial) {
            return CapsuleSheet(capsule: capsule, onPlaceTap: onPlace);
          }
          return ChangeNotifierProvider(
            create: (_) => CapsuleSocialController(
              capsule: capsule,
              uid: uid,
              social: social,
            ),
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
        },
      ),
    );
  }
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
