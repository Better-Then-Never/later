import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../data/models/social.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/motion/reaction_burst.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../history/own_capsules_store.dart';
import 'capsule_social_controller.dart';

/// Takes the user off a capsule they co-authored; it is no longer theirs to
/// see, so the opened capsule closes.
Future<void> leaveCapsule(BuildContext context, String capsuleId) async {
  final l10n = context.l10n;
  final navigator = Navigator.of(context);
  final failure = await context.read<OwnCapsulesStore>().leave(capsuleId);
  if (!context.mounted) return;
  if (failure != null) {
    PopupNotificationService.showError(
      context: context,
      message: failure.message,
      position: NotificationPosition.bottom,
    );
    return;
  }
  await navigator.maybePop();
  final root = navigator.context;
  if (root.mounted) {
    PopupNotificationService.showSuccess(
      context: root,
      message: l10n.capsulesLeftCoAuthors,
      position: NotificationPosition.bottom,
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
      position: NotificationPosition.top,
    );
  }
}

/// Why the user reports something (a capsule, a comment, a message), or
/// null when they back out: a sheet with the reasons; one is picked first,
/// then the red Report button sends it (one tap on a reason used to send at
/// once).
Future<ReportReason?> pickReportReason(BuildContext context) =>
    showEdgeSheet<ReportReason>(context, (_) => const ReportReasonSheet());

/// The reasons to report something, with a confirm button (Figma "Report
/// sheet"): a reason first, then the red Report button.
class ReportReasonSheet extends StatefulWidget {
  const ReportReasonSheet({super.key});

  @override
  State<ReportReasonSheet> createState() => _ReportReasonSheetState();
}

class _ReportReasonSheetState extends State<ReportReasonSheet> {
  ReportReason? _reason;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final reasons = {
      ReportReason.spam: l10n.capsulesReportSpam,
      ReportReason.abuse: l10n.capsulesReportAbuse,
      ReportReason.nudity: l10n.capsulesReportNudity,
      ReportReason.violence: l10n.capsulesReportViolence,
      ReportReason.privacy: l10n.capsulesReportPrivacy,
      ReportReason.other: l10n.capsulesReportOther,
    };
    TextStyle row(Color color) => TextStyle(
      fontFamily: kAppFontFamily,
      fontSize: 16,
      height: 1.25,
      color: color,
    );
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSheets.radius),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: SheetHandle.v2()),
              const SizedBox(height: 4),
              Text(
                l10n.capsulesReportTitle,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: palette.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.capsulesReportHint,
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 13,
                  height: 1.25,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              for (final entry in reasons.entries)
                Semantics(
                  button: true,
                  selected: _reason == entry.key,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _reason = entry.key),
                    child: SizedBox(
                      height: 42,
                      child: Row(
                        children: [
                          _Radio(on: _reason == entry.key),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: row(palette.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: AppColors.onAccent,
                    disabledBackgroundColor: palette.disabled,
                    disabledForegroundColor: AppColors.onAccent,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: _reason == null
                      ? null
                      : () => Navigator.of(context).pop(_reason),
                  child: Text(
                    l10n.capsulesReport,
                    style: const TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Text(
                      l10n.commonCancel,
                      style: row(palette.textSecondary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A 20 dp radio: a grey ring, or a green ring with a green dot.
class _Radio extends StatelessWidget {
  const _Radio({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) => Container(
    width: 20,
    height: 20,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: on ? AppColors.brandGreen : context.palette.disabled,
        width: 2,
      ),
    ),
    child: on
        ? const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.brandGreen,
              shape: BoxShape.circle,
            ),
          )
        : null,
  );
}

/// The six reactions in one row (Figma "Reactions"): a 36 dp mark each, with
/// how many people chose it; the user's choice is tinted soft green with a
/// green outline. The heart is the app's own drawing; the other marks are
/// Material placeholders until the owner's drawings exist
/// (docs/polish/PLACEHOLDER_ICONS.md).
class CapsuleReactionsBar extends StatelessWidget {
  const CapsuleReactionsBar({super.key, required this.controller});

  final CapsuleSocialController controller;

  /// The placeholder mark of each reaction but the heart.
  static IconData? markOf(ReactionType type) => switch (type) {
    ReactionType.heart => null,
    ReactionType.laugh => Icons.sentiment_very_satisfied,
    ReactionType.wow => Icons.sentiment_satisfied,
    ReactionType.sad => Icons.sentiment_dissatisfied,
    ReactionType.fire => Icons.local_fire_department,
    ReactionType.clap => Icons.celebration,
  };

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
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final type in ReactionType.values)
          Semantics(
            button: true,
            selected: mine == type,
            label: context.l10n.capsulesReactWith(type.emoji),
            child: AppPressable(
              child: GestureDetector(
                onTap: () => _react(context, type),
                child: AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.fast),
                  curve: AppMotion.standardCurve,
                  height: 36,
                  padding: EdgeInsets.only(
                    left: 7,
                    right: (counts[type] ?? 0) > 0 ? 9 : 7,
                  ),
                  decoration: BoxDecoration(
                    color: mine == type
                        ? AppColors.brandGreen.withValues(alpha: 0.25)
                        : palette.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: mine == type
                          ? AppColors.brandGreen
                          : palette.divider,
                      width: mine == type ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ReactionBurst(
                        active: mine == type,
                        child: switch (markOf(type)) {
                          final icon? => Icon(
                            icon,
                            size: 20,
                            color: palette.icon,
                          ),
                          null => Image.asset(
                            AppIcons.capsuleFavorites,
                            width: 20,
                          ),
                        },
                      ),
                      if ((counts[type] ?? 0) > 0) ...[
                        const SizedBox(width: 3),
                        Text(
                          '${counts[type]}',
                          style: TextStyle(
                            fontFamily: kAppFontFamily,
                            fontSize: 15,
                            height: 1.1,
                            fontWeight: FontWeight.bold,
                            color: mine == type
                                ? palette.accentText
                                : palette.textPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
