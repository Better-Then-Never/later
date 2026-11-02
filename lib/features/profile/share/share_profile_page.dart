import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/session/session_controller.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_profile.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/pill_v2.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../postcard/own_postcard.dart';
import '../postcard/profile_postcard.dart';
import 'sharing_service.dart';

/// Your Later card (Figma page 14 `7189:723`, `7189:812`): the postcard of
/// your profile as a card to send. Tap it to turn it over: the back is a
/// written postcard with your words, your stamp, a postmark and the code
/// that adds you. Share sends the side in view as a picture with your link.
class ShareProfilePage extends StatefulWidget {
  const ShareProfilePage({super.key});

  @override
  State<ShareProfilePage> createState() => _ShareProfilePageState();
}

class _ShareProfilePageState extends State<ShareProfilePage> {
  final _card = GlobalKey();
  bool _back = false;
  bool _sharing = false;

  Future<void> _share(String uid, String name) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final l10n = context.l10n;
    final link = SharingService.generateProfileLink(uid);
    try {
      final boundary =
          _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              png!.buffer.asUint8List(),
              mimeType: 'image/png',
              name: 'later_card.png',
            ),
          ],
          text: l10n.profileShareMessage(name, link),
          subject: l10n.profileShareSubject(name),
        ),
      );
    } catch (e) {
      AppLogger.warning('Later card not shared', error: e);
      if (mounted) {
        PopupNotificationService.showError(
          context: context,
          message: l10n.profileErrorShare,
          position: NotificationPosition.bottom,
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    // Always the real uid: the code and link were built from 'No User'
    // until the profile had loaded (BUG-092).
    final uid = context.read<SessionController>().uid!;
    final profile = context.select<SessionController, UserProfile?>(
      (s) => s.profile,
    );
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            PageHeaderV2(
              title: l10n.laterCardTitle,
              onBack: () => Navigator.pop(context),
              backLabel: l10n.commonBack,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _back = !_back),
                    child: RepaintBoundary(
                      key: _card,
                      child: _Flip(
                        back: _back,
                        front: LaterCardFront(uid: uid, profile: profile),
                        backSide: LaterCardBack(uid: uid, profile: profile),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _back ? l10n.laterCardTurnBack : l10n.laterCardTurn,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: l10n.laterCardSide(_back ? 2 : 1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Dot(on: !_back),
                        const SizedBox(width: 6),
                        _Dot(on: _back),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PillV2(
                        label: l10n.profileShare,
                        onTap: _sharing
                            ? null
                            : () => _share(uid, profile?.name ?? ''),
                      ),
                      const SizedBox(width: 10),
                      PillV2(
                        label: l10n.profileCopyLink,
                        kind: PillV2Kind.outline,
                        onTap: () => SharingService.copyProfileLink(
                          context: context,
                          userId: uid,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: Semantics(
                      button: true,
                      child: GestureDetector(
                        onTap: () => AppRoutes.scanProfileQr(context),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            l10n.laterCardScanFriend,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: palette.accentText,
                            ),
                          ),
                        ),
                      ),
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

class _Dot extends StatelessWidget {
  const _Dot({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: AppMotion.standard,
    width: on ? 16 : 6,
    height: 6,
    decoration: BoxDecoration(
      color: on ? AppColors.brandGreen : context.palette.divider,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

/// Turns the card over around its vertical axis; the side facing away is
/// hidden at the half-way point.
class _Flip extends StatelessWidget {
  const _Flip({
    required this.back,
    required this.front,
    required this.backSide,
  });

  final bool back;
  final Widget front;
  final Widget backSide;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: back ? 1 : 0),
      duration: AppMotion.reduced(context) ? Duration.zero : AppMotion.reveal,
      curve: AppMotion.emphasizedCurve,
      builder: (context, t, _) {
        final showBack = t > 0.5;
        final angle = t * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          child: showBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: backSide,
                )
              : front,
        );
      },
    );
  }
}

/// The card's front: the profile's postcard, with the Later mark and link
/// instead of the numbers.
class LaterCardFront extends StatelessWidget {
  const LaterCardFront({super.key, required this.uid, required this.profile});

  final String uid;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final about = profile?.about.trim() ?? '';
    final town = profile?.homeTown.trim() ?? '';
    final username = profile?.username ?? '';
    final link = SharingService.generateProfileLink(uid);
    return ProfilePostcard(
      photoHeight: 230,
      cover: const OwnCover(),
      stamp: OwnStamp(
        size: ProfilePostcard.stampSize,
        tilt: 4,
        style: profile?.stamp ?? const ProfileStampStyle(),
        initial: profile?.initial ?? '',
      ),
      name: Text(
        profile?.name ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.body.copyWith(
          fontSize: 24,
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
          fontSize: 13,
          color: palette.textSecondary,
        ),
      ),
      about: about.isEmpty
          ? const SizedBox.shrink()
          : StampSpeechBubble(
              child: Text(about, style: StampSpeechBubble.textStyle(context)),
            ),
      counts: Row(
        children: [
          Image.asset(AppImages.laterLogo, width: 22, height: 22),
          const SizedBox(width: 6),
          Text(
            'Later',
            style: AppTextStyles.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: palette.accentText,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              link.replaceFirst(RegExp('^https?://'), ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                color: palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The card's back: a written postcard. Your words on ruled lines, signed;
/// your stamp, a postmark with today and your town; the code that adds you
/// and your name, username and link on address lines.
class LaterCardBack extends StatelessWidget {
  const LaterCardBack({super.key, required this.uid, required this.profile});

  final String uid;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final about = profile?.about.trim() ?? '';
    final first = (profile?.name ?? '').split(' ').first;
    final link = SharingService.generateProfileLink(uid);
    final hand = AppTextStyles.body.copyWith(
      fontSize: 17,
      height: 1.75,
      fontStyle: FontStyle.italic,
      color: palette.textPrimary,
    );
    TextStyle address(bool bold) => AppTextStyles.body.copyWith(
      fontSize: 13,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: bold ? palette.textPrimary : palette.textSecondary,
    );
    Widget line() => Divider(height: 10, thickness: 1, color: palette.divider);
    return Semantics(
      label: l10n.laterCardBack,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        height: 430,
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: AppColors.passportShadow,
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Expanded(
                    child: CustomPaint(
                      painter: _RuledLines(palette.divider, 17 * 1.75),
                      child: Text(
                        about.isEmpty ? '' : '$about\n— $first',
                        style: hand,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                  ),
                  Text(
                    l10n.laterCardScanMe,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: palette.accentText,
                    ),
                  ),
                ],
              ),
            ),
            VerticalDivider(width: 24, thickness: 1, color: palette.divider),
            SizedBox(
              width: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 90,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          top: 4,
                          child: _Postmark(town: profile?.homeTown ?? ''),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: OwnStamp(
                            size: 66,
                            tilt: 3,
                            style: profile?.stamp ?? const ProfileStampStyle(),
                            initial: profile?.initial ?? '',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  QrImageView(
                    data: link,
                    size: 130,
                    padding: EdgeInsets.zero,
                    backgroundColor: palette.surface,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: palette.textPrimary,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: palette.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    profile?.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: address(true),
                  ),
                  line(),
                  Text(
                    '@${profile?.username ?? ''}',
                    maxLines: 1,
                    style: address(false),
                  ),
                  line(),
                  Text(
                    link.replaceFirst(RegExp('^https?://'), ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: address(false),
                  ),
                  line(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lines to write on, [step] apart (the text's line height).
class _RuledLines extends CustomPainter {
  _RuledLines(this.color, this.step);

  final Color color;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var y = step - 2; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_RuledLines old) => old.color != color || old.step != step;
}

/// A round postmark in passport ink: "LATER POST", today, the town.
class _Postmark extends StatelessWidget {
  const _Postmark({required this.town});

  final String town;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final day = MaterialLocalizations.of(context).formatMediumDate(now);
    final style = AppTextStyles.body.copyWith(
      fontSize: 8,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.8,
      color: AppColors.passportInk,
    );
    return Transform.rotate(
      angle: -0.2,
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.passportInk, width: 1.5),
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.passportInk.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (town.trim().isNotEmpty)
                Text(
                  town.trim().toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              Text(day.toUpperCase(), style: style.copyWith(fontSize: 9)),
              Text(l10n.laterCardPost, style: style),
            ],
          ),
        ),
      ),
    );
  }
}
