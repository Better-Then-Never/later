import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/session/session_controller.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/models/capsule.dart';
import '../../../data/models/user_settings.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/options/options_section.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../settings_store.dart';
import '../widgets/settings_scaffold.dart';

/// Defaults for new capsules and what others see of the user.
class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  static String visibilityName(AppLocalizations l10n, CapsulePrivacy p) =>
      switch (p) {
        CapsulePrivacy.public => l10n.settingsVisibilityPublic,
        CapsulePrivacy.friends => l10n.settingsVisibilityFriends,
        CapsulePrivacy.private => l10n.settingsVisibilityPrivate,
      };

  static String _visibilityHint(AppLocalizations l10n, CapsulePrivacy p) =>
      switch (p) {
        CapsulePrivacy.public => l10n.settingsVisibilityPublicHint,
        CapsulePrivacy.friends => l10n.settingsVisibilityFriendsHint,
        CapsulePrivacy.private => l10n.settingsVisibilityPrivateHint,
      };

  static void _showFailure(BuildContext context, AppFailure? failure) {
    if (failure == null || !context.mounted) return;
    PopupNotificationService.showError(
      context: context,
      message: failure.message,
      position: NotificationPosition.bottom,
    );
  }

  Future<void> _save(BuildContext context, PrivacySettings next) async {
    final failure = await context.read<SettingsStore>().updatePrivacy(next);
    if (context.mounted) _showFailure(context, failure);
  }

  Future<void> _setShowAchievements(BuildContext context, bool show) async {
    final uid = context.read<SessionController>().uid;
    if (uid == null) return;
    try {
      await context.read<UserRepository>().setShowAchievements(uid, show);
    } catch (e, st) {
      AppLogger.warning(
        'Saving showAchievements failed',
        error: e,
        stackTrace: st,
      );
      if (!context.mounted) return;
      _showFailure(
        context,
        AppFailure.from(
          e,
          fallbackMessage: context.l10n.settingsErrorSaveFailed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final privacy = context.select<SettingsStore, PrivacySettings>(
      (s) => s.privacy,
    );
    // The defaults show until the saved settings arrive; no saving before.
    final loaded = context.select<SettingsStore, bool>((s) => s.isLoaded);
    final showAchievements = context.select<SessionController, bool>(
      (s) => s.profile?.showAchievements ?? true,
    );
    final l10n = context.l10n;
    const order = [
      CapsulePrivacy.public,
      CapsulePrivacy.friends,
      CapsulePrivacy.private,
    ];

    return SettingsScaffold(
      title: l10n.settingsPrivacy,
      description: l10n.settingsPrivacyDescription,
      children: [
        OptionsSection(
          title: l10n.settingsSectionNewCapsules,
          footer: l10n.settingsPrivacyNewCapsulesFooter,
          children: [
            for (final p in order)
              SettingsChoiceRow(
                title: visibilityName(l10n, p),
                subtitle: _visibilityHint(l10n, p),
                selected: privacy.defaultVisibility == p,
                onTap: () {
                  if (loaded) {
                    _save(context, privacy.copyWith(defaultVisibility: p));
                  }
                },
              ),
            OptionsSwitchRow(
              title: l10n.settingsPrivacyApproximate,
              subtitle: l10n.settingsPrivacyApproximateHint,
              value: privacy.locationPrecision == LocationPrecision.approximate,
              withDivider: false,
              onChanged: loaded
                  ? (v) => _save(
                      context,
                      privacy.copyWith(
                        locationPrecision: v
                            ? LocationPrecision.approximate
                            : LocationPrecision.exact,
                      ),
                    )
                  : null,
            ),
          ],
        ),
        OptionsSection(
          title: l10n.settingsSectionVisibility,
          children: [
            OptionsSwitchRow(
              title: l10n.settingsPrivacyFindByName,
              subtitle: l10n.settingsPrivacyFindByNameHint,
              value: privacy.findByName,
              onChanged: loaded
                  ? (v) => _save(context, privacy.copyWith(findByName: v))
                  : null,
            ),
            OptionsSwitchRow(
              title: l10n.settingsPrivacyReadReceipts,
              subtitle: l10n.settingsPrivacyReadReceiptsHint,
              value: privacy.readReceipts,
              withDivider: FeatureFlags.achievements,
              onChanged: loaded
                  ? (v) => _save(context, privacy.copyWith(readReceipts: v))
                  : null,
            ),
            if (FeatureFlags.achievements)
              OptionsSwitchRow(
                title: l10n.settingsPrivacyAchievements,
                subtitle: l10n.settingsPrivacyAchievementsHint,
                value: showAchievements,
                withDivider: false,
                onChanged: (v) => _setShowAchievements(context, v),
              ),
          ],
        ),
      ],
    );
  }
}
