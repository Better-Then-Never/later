import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/router/app_routes.dart';
import '../../core/l10n/app_dates.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/world.dart';
import '../../data/services/country_names.dart';
import '../../shared/widgets/popup/popup_notification_service.dart';
import '../users/user_directory.dart';
import 'passport_cover.dart';
import 'passport_data.dart';
import 'passport_photo_page.dart';
import 'passport_sheets.dart';
import 'passport_stamps_page.dart';
import 'passport_together_page.dart';
import 'passport_visas_page.dart';
import 'passport_year_page.dart';

/// The Passport booklet (Figma page 8 and page 14): the leaves of
/// [PassportData.book] in a page view, page dots and a hint under them.
/// [viewerWorld] (a friend's Passport) adds You and a friend; your own
/// Passport ends with your year when it has one.
class PassportBook extends StatefulWidget {
  const PassportBook({
    super.key,
    required this.uid,
    required this.world,
    this.viewerUid,
    this.viewerWorld,
    this.focusTown,
    this.now,
  });

  final String uid;
  final WorldSummary world;

  /// The signed-in user, when this is a friend's Passport.
  final String? viewerUid;
  final WorldSummary? viewerWorld;
  final String? focusTown;

  /// Today, for the year page (tests).
  final DateTime? now;

  @override
  State<PassportBook> createState() => PassportBookState();
}

class PassportBookState extends State<PassportBook> {
  PageController? _pages;
  int _page = 0;
  final Map<int, GlobalKey> _shots = {};
  Map<String, String> _names = const {};
  String? _asked;

