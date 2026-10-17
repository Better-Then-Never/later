import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../data/models/social.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/motion/reaction_burst.dart';
import '../../../shared/widgets/options_menu.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import 'capsule_comments_sheet.dart';
import 'capsule_social_controller.dart';

/// Under an open capsule: the six reactions and the way into its comments
/// (F-50). Shown only for what the author allowed and the features that are
/// switched on.
class CapsuleSocialPanel extends StatelessWidget {
  const CapsuleSocialPanel({super.key, required this.controller});

  final CapsuleSocialController controller;

  static bool showsAnything(Capsule capsule) =>
      (FeatureFlags.reactions && capsule.allowReactions) ||
      (FeatureFlags.comments && capsule.allowComments);

  @override
  Widget build(BuildContext context) {
    final capsule = controller.capsule;
    final palette = context.palette;
    final reactions = FeatureFlags.reactions && capsule.allowReactions;
    final comments = FeatureFlags.comments && capsule.allowComments;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.lCircular,
        border: palette.isDark ? Border.all(color: palette.cardBorder) : null,
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reactions) CapsuleReactionsBar(controller: controller),
            if (comments || !controller.isOwner)
              Row(
                children: [
                  if (comments)
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: palette.textPrimary,
                          alignment: Alignment.centerLeft,
                        ),
                        onPressed: () =>
                            CapsuleCommentsSheet.show(context, controller),
                        child: Text(
                          context.l10n.capsulesCommentsCount(
                            controller.commentCount,
                          ),
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (!controller.isOwner)
                    IconButton(
                      tooltip: context.l10n.capsulesReportCapsule,
                      onPressed: () => _capsuleMenu(context),
                      icon: Image.asset(AppIcons.openMenu, width: 24),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _capsuleMenu(BuildContext context) async {
    final l10n = context.l10n;
    final report = await showCenteredSheet<bool>(
      context,
      OptionsMenu(
        children: [
          OptionsMenuItem(
            text: l10n.capsulesReportCapsule,
            textColor: AppColors.danger,
            isFirst: true,
            isLast: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (report != true || !context.mounted) return;
    await reportFlow(
      context,
      controller,
      target: ReportTarget.capsule,
      targetPath: 'capsules/${controller.capsule.id}',
    );
  }
}

/// Asks why, sends the report, thanks the user.
Future<void> reportFlow(
  BuildContext context,
  CapsuleSocialController controller, {
  required ReportTarget target,
  required String targetPath,
}) async {
  final reason = await pickReportReason(context);
  if (reason == null || !context.mounted) return;
  final failure = await controller.report(
    target: target,
    targetPath: targetPath,
    reason: reason,
  );
  if (context.mounted) showReportResult(context, failure);
}

/// Thanks the user, or says why the report did not go.
void showReportResult(BuildContext context, AppFailure? failure) {
  if (failure != null) {
    PopupNotificationService.showError(
      context: context,
      message: failure.message,
      position: NotificationPosition.bottom,
    );
  } else {
    PopupNotificationService.showSuccess(
      context: context,
      message: context.l10n.capsulesReportSent,
      position: NotificationPosition.bottom,
    );
  }
}

/// Why the user reports something (a capsule, a comment, a message), or
/// null when they back out.
Future<ReportReason?> pickReportReason(BuildContext context) {
  final l10n = context.l10n;
  final reasons = {
    ReportReason.spam: l10n.capsulesReportSpam,
    ReportReason.abuse: l10n.capsulesReportAbuse,
    ReportReason.nudity: l10n.capsulesReportNudity,
    ReportReason.violence: l10n.capsulesReportViolence,
    ReportReason.privacy: l10n.capsulesReportPrivacy,
    ReportReason.other: l10n.capsulesReportOther,
  };
  return showCenteredSheet<ReportReason>(
    context,
    OptionsMenu(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.capsulesReportTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: context.palette.textPrimary,
            ),
          ),
        ),
        for (final (i, entry) in reasons.entries.indexed) ...[
          const OptionsMenuDivider(),
          OptionsMenuItem(
            text: entry.value,
            isLast: i == reasons.length - 1,
            onPressed: () => Navigator.of(context).pop(entry.key),
          ),
        ],
      ],
    ),
  );
}

/// The six reactions in equal slots; the user's choice is tinted green and
/// each shows how many people chose it.
class CapsuleReactionsBar extends StatelessWidget {
  const CapsuleReactionsBar({super.key, required this.controller});

  final CapsuleSocialController controller;

  Future<void> _react(BuildContext context, ReactionType type) async {
    unawaited(HapticFeedback.selectionClick());
    final failure = await controller.react(type);
    if (failure != null && context.mounted) {
      PopupNotificationService.showError(
        context: context,
        message: failure.message,
        position: NotificationPosition.bottom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mine = controller.myReaction;
    final counts = controller.counts;
    final palette = context.palette;
    return Row(
      children: [
        for (final type in ReactionType.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Semantics(
                button: true,
                selected: mine == type,
                label: context.l10n.capsulesReactWith(type.emoji),
                child: AppPressable(
                  child: GestureDetector(
                    onTap: () => _react(context, type),
                    child: AnimatedContainer(
                      duration: AppMotion.of(context, AppMotion.fast),
                      curve: AppMotion.standardCurve,
                      height: 40,
                      decoration: BoxDecoration(
                        color: mine == type
                            ? AppColors.brandGreen.withValues(alpha: 0.18)
                            : palette.surfaceMuted,
                        borderRadius: AppRadii.lCircular,
                        border: Border.all(
                          color: mine == type
                              ? AppColors.brandGreen
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ReactionBurst(
                                active: mine == type,
                                child: Text(
                                  type.emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              if ((counts[type] ?? 0) > 0) ...[
                                const SizedBox(width: 3),
                                Text(
                                  '${counts[type]}',
                                  style: TextStyle(
                                    fontFamily: kAppFontFamily,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
