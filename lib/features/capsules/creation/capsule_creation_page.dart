import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/session/session_controller.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/capsule.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/location_service.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../../shared/widgets/capsule/capsule_date_pill.dart';
import '../../../shared/widgets/capsule/capsule_place_pill.dart';
import '../../../shared/styles/box_decorations.dart';
import '../../../shared/widgets/buttons/default_green_button.dart';
import '../../../shared/widgets/buttons/default_icon_button.dart';
import '../../../shared/widgets/default_text.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/options/options_section.dart';
import '../../../shared/widgets/options/options_settings_row.dart';
import '../../../shared/widgets/profile_page_divider.dart';
import '../../map/current_location.dart';
import '../../settings/settings_store.dart';
import '../outbox/capsule_outbox.dart';
import 'capsule_creation_controller.dart';
import 'widgets/capsule_creation_cycled_info.dart';
import 'widgets/capsule_creation_description_input.dart';
import 'widgets/capsule_creation_title_input.dart';
import 'widgets/capsule_image_preview.dart';

class CapsuleCreationPage extends StatelessWidget {
  const CapsuleCreationPage({
    super.key,
    required this.imagePath,
    this.initialPrivacy,
    this.recipientId,
  });

  final String imagePath;
  final CapsulePrivacy? initialPrivacy;

  /// The friend the capsule is sent to (it also lands in your chat).
  final String? recipientId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CapsuleCreationController(
        ownerId: context.read<SessionController>().uid!,
        imagePath: imagePath,
        capsules: context.read<CapsuleRepository>(),
        location: context.read<LocationService>(),
        currentLocation: context.read<CurrentLocation>(),
        // Settings > Privacy gives the default for a capsule on the map.
        initialPrivacy:
            initialPrivacy ??
            (recipientId == null
                ? context.read<SettingsStore>().privacy.defaultVisibility
                : null),
        recipientId: recipientId,
        chats: context.read<ChatRepository>(),
        locationPrecision: context
            .read<SettingsStore>()
            .privacy
            .locationPrecision,
        outbox: context.read<CapsuleOutbox>(),
      ),
      child: _CapsuleCreationView(
        initialPrivacy: initialPrivacy,
        recipientId: recipientId,
      ),
    );
  }
}

class _CapsuleCreationView extends StatelessWidget {
  const _CapsuleCreationView({this.initialPrivacy, this.recipientId});

  final CapsulePrivacy? initialPrivacy;
  final String? recipientId;

