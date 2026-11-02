import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_page_route.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/session/session_controller.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/profile_image_cache.dart';
import '../../../shared/widgets/later_loading_bar.dart';
import '../../../shared/widgets/user/profile_stamp.dart';
import '../../notifications/widgets/unread_notification_badge.dart';
import '../../settings/pages/about_settings_page.dart';
import '../profile_image_editor.dart';
import '../stamp/stamp_sheet.dart';
import '../widgets/edit_profile_image.dart';
import 'profile_postcard.dart';

/// The signed-in user's postcard (Profile v4): their cover, their stamp,
/// name, town, About me and numbers. Tapping the cover or the stamp changes
/// that picture; the About me opens its editor.
class OwnPostcard extends StatelessWidget {
  const OwnPostcard({super.key, required this.open});

  /// Pulled open: the whole photo.
  final bool open;

  @override
  Widget build(BuildContext context) {
    final profile = context.select<SessionController, UserProfile?>(
      (s) => s.profile,
    );
    final palette = context.palette;
    final l10n = context.l10n;
    final about = profile?.about.trim() ?? '';
    final town = profile?.homeTown.trim() ?? '';
    final username = profile?.username ?? '';
    void editAbout() =>
        Navigator.of(context).push(appRoute<void>(const AboutSettingsPage()));
    return Semantics(
      hint: l10n.profilePostcardOpen,
      child: ProfilePostcard(
        photoHeight: open
            ? ProfilePostcard.photoOpen
            : ProfilePostcard.photoDefault,
        cover: const OwnCover(editable: true),
        stamp: OwnStamp(
          size: ProfilePostcard.stampSize,
          tilt: 4,
          style: profile?.stamp ?? const ProfileStampStyle(),
          initial: profile?.initial ?? '',
          editable: true,
        ),
        name: Text(
          profile?.name ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(
            fontSize: 26,
            height: 1.15,
            fontWeight: FontWeight.bold,
            color: palette.textPrimary,
          ),
        ),
        subtitle: Text(
          town.isEmpty ? '@$username' : '@$username  ·  $town',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: palette.textSecondary,
          ),
        ),
        about: about.isEmpty
            ? Align(
                alignment: Alignment.centerLeft,
                child: AboutPrompt(onTap: editAbout),
              )
            : StampSpeechBubble(
                onTap: editAbout,
                child: Text(about, style: StampSpeechBubble.textStyle(context)),
              ),
        counts: PostcardCounts(profile: profile),
      ),
    );
  }
}

/// Followers, following and countries, under the line on the postcard.
class PostcardCounts extends StatelessWidget {
  const PostcardCounts({super.key, required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    if (p == null) return const SizedBox(height: 18);
    final l10n = context.l10n;
    final parts = [
      l10n.profileFollowers(p.followerCount),
      l10n.profileFollowing(p.followingCount),
      if (p.stats.countries > 0) l10n.profileCountries(p.stats.countries),
    ];
    return Text(
      parts.join('  ·  '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.body.copyWith(
        fontSize: 13,
        color: context.palette.textSecondary,
      ),
    );
  }
}

/// "Add a few words about you" in a dashed bubble, when there is no About me.
class AboutPrompt extends StatelessWidget {
  const AboutPrompt({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedRRect(palette.textTertiary),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              context.l10n.profileAboutPrompt,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: palette.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRect extends CustomPainter {
  _DashedRRect(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.6),
          const Radius.circular(18),
        ),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRect old) => old.color != color;
}

/// The signed-in user's cover photo, filling its box. Without one: soft
/// green and, when [editable], "Add a cover photo" with the camera.
class OwnCover extends StatelessWidget {
  const OwnCover({super.key, this.editable = false});

  final bool editable;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileImageEditor(
        uid: context.read<SessionController>().uid!,
        kind: ProfileImageKind.background,
        images: context.read<ImageStorageRepository>(),
        cache: context.read<ProfileImageCache>(),
      ),
      child: _CoverView(editable: editable),
    );
  }
}

class _CoverView extends StatelessWidget {
  const _CoverView({required this.editable});