  bool get _friend => widget.viewerUid != null && widget.viewerWorld != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _askNames();
  }

  @override
  void didUpdateWidget(PassportBook oldWidget) {
    super.didUpdateWidget(oldWidget);
    _askNames();
  }

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  void _askNames() {
    final language = context.l10n.localeName;
    final codes = {
      for (final c in widget.world.countries) c.code,
      for (final c in widget.viewerWorld?.countries ?? const <CountryVisit>[])
        c.code,
    }.toList()..sort();
    final key = '$language:${codes.join(',')}';
    if (key == _asked) return;
    _asked = key;
    context.read<CountryNames>().of(codes, language).then((names) {
      if (mounted && _asked == key) setState(() => _names = names);
    });
  }

  String _country(String code) => _names[code] ?? code;

  GlobalKey _shot(int page) => _shots.putIfAbsent(page, GlobalKey.new);

  void _turnTo(int page) {
    final pages = _pages;
    if (pages == null || !pages.hasClients) return;
    if (AppMotion.reduced(context)) {
      pages.jumpToPage(page);
    } else {
      unawaited(
        pages.animateToPage(
          page,
          duration: AppMotion.slow,
          curve: AppMotion.emphasizedCurve,
        ),
      );
    }
  }

  /// Sends the open page as a picture (Figma 7192:1508).
  Future<void> share() async {
    final l10n = context.l10n;
    final boundary = _shots[_page]?.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary || !boundary.hasSize) return;
    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('no png');
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              data.buffer.asUint8List(),
              mimeType: 'image/png',
              name: 'later_passport.png',
            ),
          ],
          fileNameOverrides: const ['later_passport.png'],
          text: l10n.passportShareText,
        ),
      );
    } catch (e) {
      AppLogger.debug('Passport share failed: $e');
      if (mounted) {
        PopupNotificationService.showError(
          context: context,
          message: l10n.profileErrorShare,
          position: NotificationPosition.bottom,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final world = widget.world;
    final profile = context.select<UserDirectory, UserProfile?>(
      (d) => d.profile(widget.uid),
    );
    final firstName = (profile?.name ?? '').trim().split(' ').first;
    final towns = PassportData.towns(world);
    final year = _friend
        ? null
        : PassportData.year(world, (widget.now ?? DateTime.now()).year);
    final leaves = PassportData.book(
      world,
      together: _friend,
      year: year != null,
    );
    final comparison = _friend
        ? PassportData.compare(widget.viewerWorld!, world)
        : null;
    final pages = _pages ??= PageController(
      initialPage: _page = PassportData.openAt(
        leaves,
        towns,
        focusTown: widget.focusTown,
      ),
    );
    if (_page >= leaves.length) _page = leaves.length - 1;

    void openTown(PassportTown town, int index) => PassportStampSheet.show(
      context,
      town: town,
      index: index,
      countryName: _country(town.countryCode),
    );

    Widget leaf(int i) {
      final leaf = leaves[i];
      return switch (leaf.kind) {
        PassportLeafKind.cover => PassportCover(
          line: _friend && firstName.isNotEmpty
              ? l10n.passportCoverFriend(firstName)
              : l10n.passportCoverOwn,
          onOpen: () => _turnTo(i + 1),
        ),
        PassportLeafKind.together => PassportTogetherPage(
          myUid: widget.viewerUid!,
          friendUid: widget.uid,
          friendName: firstName,
          comparison: comparison!,
          countryName: _country,
          onTapTown: openTown,
        ),
        PassportLeafKind.photo => PassportPhotoPage(
          uid: widget.uid,
          profile: profile,
          world: world,
          countryName: _country,
        ),
        PassportLeafKind.empty => PassportEmptyPage(
          number: leaf.number,
          text: _friend
              ? l10n.passportEmptyFriend(firstName)
              : l10n.passportEmptyBody,
          onMake: _friend ? null : () => AppRoutes.toCamera(context),
        ),
        PassportLeafKind.stamps => PassportStampsPage(
          towns: towns.sublist(leaf.start, leaf.start + leaf.count),
          first: leaf.start,
          number: leaf.number,
          countryName: _country,
          onTap: openTown,
        ),
        PassportLeafKind.visas => PassportVisasPage(
          countries: world.countries.sublist(
            leaf.start,
            leaf.start + leaf.count,
          ),
          first: leaf.start,
          number: leaf.number,
          countryName: _country,
          onTap: (country, index) => PassportVisaSheet.show(
            context,
            country: country,
            index: index,
            name: _country(country.code),
          ),
        ),
        PassportLeafKind.year => PassportYearPage(
          year: year!,
          number: leaf.number,
          countryName: _country,
          about: profile?.about ?? '',
        ),
      };
    }

    final kind = leaves[_page].kind;
    final hint = switch (kind) {
      PassportLeafKind.cover => l10n.passportTapToOpen,
      PassportLeafKind.together when firstName.isNotEmpty =>
        l10n.passportFriendHint(firstName),
      PassportLeafKind.stamps => l10n.passportStampsHint,
      PassportLeafKind.visas => l10n.passportVisasHint,
      _ => l10n.passportSwipeHint,
    };
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: pages,
            itemCount: leaves.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final shot = RepaintBoundary(key: _shot(i), child: leaf(i));
              if (leaves[i].kind != PassportLeafKind.cover) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: shot,
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(40, 24, 40, 8),
                child: Column(
                  children: [
                    Expanded(child: Center(child: shot)),
                    const SizedBox(height: 14),
                    _CoverTotals(world: world),
                  ],
                ),
              );
            },
          ),
        ),
        _Dots(count: leaves.length, current: _page),
        Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottom),
          child: Text(
            hint,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              color: palette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Under the cover: "16 countries · 21 towns · stamps since 12 Mar 2025".
class _CoverTotals extends StatelessWidget {
  const _CoverTotals({required this.world});

  final WorldSummary world;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final since = PassportData.since(world);
    final parts = [
      l10n.profileCountries(world.countryCount),
      l10n.profileTowns(world.cityCount),
      if (since != null)
        l10n.passportStampsSince(AppDates.medium(since, l10n.localeName)),
    ];
    return Text(
      parts.join(' · '),
      textAlign: TextAlign.center,
      style: AppTextStyles.body.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: context.palette.textSecondary,
      ),
    );
  }
}

/// The page dots: the open page a green pill.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // A long book: the page and the count instead of a row of dots.
    if (count > 14) {
      return Text(
        '${current + 1} / $count',
        style: AppTextStyles.body.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: palette.textSecondary,
        ),
      );
    }
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: AppMotion.standard,
              curve: AppMotion.standardCurve,
              width: i == current ? 16 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i == current ? AppColors.brandGreen : palette.textFaint,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}
