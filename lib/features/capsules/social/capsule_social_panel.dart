import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
      position: NotificationPosition.bottom,
    );
  }
}

/// Why the user reports something (a capsule, a comment, a message), or
/// null when they back out: a sheet with the reasons; one is picked first,
/// then the red Report button sends it (one tap on a reason used to send at
/// once).
Future<ReportReason?> pickReportReason(BuildContext context) =>
    showEdgeSheet<ReportReason>(context, (_) => const ReportReasonSheet());

/// The reasons to report something, with a confirm button.
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
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSheets.radius),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: SheetHandle()),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
              child: Text(
                l10n.capsulesReportTitle,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: palette.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(
                l10n.capsulesReportHint,
                style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  color: palette.textSecondary,
                ),
              ),
            ),
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (r) => setState(() => _reason = r),
              child: Column(
                children: [
                  for (final entry in reasons.entries)
                    RadioListTile<ReportReason>(
                      value: entry.key,
                      dense: true,
                      activeColor: AppColors.brandGreen,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        entry.value,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 16,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SizedBox(
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n.commonCancel,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

/// The six reactions in one row; the user's choice is tinted soft green and
/// each shows how many people chose it. The marks are Material placeholders
/// until the owner's drawings exist (docs/polish/PLACEHOLDER_ICONS.md).
class CapsuleReactionsBar extends StatelessWidget {
  const CapsuleReactionsBar({super.key, required this.controller});

  final CapsuleSocialController controller;

  /// The mark of each reaction (placeholders for the hand-drawn ones).
  static IconData markOf(ReactionType type) => switch (type) {
    ReactionType.heart => Icons.favorite_border,
    ReactionType.laugh => Icons.sentiment_very_satisfied,
    ReactionType.wow => Icons.sentiment_neutral,
    ReactionType.sad => Icons.sentiment_dissatisfied,
    ReactionType.fire => Icons.local_fire_department_outlined,
    ReactionType.clap => Icons.celebration_outlined,
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
                  height: 38,
                  padding: EdgeInsets.only(
                    left: 9,
                    right: (counts[type] ?? 0) > 0 ? 11 : 9,
                  ),
                  decoration: BoxDecoration(
                    color: mine == type ? palette.accentSoft : palette.surface,
                    borderRadius: AppRadii.lCircular,
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
                        child: Icon(
                          markOf(type),
                          size: 20,
                          color: mine == type
                              ? palette.accentText
                              : palette.icon,
                        ),
                      ),
                      if ((counts[type] ?? 0) > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${counts[type]}',
                          style: TextStyle(
                            fontFamily: kAppFontFamily,
                            fontSize: 15,
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

/// The usual share sign: three nodes, two links, in the icons' round stroke.
class ShareSignPainter extends CustomPainter {
  const ShareSignPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final a = Offset(w * 0.74, h * 0.2);
    final b = Offset(w * 0.24, h * 0.5);
    final c = Offset(w * 0.74, h * 0.8);
    final line = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(a, b, line)
      ..drawLine(b, c, line);
    final dot = Paint()..color = color;
    for (final o in [a, b, c]) {
      canvas.drawCircle(o, w * 0.13, dot);
    }
  }

  @override
  bool shouldRepaint(ShareSignPainter old) => old.color != color;
}