  final bool editable;

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<ProfileImageEditor>();
    final image = ownImage(context, editor);
    final resolved = isOwnImageResolved(context, editor);
    final l10n = context.l10n;
    final palette = context.palette;
    Widget child;
    if (editor.isBusy) {
      child = ColoredBox(
        color: palette.emptyBackground,
        child: Center(
          child: LaterLoadingBar(
            width: 40,
            height: 40,
            message: l10n.profileUpdating,
            messageSpacing: 5,
          ),
        ),
      );
    } else if (image != null) {
      child = Image(image: image, fit: BoxFit.cover, gaplessPlayback: true);
    } else if (!resolved) {
      child = ColoredBox(color: palette.skeleton);
    } else {
      child = ColoredBox(
        color: Color.alphaBlend(
          AppColors.brandGreen.withValues(alpha: 0.28),
          palette.surface,
        ),
        child: editable
            ? Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _AddCoverChip(label: l10n.profileAddCover),
                ),
              )
            : null,
      );
    }
    if (!editable) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: editor.isBusy
          ? null
          : () => editProfileImage(
              context,
              editor,
              title: l10n.profileBackgroundTitle,
              deleteLabel: l10n.profileBackgroundDelete,
              successMessage: l10n.profileBackgroundUpdated,
            ),
      child: child,
    );
  }
}

class _AddCoverChip extends StatelessWidget {
  const _AddCoverChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.mediaScrim,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AppIcons.cameraFull, width: 16, height: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.onMedia,
            ),
          ),
        ],
      ),
    );
  }
}

/// The signed-in user's stamp: their photo, or their initial with a camera
/// badge when there is none. When [editable], a tap changes the photo.
class OwnStamp extends StatelessWidget {
  const OwnStamp({
    super.key,
    required this.size,
    required this.style,
    required this.initial,
    this.tilt = 0,
    this.editable = false,
  });

  final double size;
  final ProfileStampStyle style;
  final String initial;
  final double tilt;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileImageEditor(
        uid: context.read<SessionController>().uid!,
        kind: ProfileImageKind.profile,
        images: context.read<ImageStorageRepository>(),
        cache: context.read<ProfileImageCache>(),
      ),
      child: _StampView(
        size: size,
        style: style,
        initial: initial,
        tilt: tilt,
        editable: editable,
      ),
    );
  }
}

class _StampView extends StatelessWidget {
  const _StampView({
    required this.size,
    required this.style,
    required this.initial,
    required this.tilt,
    required this.editable,
  });

  final double size;
  final ProfileStampStyle style;
  final String initial;
  final double tilt;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<ProfileImageEditor>();
    final image = ownImage(context, editor);
    final resolved = isOwnImageResolved(context, editor);
    final l10n = context.l10n;
    final name = context.select<SessionController, String>(
      (s) => s.profile?.name ?? '',
    );
    final stamp = ProfileStamp(
      style: style,
      size: size,
      photo: editor.isBusy ? null : image,
      initial: resolved ? initial : '',
      caption: name.split(' ').first.toLowerCase(),
      tilt: tilt,
    );
    if (!editable) return stamp;
    return Semantics(
      button: true,
      label: l10n.profileStampLabel(name),
      child: GestureDetector(
        // The photo, its shape and its colour (the sheet has Change photo).
        onTap: editor.isBusy ? null : () => StampSheet.show(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            stamp,
            if (editor.isBusy)
              const Positioned.fill(
                child: Center(child: LaterLoadingBar(width: 32, height: 32)),
              ),
            if (image == null && resolved && !editor.isBusy)
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.onAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.passportShadow,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(7),
                  child: Image.asset(
                    AppIcons.cameraFull,
                    color: AppColors.mediaBlack,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Notifications, share and settings, on every state of the own postcard.
class PostcardButtons extends StatelessWidget {
  const PostcardButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            PostcardIconButton(
              asset: AppIcons.notifications,
              label: l10n.notificationsTitle,
              onTap: () => AppRoutes.toNotifications(context),
            ),
            const Positioned(
              right: 0,
              top: -2,
              child: UnreadNotificationBadge(size: 18),
            ),
          ],
        ),
        PostcardIconButton(
          asset: AppIcons.share,
          label: l10n.friendsShareProfile,
          onTap: () => AppRoutes.toShareProfile(context),
        ),
        PostcardIconButton(
          asset: AppIcons.settings,
          label: l10n.settingsTitle,
          onTap: () => AppRoutes.toSettings(context),
        ),
      ],
    );
  }
}

/// The signed-in user's postcard in small, on top of Settings: cover, stamp,
/// name and "Edit profile".
class MiniOwnPostcard extends StatelessWidget {
  const MiniOwnPostcard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final profile = context.select<SessionController, UserProfile?>(
      (s) => s.profile,
    );
    final palette = context.palette;
    final l10n = context.l10n;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: AppColors.passportShadow,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 150,
                height: 100,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      right: 30,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: const OwnCover(),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: -2,
                      child: OwnStamp(
                        size: 56,
                        tilt: 4,
                        style: profile?.stamp ?? const ProfileStampStyle(),
                        initial: profile?.initial ?? '',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      '@${profile?.username ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.editProfileTitle,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: palette.accentText,
                      ),
                    ),
                  ],
                ),
              ),
              Image.asset(AppIcons.goHere, width: 20),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}
