import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/session/session_controller.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/models/social.dart';
import '../../../data/repositories/repositories.dart';
import '../../capsules/social/capsule_social_panel.dart'
    show pickReportReason, showReportResult;

/// Asks why, reports the profile [uid] to the moderators, thanks the user.
/// Used by the friend menu (the menu that opened it may be closing, so the
/// app's navigator shows the follow-ups).
Future<void> reportUser(BuildContext context, String uid) async {
  final reporter = context.read<SessionController>().uid;
  final social = context.read<SocialRepository>();
  final page = AppRoutes.navigatorKey.currentContext ?? context;
  if (reporter == null) return;
  final reason = await pickReportReason(page);
  if (reason == null || !page.mounted) return;
  AppFailure? failure;
  try {
    await social.report(
      reporterId: reporter,
      target: ReportTarget.user,
      targetPath: 'users/$uid',
      reason: reason,
    );
  } catch (e, st) {
    AppLogger.warning('Reporting a profile failed', error: e, stackTrace: st);
    failure = AppFailure.from(
      e,
      fallbackMessage: AppL10n.current.messagesReportFailed,
    );
  }
  if (page.mounted) showReportResult(page, failure);
}
