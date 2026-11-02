import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/app_page_route.dart';
import '../../app/session/session_controller.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/profile_image_cache.dart';
import '../../shared/widgets/app_sheets.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/pill_v2.dart';
import '../../shared/widgets/popup/popup_notification_service.dart';
import '../../shared/widgets/v2/card_v2.dart';
import '../settings/pages/about_settings_page.dart';
import '../settings/pages/name_settings_page.dart';
import '../settings/pages/username_settings_page.dart';
import 'postcard/own_postcard.dart';
import 'profile_image_editor.dart';
import 'stamp/stamp_sheet.dart';
import 'widgets/edit_profile_image.dart';

/// Edit profile (Profile v4, Figma page 14 `7188:1035`): the postcard as
/// others see it, live and tappable, then the details on it. Each change
/// saves on its own (no Save button to forget).
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  Future<void> _image(BuildContext context, ProfileImageKind kind) async {
    final uid = context.read<SessionController>().uid;
    if (uid == null) return;
    final l10n = context.l10n;
    final editor = ProfileImageEditor(
      uid: uid,
      kind: kind,
      images: context.read<ImageStorageRepository>(),
      cache: context.read<ProfileImageCache>(),
    );
    final cover = kind == ProfileImageKind.background;
    await editProfileImage(
      context,
      editor,
      title: cover ? l10n.profileBackgroundTitle : l10n.profilePictureTitle,
      deleteLabel: cover
          ? l10n.profileBackgroundDelete
          : l10n.profilePictureDelete,
      successMessage: cover
          ? l10n.profileBackgroundUpdated
          : l10n.profilePictureUpdated,
    );
    editor.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final profile = context.select<SessionController, UserProfile?>(
      (s) => s.profile,
    );
    void push(Widget page) => Navigator.of(context).push(appRoute<void>(page));
    final stamp = profile?.stamp ?? const ProfileStampStyle();
    final about = profile?.about.trim() ?? '';
    final town = profile?.homeTown.trim() ?? '';

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeaderV2(
              title: l10n.editProfileTitle,
              onBack: () => Navigator.pop(context),
              backLabel: l10n.commonBack,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  0,
                  8,
                  0,
                  MediaQuery.paddingOf(context).bottom + 24,
                ),
                children: [
                  const OwnPostcard(open: false),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    child: Text(
                      l10n.editProfileHint,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GroupLabelV2(l10n.editProfileAboutYou),
                        CardV2Rows(
                          indent: 16,
                          children: [
                            RowV2(
                              title: l10n.settingsName,
                              value: profile?.name,
                              onTap: () => push(const NameSettingsPage()),
                            ),
                            RowV2(
                              title: l10n.settingsUsername,
                              value: profile == null
                                  ? null
                                  : '@${profile.username}',
                              onTap: () => push(const UsernameSettingsPage()),
                            ),
                            RowV2(
                              title: l10n.settingsAbout,
                              subtitle: about.isEmpty ? null : about,
                              value: about.isEmpty ? l10n.editProfileAdd : null,
                              onTap: () => push(const AboutSettingsPage()),
                            ),
                            RowV2(
                              title: l10n.editProfileHomeTown,
                              value: town.isEmpty ? l10n.editProfileAdd : town,
                              onTap: () => HomeTownSheet.show(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GroupLabelV2(l10n.editProfileYourPostcard),
                        CardV2Rows(
                          indent: 16,
                          children: [
                            RowV2(
                              title: l10n.editProfileCover,
                              value: l10n.editProfileChange,
                              onTap: () =>
                                  _image(context, ProfileImageKind.background),
                            ),
                            RowV2(
                              title: l10n.editProfilePhoto,
                              value: l10n.editProfileChange,
                              onTap: () =>
                                  _image(context, ProfileImageKind.profile),
                            ),
                            RowV2(
                              title: l10n.editProfileStamp,
                              value: l10n.editProfileStampValue(
                                StampSheet.shapeName(context, stamp.shape),
                                StampSheet.colourName(context, stamp.color),
                              ),
                              onTap: () => StampSheet.show(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Edits the town on the postcard; empty removes it.
class HomeTownSheet extends StatefulWidget {
  const HomeTownSheet({super.key, required this.initial});

  final String initial;

  static Future<void> show(BuildContext context) async {
    final session = context.read<SessionController>();
    final uid = session.uid;
    if (uid == null) return;
    final users = context.read<UserRepository>();
    final before = session.profile?.homeTown ?? '';
    final town = await showEdgeSheet<String>(
      context,
      (_) => HomeTownSheet(initial: before),
    );
    if (town == null || town == before || !context.mounted) return;
    try {
      await users.setHomeTown(uid, town);
    } catch (e) {
      AppLogger.warning('Home town not saved', error: e);
      if (context.mounted) {
        PopupNotificationService.showError(
          context: context,
          message: context.l10n.editProfileHomeTownFailed,
          duration: const Duration(seconds: 3),
          position: NotificationPosition.top,
        );
      }
    }
  }

  @override
  State<HomeTownSheet> createState() => _HomeTownSheetState();
}

class _HomeTownSheetState extends State<HomeTownSheet> {
  late final _field = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _save() => Navigator.pop(context, _field.text.trim());

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: SheetHandle.v2()),
              Text(
                l10n.editProfileHomeTown,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: palette.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _field,
                autofocus: true,
                maxLength: UserProfile.maxHomeTown,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                style: AppTextStyles.body.copyWith(
                  fontSize: 16,
                  color: palette.textPrimary,
                ),
                decoration: InputDecoration(
                  helperText: l10n.editProfileHomeTownNote,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: PillV2(label: l10n.commonSave, onTap: _save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
