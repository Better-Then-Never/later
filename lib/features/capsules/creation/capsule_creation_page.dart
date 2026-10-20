import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/entitlements_store.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/session/session_controller.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/gallery_service.dart';
import '../../../data/services/geocoding_service.dart';
import '../../../data/services/location_service.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../../shared/widgets/capsule/capsule_place_chip.dart';
import '../../../shared/styles/box_decorations.dart';
import '../../../shared/widgets/buttons/default_icon_button.dart';
import '../../../shared/widgets/default_text.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/loop_picture.dart';
import '../../../shared/widgets/photo_viewer.dart';
import '../../../shared/widgets/options/options_section.dart';
import '../../../shared/widgets/options/options_settings_row.dart';
import '../../../shared/widgets/options_menu.dart';
import '../../map/current_location.dart';
import '../../messages/widgets/group_friends_picker.dart';
import '../../settings/device_settings_store.dart';
import '../../settings/settings_store.dart';
import '../outbox/capsule_outbox.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import 'capsule_creation_controller.dart';
import 'creation_draft.dart';
import 'widgets/capsule_creation_cycled_info.dart';
import 'widgets/capsule_creation_description_input.dart';
import 'widgets/capsule_creation_title_input.dart';
import 'widgets/loop_frame_strip.dart';
import 'widgets/open_date_calendar.dart';
import 'widgets/pin_picker_sheet.dart';
import 'widgets/capsule_submit_button.dart';
import '../../../core/l10n/app_dates.dart';

class CapsuleCreationPage extends StatelessWidget {
  const CapsuleCreationPage({
    super.key,
    required this.imagePath,
    this.framePaths = const [],
    this.initialPrivacy,
    this.recipientId,
    this.draft,
  });

  /// An unfinished capsule taken up again (B4).
  final CreationDraft? draft;

  final String imagePath;

  /// A loop capsule's frames (empty for a photo).
  final List<String> framePaths;
  final CapsulePrivacy? initialPrivacy;

