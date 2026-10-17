import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/session/session_controller.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/capsule.dart';
import '../../../data/repositories/repositories.dart';
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
    return showDialog<void>(
      context: context,
      barrierColor: context.palette.scrim,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
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
    );
  }
}
