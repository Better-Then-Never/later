import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/entitlements_store.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/session/session_controller.dart';
import '../../../core/assets/app_assets.dart';
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
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/loop_picture.dart';
import '../../../shared/widgets/photo_viewer.dart';
import '../../../shared/widgets/options/options_section.dart';
import '../../../shared/widgets/options_menu.dart';
import '../../map/current_location.dart';
import '../../messages/widgets/group_friends_picker.dart';
import '../../settings/device_settings_store.dart';
import '../../settings/settings_store.dart';
import '../outbox/capsule_outbox.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../social/capsule_sheet.dart';
import 'capsule_creation_controller.dart';
import 'creation_draft.dart';
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
        for (final p in CapsulePrivacy.values) MenuChoice(p, p.who(l10n)),
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
    final l10n = context.l10n;
    final openAt = controller.openAt;
    void retake() => AppRoutes.toCamera(
      context,
      replace: true,
      privacy: initialPrivacy,
      recipientId: recipientId,
    );

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
            PageHeaderV2(
              title: l10n.capsulesCreationTitle,
              backLabel: l10n.commonBack,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: AppStaggerScope(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The capsule as it will look (Figma "Preview v3"):
                      // the photo as a square, the title and its place, the
                      // words, when it is left and opens.
                      _CardV2(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PreviewPhoto(
                              controller: controller,
                              onRetake: retake,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                  const SizedBox(height: 8),
                                  CapsuleCreationDescriptionInputField(
                                    controller:
                                        controller.descriptionController,
                                  ),
                                  const SizedBox(height: 8),
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
                        child: _GroupLabel(l10n.capsulesCreationSettings),
                      ),
                      AppStaggerItem(
                        index: 1,
                        child: _CardV2(
                          child: Column(
                            children: [
                              _RowV2(
                                iconPath: AppIcons.capsuleTimer,
                                title: l10n.capsulesCreationOpenAt,
                                value: openAt != null
                                    ? AppDates.short(openAt, l10n.localeName)
                                    : l10n.capsulesCreationAnytime,
                                onTap: () => _chooseOpenDate(context),
                              ),
                              const _RowDivider(inset: 58),
                              _RowV2(
                                iconPath: AppIcons.capsulePrivacy,
                                title: l10n.capsulesCreationPrivacy,
                                value: controller.privacy.who(l10n),
                                onTap: () => _choosePrivacy(context),
                              ),
                              const _RowDivider(inset: 58),
                              _RowV2(
                                iconPath: AppIcons.profileMyFriends,
                                tint: true,
                                title: l10n.capsulesCreationCoAuthors,
                                value: controller.coAuthors.isEmpty
                                    ? l10n.capsulesCreationCoAuthorsNone
                                    : l10n.capsulesCreationCoAuthorsCount(
                                        controller.coAuthors.length,
                                      ),
                                onTap: () => _chooseCoAuthors(context),
                              ),
                              const _RowDivider(inset: 58),
                              _RowV2(
                                iconPath: AppIcons.capsulePinColor,
                                title: l10n.capsulesCreationColor,
                                value: controller.color.localized(l10n),
                                onTap: () => _chooseColor(context),
                              ),
                              if (controller.isLoop) ...[
                                const _RowDivider(inset: 58),
                                _RowV2(
                                  iconPath: AppIcons.capsuleTimer,
                                  title: l10n.capsulesCreationSpeed,
                                  value: _speedLabel(
                                    l10n,
                                    controller.frameDelayMs,
                                  ),
                                  onTap: () => _chooseSpeed(context),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppStaggerItem(
                        index: 2,
                        child: _GroupLabel(l10n.capsulesCreationOptions),
                      ),
                      AppStaggerItem(
                        index: 3,
                        child: _CardV2(
                          child: Column(
                            children: [
                              if (FeatureFlags.comments) ...[
                                _SwitchRowV2(
                                  title: l10n.capsulesCreationAllowComments,
                                  value: controller.allowComments,
                                  onChanged: (v) =>
                                      controller.allowComments = v,
                                ),
                                const _RowDivider(inset: 16),
                              ],
                              if (FeatureFlags.reactions) ...[
                                _SwitchRowV2(
                                  title: l10n.capsulesCreationAllowReactions,
                                  value: controller.allowReactions,
                                  onChanged: (v) =>
                                      controller.allowReactions = v,
                                ),
                                const _RowDivider(inset: 16),
                              ],
                              _SwitchRowV2(
                                title: l10n.capsulesCreationShowAuthor,
                                subtitle: l10n.capsulesCreationShowAuthorHint,
                                value: controller.showAuthor,
                                onChanged: (v) => controller.showAuthor = v,
                              ),
                              const _RowDivider(inset: 16),
                              _SwitchRowV2(
                                title: l10n.capsulesCreationApproximate,
                                subtitle: l10n.capsulesCreationApproximateHint,
                                value:
                                    controller.locationPrecision ==
                                    LocationPrecision.approximate,
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
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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

/// A card of the v2 Create page: the surface, 20 dp corners, the card shadow.
class _CardV2 extends StatelessWidget {
  const _CardV2({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(AppRadii.m),
      boxShadow: AppShadows.card(context),
    ),
    child: child,
  );
}

/// "SETTINGS", "OPTIONS": a small grey label above a card.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: kAppFontFamily,
        fontSize: 12,
        height: 1.2,
        letterSpacing: 0.96,
        fontWeight: FontWeight.bold,
        color: context.palette.textSecondary,
      ),
    ),
  );
}

/// A settings row of the v2 design (Figma "Row v2", regular): a 28 dp icon,
/// the title, the value in grey and an arrow.
class _RowV2 extends StatelessWidget {
  const _RowV2({
    required this.iconPath,
    required this.title,
    required this.value,
    required this.onTap,
    this.tint = false,
  });

  final String iconPath;

  /// The icon is drawn in colour: shown in the icons' ink instead.
  final bool tint;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    TextStyle row(Color color) => TextStyle(
      fontFamily: kAppFontFamily,
      fontSize: 16,
      height: 1.25,
      color: color,
    );
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
            child: Row(
              children: [
                Image.asset(
                  iconPath,
                  width: 28,
                  height: 28,
                  color: tint ? palette.icon : null,
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(title, style: row(palette.textPrimary))),
                const SizedBox(width: 14),
                // As wide as its words, up to 150 dp.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: row(palette.textMuted),
                  ),
                ),
                const SizedBox(width: 14),
                Image.asset(AppIcons.goHere, width: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A switch row of the v2 design: the title (and a grey line under it) and
/// the app's switch.
class _SwitchRowV2 extends StatelessWidget {
  const _SwitchRowV2({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 16,
                          height: 1.25,
                          color: palette.textPrimary,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontFamily: kAppFontFamily,
                            fontSize: 13,
                            height: 1.25,
                            color: palette.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // The switch at the design's size (Figma "Switch" 44 x 27).
                SizedBox(
                  width: 44.2,
                  height: 27.2,
                  child: FittedBox(
                    child: AppSwitch(
                      value: value,
                      onChanged: onChanged,
                      compact: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The 1 dp line between rows, starting at [inset].
class _RowDivider extends StatelessWidget {
  const _RowDivider({required this.inset});

  final double inset;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: inset),
    child: Divider(height: 1, thickness: 1, color: context.palette.divider),
  );
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
              borderRadius: BorderRadius.circular(16),
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
                  child: PhotoBadge(text: context.l10n.capsulesCreationRetake),
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
  /// Who sees it, in words ("Everyone", "Friends", "Only me").
  String who(AppLocalizations l10n) => switch (this) {
    CapsulePrivacy.public => l10n.capsulesWhoEveryone,
    CapsulePrivacy.friends => l10n.capsulesWhoFriends,
    CapsulePrivacy.private => l10n.capsulesWhoOnlyMe,
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