  Future<void> _pickOpenDate(BuildContext context) async {
    final now = DateTime.now();
    final controller = context.read<CapsuleCreationController>();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) controller.setOpenDate(picked);
  }

  Future<void> _save(BuildContext context) async {
    final navigator = Navigator.of(context);
    final controller = context.read<CapsuleCreationController>();
    final failure = await controller.save();
    if (!context.mounted) return;
    if (failure == null) {
      if (controller.queued) {
        PopupNotificationService.showSuccess(
          context: context,
          message: context.l10n.capsulesQueued,
          position: NotificationPosition.top,
        );
      }
      navigator.pop();
    } else {
      PopupNotificationService.showError(
        context: context,
        message: failure.message,
        position: NotificationPosition.center,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CapsuleCreationController>();
    final screen = MediaQuery.sizeOf(context);
    final l10n = context.l10n;
    final openAt = controller.openAt;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: context.palette.backgroundAlt,
        // The header stays put (edge-to-edge: content scrolling under the
        // status bar would otherwise carry the title into it).
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              mainText: l10n.capsulesCreationTitle,
              leadingButton: DefaultIconButton(
                onTap: () => AppRoutes.toCamera(
                  context,
                  replace: true,
                  privacy: initialPrivacy,
                  recipientId: recipientId,
                ),
                assetPath: AppIcons.goBack,
                semanticLabel: context.l10n.commonBack,
              ),
              trailingButton: DefaultIconButton(
                onTap: () => Navigator.pop(context),
                assetPath: AppIcons.capsuleClose,
                semanticLabel: MaterialLocalizations.of(
                  context,
                ).closeButtonTooltip,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DefaultText(
                          l10n.capsulesCreationPreview,
                          fontSize: screen.width * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                        Container(
                          width: screen.width,
                          height: screen.height * 0.4,
                          decoration: BoxDecorations.whiteCard(context),
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: screen.width * 0.45,
                                height: double.infinity,
                                child: CapsuleImagePreview(
                                  imagePath: controller.imagePath,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CapsuleCreationTitleInput(
                                      controller: controller.titleController,
                                    ),
                                    ProfilePageDivider(
                                      width: screen.width * 0.5,
                                    ),
                                    CapsuleCreationDescriptionInputField(
                                      controller:
                                          controller.descriptionController,
                                    ),
                                    CapsuleDatePill(
                                      height: screen.height * 0.045,
                                    ),
                                    const SizedBox(height: 8),
                                    CapsulePlacePill(
                                      height: screen.height * 0.05,
                                      iconPath: AppIcons.capsuleLocation,
                                      position: controller.position,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        DefaultText(
                          l10n.capsulesCreationSettings,
                          fontSize: screen.width * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: screen.width,
                          decoration: BoxDecorations.whiteCard(context),
                          child: Column(
                            children: [
                              OptionsSettingsRow(
                                minVerticalPadding: 10,
                                title: l10n.capsulesCreationPrivacy,
                                leadingIconPath: AppIcons.capsulePrivacy,
                                trailing: CapsuleCreationCycledInfo(
                                  infoText: controller.privacy.localized(l10n),
                                ),
                                onTap: controller.cyclePrivacy,
                              ),
                              OptionsSettingsRow(
                                minVerticalPadding: 10,
                                title: l10n.capsulesCreationOpenAt,
                                trailing: CapsuleCreationCycledInfo(
                                  infoText: openAt != null
                                      ? DateFormat(
                                          'yyyy-MM-dd',
                                          l10n.localeName,
                                        ).format(openAt)
                                      : l10n.capsulesCreationSelectDate,
                                ),
                                leadingIconPath: AppIcons.capsuleTimer,
                                onTap: () => _pickOpenDate(context),
                              ),
                              OptionsSettingsRow(
                                minVerticalPadding: 10,
                                title: l10n.capsulesCreationColor,
                                trailing: CapsuleCreationCycledInfo(
                                  infoText: controller.color.localized(l10n),
                                  trailingLeadingIconPath: AppIcons.capsulePin(
                                    controller.color.name,
                                  ),
                                ),
                                leadingIconPath: AppIcons.capsulePinColor,
                                onTap: controller.cycleColor,
                                withDivider: false,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: screen.width,
                          decoration: BoxDecorations.whiteCard(context),
                          child: Column(
                            children: [
                              if (FeatureFlags.comments)
                                OptionsSwitchRow(
                                  title: l10n.capsulesCreationAllowComments,
                                  value: controller.allowComments,
                                  onChanged: (v) =>
                                      controller.allowComments = v,
                                ),
                              if (FeatureFlags.reactions)
                                OptionsSwitchRow(
                                  title: l10n.capsulesCreationAllowReactions,
                                  value: controller.allowReactions,
                                  onChanged: (v) =>
                                      controller.allowReactions = v,
                                ),
                              OptionsSwitchRow(
                                title: l10n.capsulesCreationApproximate,
                                subtitle: l10n.capsulesCreationApproximateHint,
                                value:
                                    controller.locationPrecision ==
                                    LocationPrecision.approximate,
                                withDivider: false,
                                onChanged: (v) =>
                                    controller.approximateLocation = v,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            child: DefaultGreenButton(
              onTap: () => _save(context),
              text: l10n.capsulesCreationSubmit,
              isLoading: controller.isSaving,
            ),
          ),
        ),
      ),
    );
  }
}

/// Privacy names in the app's language (the model's `label` is English).
extension on CapsulePrivacy {
  String localized(AppLocalizations l10n) => switch (this) {
    CapsulePrivacy.public => l10n.capsulesPrivacyPublic,
    CapsulePrivacy.friends => l10n.capsulesPrivacyFriends,
    CapsulePrivacy.private => l10n.capsulesPrivacyPrivate,
  };
}

/// Pin colour names in the app's language (the model's `label` is English).
extension on CapsuleColor {
  String localized(AppLocalizations l10n) => switch (this) {
    CapsuleColor.red => l10n.capsulesColorRed,
    CapsuleColor.blue => l10n.capsulesColorBlue,
    CapsuleColor.green => l10n.capsulesColorGreen,
    CapsuleColor.yellow => l10n.capsulesColorYellow,
    CapsuleColor.orange => l10n.capsulesColorOrange,
    CapsuleColor.purple => l10n.capsulesColorPurple,
  };
}