  /// The friend the capsule is sent to (it also lands in your chat).
  final String? recipientId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CapsuleCreationController(
        ownerId: context.read<SessionController>().uid!,
        imagePath: imagePath,
        framePaths: framePaths,
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
        // Settings > Map and camera: photo size and the gallery copy.
        highQuality:
            context.read<DeviceSettingsStore>().photoQuality ==
            PhotoQuality.high,
        saveToGallery:
            GalleryService.isSupported &&
            context.read<DeviceSettingsStore>().saveToGallery,
        gallery: GalleryService(),
        // Town and country for the passport (B7).
        geocoding: context.read<GeocodingService>(),
        // Kept as left until it is made (B4).
        drafts: CreationDraftStore(),
        draft: draft,
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

  Future<void> _choosePrivacy(BuildContext context) async {
    final l10n = context.l10n;
    final controller = context.read<CapsuleCreationController>();
    final chosen = await showChoiceMenu<CapsulePrivacy>(
      context,
      title: l10n.capsulesCreationPrivacy,
      selected: controller.privacy,
      choices: [
        for (final p in CapsulePrivacy.values) MenuChoice(p, p.localized(l10n)),
      ],
    );
    if (chosen != null) controller.privacy = chosen;
  }

  static String _speedLabel(AppLocalizations l10n, int delayMs) =>
      switch (delayMs) {
        > Capsule.defaultFrameDelayMs => l10n.capsulesSpeedSlow,
        < Capsule.defaultFrameDelayMs => l10n.capsulesSpeedFast,
        _ => l10n.capsulesSpeedNormal,
      };

  Future<void> _chooseSpeed(BuildContext context) async {
    final l10n = context.l10n;
    final controller = context.read<CapsuleCreationController>();
    final chosen = await showChoiceMenu<int>(
      context,
      title: l10n.capsulesCreationSpeed,
      selected: controller.frameDelayMs,
      choices: [
        for (final delay in CapsuleCreationController.frameDelays)
          MenuChoice(delay, _speedLabel(l10n, delay)),
      ],
    );
    if (chosen != null) controller.frameDelayMs = chosen;
  }

  Future<void> _choosePlace(BuildContext context) async {
    final controller = context.read<CapsuleCreationController>();
    final here = controller.here;
    if (here == null) return;
    final spot = await PinPickerSheet.show(
      context,
      here: here,
      start: controller.position,
      pinAsset: AppIcons.mapPin(controller.color.name),
    );
    if (spot != null) controller.movePin(spot);
  }

  Future<void> _chooseColor(BuildContext context) async {
    final l10n = context.l10n;
    final controller = context.read<CapsuleCreationController>();
    final chosen = await showChoiceMenu<CapsuleColor>(
      context,
      title: l10n.capsulesCreationColor,
      selected: controller.color,
      choices: [
        for (final c in CapsuleColor.values)
          MenuChoice(
            c,
            c.localized(l10n),
            trailing: Image.asset(
              AppIcons.capsulePin(c.name),
              width: 22,
              height: 22,
            ),
          ),
      ],
    );
    if (chosen != null) controller.color = chosen;
  }

  Future<void> _chooseCoAuthors(BuildContext context) async {
    final l10n = context.l10n;
    final controller = context.read<CapsuleCreationController>();
    final pick = await GroupFriendsPicker.show(
      context,
      title: l10n.capsulesCoAuthorsPick,
      actionText: l10n.capsulesCoAuthorsDone,
      room: EntitlementsStore.of(context).coAuthors,
      initial: controller.coAuthors.toSet(),
      allowEmpty: true,
      tooManyText: l10n.capsulesCoAuthorsTooMany(
        EntitlementsStore.of(context).coAuthors,
      ),
    );
    if (pick != null) controller.coAuthors = pick.friends;
  }

  /// Quick choices first; the calendar only for another day.
  Future<void> _chooseOpenDate(BuildContext context) async {
    final l10n = context.l10n;
    final controller = context.read<CapsuleCreationController>();
    final now = DateTime.now();
    final choice = await showChoiceMenu<_OpenChoice>(
      context,
      title: l10n.capsulesCreationOpenAt,
      choices: [
        MenuChoice(_OpenChoice.tomorrow, l10n.capsulesOpenTomorrow),
        MenuChoice(_OpenChoice.week, l10n.capsulesOpenInWeek),
        MenuChoice(_OpenChoice.month, l10n.capsulesOpenInMonth),
        MenuChoice(_OpenChoice.year, l10n.capsulesOpenInYear),
        MenuChoice(_OpenChoice.pick, l10n.capsulesOpenPickDate),
        if (controller.openAt != null)
          MenuChoice(_OpenChoice.now, l10n.capsulesOpenNow),
      ],
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case _OpenChoice.tomorrow:
        controller.setOpenDate(now.add(const Duration(days: 1)));
      case _OpenChoice.week:
        controller.setOpenDate(now.add(const Duration(days: 7)));
      case _OpenChoice.month:
        controller.setOpenDate(CapsuleCreationController.addMonths(now, 1));
      case _OpenChoice.year:
        controller.setOpenDate(CapsuleCreationController.addMonths(now, 12));
      case _OpenChoice.now:
        controller.clearOpenDate();
      case _OpenChoice.pick:
        // The app's own calendar (F-27), not the stock picker.
        final picked = await OpenDateCalendar.show(
          context,
          first: now.add(const Duration(days: 1)),
          last: DateTime(now.year + 5, 12, 31),
          selected: controller.openAt,
        );
        if (picked != null) controller.setOpenDate(picked);
    }
  }

  /// Saves; true when the capsule is made (or kept to upload later).
  Future<bool> _save(BuildContext context) async {
    final controller = context.read<CapsuleCreationController>();
    final failure = await controller.save();
    if (!context.mounted) return false;
    if (failure == null) {
      if (controller.queued) {
        PopupNotificationService.showSuccess(
          context: context,
          message: context.l10n.capsulesQueued,
          position: NotificationPosition.top,
        );
      }
      return true;
    }
    PopupNotificationService.showError(
      context: context,
      message: failure.message,
      position: NotificationPosition.center,
    );
    return false;
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
                child: AppStaggerScope(
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // The capsule as it will look (capsule v3): the
                          // photo as a square, the title and its place, the
                          // words, when it is left and opens.
                          Container(
                            width: screen.width,
                            decoration: BoxDecorations.whiteCard(context),
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _PreviewPhoto(
                                  controller: controller,
                                  onRetake: () => AppRoutes.toCamera(
                                    context,
                                    replace: true,
                                    privacy: initialPrivacy,
                                    recipientId: recipientId,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CapsuleCreationTitleInput(
                                              controller:
                                                  controller.titleController,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // A tap moves the pin (B4).
                                          CapsulePlaceChip.at(
                                            position: controller.position,
                                            label: l10n.capsulesPinTitle,
                                            onTap: () => _choosePlace(context),
                                          ),
                                        ],
                                      ),
                                      CapsuleCreationDescriptionInputField(
                                        controller:
                                            controller.descriptionController,
                                      ),
                                      _PreviewDates(openAt: openAt),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // A loop: its frames, to reorder or thin out.
                          if (controller.isLoop) ...[
                            const SizedBox(height: 10),
                            LoopFrameStrip(controller: controller),
                          ],
                          const SizedBox(height: 8),
                          AppStaggerItem(
                            index: 0,
                            child: DefaultText(
                              l10n.capsulesCreationSettings,
                              fontSize: screen.width * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppStaggerItem(
                            index: 1,
                            child: Container(
                              width: screen.width,
                              decoration: BoxDecorations.whiteCard(context),
                              child: Column(
                                children: [
                                  OptionsSettingsRow(
                                    minVerticalPadding: 10,
                                    title: l10n.capsulesCreationPrivacy,
                                    leadingIconPath: AppIcons.capsulePrivacy,
                                    trailing: CapsuleCreationCycledInfo(
                                      infoText: controller.privacy.localized(
                                        l10n,
                                      ),
                                    ),
                                    onTap: () => _choosePrivacy(context),
                                  ),
                                  OptionsSettingsRow(
                                    minVerticalPadding: 10,
                                    title: l10n.capsulesCreationOpenAt,
                                    trailing: CapsuleCreationCycledInfo(
                                      infoText: openAt != null
                                          ? AppDates.short(
                                              openAt,
                                              l10n.localeName,
                                            )
                                          : l10n.capsulesCreationSelectDate,
                                    ),
                                    leadingIconPath: AppIcons.capsuleTimer,
                                    onTap: () => _chooseOpenDate(context),
                                  ),
                                  if (controller.isLoop)
                                    OptionsSettingsRow(
                                      minVerticalPadding: 10,
                                      title: l10n.capsulesCreationSpeed,
                                      trailing: CapsuleCreationCycledInfo(
                                        infoText: _speedLabel(
                                          l10n,
                                          controller.frameDelayMs,
                                        ),
                                      ),
                                      leadingIconPath: AppIcons.capsuleTimer,
                                      onTap: () => _chooseSpeed(context),
                                    ),
                                  OptionsSettingsRow(
                                    minVerticalPadding: 10,
                                    title: l10n.capsulesCreationCoAuthors,
                                    trailing: CapsuleCreationCycledInfo(
                                      infoText: controller.coAuthors.isEmpty
                                          ? l10n.capsulesCreationCoAuthorsNone
                                          : l10n.capsulesCreationCoAuthorsCount(
                                              controller.coAuthors.length,
                                            ),
                                    ),
                                    leadingIconPath: AppIcons.profileMyFriends,
                                    tintLeadingIcon: true,
                                    onTap: () => _chooseCoAuthors(context),
                                  ),
                                  OptionsSettingsRow(
                                    minVerticalPadding: 10,
                                    title: l10n.capsulesCreationColor,
                                    trailing: CapsuleCreationCycledInfo(
                                      infoText: controller.color.localized(
                                        l10n,
                                      ),
                                      trailingLeadingIconPath:
                                          AppIcons.capsulePin(
                                            controller.color.name,
                                          ),
                                    ),
                                    leadingIconPath: AppIcons.capsulePinColor,
                                    onTap: () => _chooseColor(context),
                                    withDivider: false,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppStaggerItem(
                            index: 2,
                            child: Container(
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
                                      title:
                                          l10n.capsulesCreationAllowReactions,
                                      value: controller.allowReactions,
                                      onChanged: (v) =>
                                          controller.allowReactions = v,
                                    ),
                                  OptionsSwitchRow(
                                    title: l10n.capsulesCreationShowAuthor,
                                    subtitle:
                                        l10n.capsulesCreationShowAuthorHint,
                                    value: controller.showAuthor,
                                    onChanged: (v) => controller.showAuthor = v,
                                  ),
                                  OptionsSwitchRow(
                                    title: l10n.capsulesCreationApproximate,
                                    subtitle:
                                        l10n.capsulesCreationApproximateHint,
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
                          ),
                        ],
                      ),
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
            child: CapsuleSubmitButton(
              label: l10n.capsulesCreationSubmit,
              saving: controller.isSaving,
              onSave: () => _save(context),
              onDone: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }
}

/// The photo on the preview card, a square as the opened capsule shows it
/// (a loop plays); a tap shows it whole, Retake goes back to the camera.
class _PreviewPhoto extends StatelessWidget {
  const _PreviewPhoto({required this.controller, required this.onRetake});

  final CapsuleCreationController controller;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final loop = controller.isLoop;
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // A look at the whole photo before saving.
          GestureDetector(
            onTap: () => PhotoViewer.show(
              context,
              Uri.file(controller.imagePath).toString(),
              heroTag: loop ? null : 'creation-photo',
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.m),
              child: loop
                  ? LoopPicture(
                      sources: controller.framePaths,
                      frameDelay: Duration(
                        milliseconds: controller.frameDelayMs,
                      ),
                    )
                  : Hero(
                      tag: 'creation-photo',
                      child: Image.file(
                        File(controller.imagePath),
                        fit: BoxFit.cover,
                        // Decoded at the card's size, not the camera's.
                        cacheWidth:
                            (MediaQuery.sizeOf(context).width *
                                    MediaQuery.devicePixelRatioOf(context))
                                .round(),
                      ),
                    ),
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            child: Semantics(
              button: true,
              child: AppPressable(
                child: GestureDetector(
                  onTap: onRetake,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.mediaScrim,
                      borderRadius: AppRadii.lCircular,
                    ),
                    child: Text(
                      context.l10n.capsulesCreationRetake,
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onMedia,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Left today · opens anytime" (or the day it opens) under the words, as
/// the opened capsule shows its dates.
class _PreviewDates extends StatelessWidget {
  const _PreviewDates({required this.openAt});

  final DateTime? openAt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final opens = openAt;
    return Row(
      children: [
        Image.asset(AppIcons.capsuleTimer, width: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            opens == null
                ? l10n.capsulesCreationLeftToday
                : l10n.capsulesCreationLeftTodayOpens(
                    AppDates.medium(opens, l10n.localeName),
                  ),
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              color: context.palette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

enum _OpenChoice { tomorrow, week, month, year, pick, now }

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
