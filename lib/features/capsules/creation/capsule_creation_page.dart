import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/session/session_controller.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/capsule.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/location_service.dart';
import '../../../services/popup_notification_service.dart';
import '../../../shared/widgets/capsule/capsule_date_pill.dart';
import '../../../shared/widgets/capsule/capsule_place_pill.dart';
import '../../../views/widgets/_common/decorations/box_decorations.dart';
import '../../../views/widgets/_common/default_buttons/default_green_button.dart';
import '../../../views/widgets/_common/default_buttons/default_icon_button.dart';
import '../../../views/widgets/_common/default_elements/default_text.dart';
import '../../../views/widgets/_common/default_elements/page_header.dart';
import '../../../views/widgets/_common/options_elements/options_settings_row.dart';
import '../../../views/widgets/my_profile_page/profile_page_divider.dart';
import '../../map/current_location.dart';
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
  });

  final String imagePath;
  final CapsulePrivacy? initialPrivacy;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CapsuleCreationController(
        ownerId: context.read<SessionController>().uid!,
        imagePath: imagePath,
        capsules: context.read<CapsuleRepository>(),
        location: context.read<LocationService>(),
        currentLocation: context.read<CurrentLocation>(),
        initialPrivacy: initialPrivacy,
      ),
      child: _CapsuleCreationView(initialPrivacy: initialPrivacy),
    );
  }
}

class _CapsuleCreationView extends StatelessWidget {
  const _CapsuleCreationView({this.initialPrivacy});

  final CapsulePrivacy? initialPrivacy;

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
    final failure = await context.read<CapsuleCreationController>().save();
    if (!context.mounted) return;
    if (failure == null) {
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

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.pageBackgroundAlt,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                mainText: 'Create Capsule',
                leadingButton: DefaultIconButton(
                  onTap: () => AppRoutes.toCamera(
                    context,
                    replace: true,
                    privacy: initialPrivacy,
                  ),
                  assetPath: AppIcons.goBack,
                ),
                trailingButton: DefaultIconButton(
                  onTap: () => Navigator.pop(context),
                  assetPath: AppIcons.capsuleClose,
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultText(
                        'Capsule Preview',
                        fontSize: screen.width * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                      Container(
                        width: screen.width,
                        height: screen.height * 0.4,
                        decoration: BoxDecorations.whiteCard(),
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
                                  ProfilePageDivider(width: screen.width * 0.5),
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
                        'Capsule Settings',
                        fontSize: screen.width * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: screen.width,
                        decoration: BoxDecorations.whiteCard(),
                        child: Column(
                          children: [
                            OptionsSettingsRow(
                              minVerticalPadding: 10,
                              title: 'Privacy',
                              leadingIconPath: AppIcons.capsulePrivacy,
                              trailing: CapsuleCreationCycledInfo(
                                infoText: controller.privacy.label,
                              ),
                              onTap: controller.cyclePrivacy,
                            ),
                            OptionsSettingsRow(
                              minVerticalPadding: 10,
                              title: 'Open At',
                              trailing: CapsuleCreationCycledInfo(
                                infoText: controller.openAt != null
                                    ? DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(controller.openAt!)
                                    : 'Select date',
                              ),
                              leadingIconPath: AppIcons.capsuleTimer,
                              onTap: () => _pickOpenDate(context),
                            ),
                            OptionsSettingsRow(
                              minVerticalPadding: 10,
                              title: 'Color',
                              trailing: CapsuleCreationCycledInfo(
                                infoText: controller.color.label,
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            child: DefaultGreenButton(
              onTap: () => _save(context),
              text: 'Create Capsule',
              isLoading: controller.isSaving,
            ),
          ),
        ),
      ),
    );
  }
}
