import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/session/session_controller.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/capsule.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../../map/widgets/capsule_preview_card.dart';
import 'capsule_social_controller.dart';
import 'capsule_social_panel.dart';

/// An opened capsule over the current screen: the photo card and, below it,
/// reactions and comments (when the capsule is open and allows them).
abstract final class CapsuleDetailDialog {
  static Future<void> show(
    BuildContext context,
    Capsule capsule, {
    VoidCallback? onPlaceTap,
  }) {
    final uid = context.read<SessionController>().uid;
    final social = context.read<SocialRepository>();
    final withSocial =
        uid != null &&
        capsule.isOpen(DateTime.now()) &&
        CapsuleSocialPanel.showsAnything(capsule);
    // The card route: rises and grows in, closes on a tap outside or a drag
    // down (MOTION_CATALOG.md).
    return Navigator.of(context).push(
      AppCardRoute<void>(
        barrierColor: context.palette.scrim,
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
        builder: (dialogContext) => Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CapsulePreviewCard(
                  capsule: capsule,
                  onPlaceTap: onPlaceTap == null
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                          onPlaceTap();
                        },
                ),
                if (withSocial) ...[
                  const SizedBox(height: 8),
                  ChangeNotifierProvider(
                    create: (_) => CapsuleSocialController(
                      capsule: capsule,
                      uid: uid,
                      social: social,
                    ),
                    child: Builder(
                      builder: (context) => CapsuleSocialPanel(
                        controller: context.read<CapsuleSocialController>(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
