import 'package:flutter/material.dart';
import 'package:later/controllers/page_controllers/capsule_creation/capsule_creation_page_controller.dart';
import 'package:later/data/models/time_capsule.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/views/pages/navbar_pages/map_page.dart' as map;
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/_common/default_buttons/default_green_button.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/_common/options_elements/options_settings_row.dart';
import 'package:later/views/widgets/capsule_creation/capsule_creation_cycled_info.dart';
import 'package:later/views/widgets/capsule_creation/capsule_image_preview.dart';
import 'package:later/views/widgets/capsule_creation/capsule_creation_location_label.dart';
import 'package:later/views/widgets/capsule_creation/capsule_creation_datestamp.dart';
import 'package:later/views/widgets/capsule_creation/capsule_creation_description_input.dart';
import 'package:later/views/widgets/capsule_creation/capsule_creation_title_input.dart';
import 'package:intl/intl.dart';
import 'package:later/views/widgets/_common/default_buttons/default_icon_button.dart';
import 'package:later/views/widgets/_common/default_elements/page_header.dart';
import 'package:later/views/widgets/my_profile_page/profile_page_divider.dart';
import 'package:provider/provider.dart';

class CapsuleCreationPage extends StatefulWidget {
  final String imagePath;
  final String? initialPrivacy;

  const CapsuleCreationPage({
    super.key,
    required this.imagePath,
    this.initialPrivacy,
  });

  @override
  State<CapsuleCreationPage> createState() => _CapsuleCreationPageState();
}

class _CapsuleCreationPageState extends State<CapsuleCreationPage> {
  late final UserDataService _userDataService;
  late final CapsuleCreationPageController _controller;

  LatLng? _pickedLocation;

  @override
  void initState() {
    super.initState();
    _userDataService = Provider.of<UserDataService>(context, listen: false);
    _pickedLocation = map.MapPage.currentPositionStatic;

    CapsulePrivacy? initialPrivacy;
    if (widget.initialPrivacy == 'friends') {
      initialPrivacy = CapsulePrivacy.friends;
    } else if (widget.initialPrivacy == 'public') {
      initialPrivacy = CapsulePrivacy.public;
    }

    _controller = CapsuleCreationPageController(
      uid: _userDataService.currentLoggedInUid,
      imagePath: widget.imagePath,
      initialLocation: _pickedLocation,
      initialPrivacy: initialPrivacy ?? null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFF5F5F5),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                mainText: 'Create Capsule',
                leadingButton: DefaultIconButton(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/camera'),
                  assetPath: 'assets/images/icons/prof_page/go_back.png',
                ),
                trailingButton: DefaultIconButton(
                  onTap: () => Navigator.pop(context),
                  assetPath: 'assets/images/icons/capsule_creation/cross.png',
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
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                      Container(
                        width: screenWidth,
                        height: screenHeight * 0.4,
                        decoration: BoxDecorations.whiteCard(),
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: screenWidth * 0.45,
                              height: double.infinity,
                              child: CapsuleImagePreview(
                                imagePath: widget.imagePath,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CapsuleCreationTitleInput(
                                    controller: _controller.titleController,
                                  ),
                                  ProfilePageDivider(width: screenWidth * 0.5),
                                  CapsuleCreationDescriptionInputField(
                                    controller:
                                        _controller.descriptionController,
                                  ),

                                  CapsuleCreationDateStamp(
                                    height: screenHeight * 0.045,
                                  ),
                                  const SizedBox(height: 8),
                                  CapsuleCreationLocationLabel(
                                    height: screenHeight * 0.05,
                                    iconPath:
                                        'assets/images/icons/capsule_creation/location_icon.png',
                                    location: _pickedLocation,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),

                      DefaultText(
                        'Capsule Settings',
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: screenWidth,
                        decoration: BoxDecorations.whiteCard(),
                        child: Column(
                          children: [
                            OptionsSettingsRow(
                              minVerticalPadding: 10,
                              title: 'Privacy',
                              leadingIconPath:
                                  'assets/images/icons/capsule_creation/privacy_icon.png',
                              trailing: CapsuleCreationCycledInfo(
                                infoText: _controller.privacy.label,
                              ),
                              onTap: () {
                                _controller.cyclePrivacy();
                                setState(() {});
                              },
                            ),

                            OptionsSettingsRow(
                              minVerticalPadding: 10,
                              title: 'Open At',
                              trailing: CapsuleCreationCycledInfo(
                                infoText: _controller.openAt != null
                                    ? DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(_controller.openAt!.toDate())
                                    : "Select date",
                              ),
                              leadingIconPath:
                                  'assets/images/icons/capsule_creation/timer_icon.png',
                              onTap: () async {
                                await _controller.pickOpenDate(context);
                                setState(() {});
                              },
                            ),

                            OptionsSettingsRow(
                              minVerticalPadding: 10,
                              title: 'Color',
                              trailing: CapsuleCreationCycledInfo(
                                infoText: _controller.color.label,
                                trailingLeadingIconPath:
                                    'assets/images/icons/capsule_creation/pin_${_controller.color.label.toLowerCase()}_icon.png',
                              ),
                              leadingIconPath:
                                  'assets/images/icons/capsule_creation/pin_color_icon.png',
                              onTap: () {
                                _controller.cycleColor();
                                setState(() {});
                              },
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
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return DefaultGreenButton(
                  onTap: () async {
                    await _controller.saveCapsule(context);
                  },
                  text: 'Create Capsule',
                  isLoading: _controller.isSaving,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
