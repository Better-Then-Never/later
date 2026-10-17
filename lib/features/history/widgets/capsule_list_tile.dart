import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../data/models/geo_position.dart';
import '../../../data/services/geocoding_service.dart';
import '../../map/current_location.dart';
import '../../../shared/styles/box_decorations.dart';
import '../../../shared/widgets/default_text.dart';
import '../../../shared/widgets/profile_page_divider.dart';
import '../capsule_labels.dart';
import '../history_controller.dart';

/// One capsule in the History list.
///
/// Null-safe for capsules without a location, image or dates (BUG-060,
/// BUG-064); the info rows ellipsize instead of overflowing on narrow
/// phones (BUG-065); only the countdown text ticks, and only while the
/// capsule is still closed and the page is visible (BUG-061).
class CapsuleListTile extends StatelessWidget {
  const CapsuleListTile({
    super.key,
    required this.capsule,
    required this.isFavorite,
    required this.onFavoriteTap,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  final Capsule capsule;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final createdAt = capsule.createdAt;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecorations.whiteCard(
          context,
        ).copyWith(color: isSelected ? context.palette.selectedCapsule : null),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: _Thumbnail(
                url: capsule.imageUrl,
                width: screen.width * 0.2,
                height: screen.height * 0.15,
              ),
            ),
            SizedBox(width: screen.width * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DefaultText(
                          capsule.title,
                          fontWeight: FontWeight.w500,
                          fontSize: screen.width * 0.04,
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Image.asset(
                        AppIcons.capsulePin(capsule.color.name),
                        width: screen.height * 0.025,
                      ),
                      SizedBox(width: screen.width * 0.01),
                      Semantics(
                        button: true,
                        label: isFavorite
                            ? context.l10n.historyRemoveFromFavorites
                            : context.l10n.historyAddToFavorites,
                        child: GestureDetector(
                          onTap: onFavoriteTap,
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: screen.height * 0.03,
                            color: isFavorite
                                ? AppColors.materialRed
                                : context.palette.iconMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screen.height * 0.004),
                  const ProfilePageDivider(width: double.infinity),
                  SizedBox(height: screen.height * 0.016),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(
                              iconPath: AppIcons.capsuleTimer,
                              child: CapsuleCountdown(openAt: capsule.openAt),
                            ),
                            SizedBox(height: screen.height * 0.008),
                            _InfoRow(
                              iconPath: AppIcons.capsulePrivacy,
                              child: _ellipsized(
                                capsule.privacy.visibilityLabel(context.l10n),
                              ),
                            ),
                            SizedBox(height: screen.height * 0.008),
                            _InfoRow(
                              iconPath: AppIcons.capsuleLocation,
                              child: _Distance(capsule: capsule),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(height: screen.height * 0.005),
                          _Pill(
                            color: AppColors.placeYellow,
                            child: _PlaceName(capsule: capsule),
                          ),
                          SizedBox(height: screen.height * 0.005),
                          if (createdAt != null)
                            _Pill(
                              color: AppColors.brandGreen,
                              // Day.month.year like the app's other date
                              // pills, in the app's language.
                              child: _pillText(
                                context,
                                DateFormat(
                                  'd.M.y',
                                  context.l10n.localeName,
                                ).format(createdAt),
                              ),
                            ),
                        ],
                      ),
                    ],
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

Widget _ellipsized(String text) =>
    DefaultText(text, maxLines: 1, overflow: TextOverflow.ellipsis);

Widget _pillText(BuildContext context, String text) => Text(
  text,
  style: TextStyle(
    fontSize: MediaQuery.sizeOf(context).width * 0.04,
    fontFamily: kAppFontFamily,
    fontWeight: FontWeight.bold,
    color: AppColors.onAccent,
  ),
);

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.iconPath, required this.child});

  final String iconPath;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Row(
      children: [
        Image.asset(iconPath, width: width * 0.05),
        SizedBox(width: width * 0.01),
        Flexible(child: child),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return Container(
      width: screen.width * 0.23,
      height: screen.height * 0.035,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(25),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screen.width * 0.02,
            vertical: screen.height * 0.003,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.url,
    required this.width,
    required this.height,
  });

  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: context.palette.skeleton,
      // Stands in for the capsule's photo: white glyph in both themes.
      child: const Icon(Icons.lock_clock, color: AppColors.onMedia),
    );
    final url = this.url;
    if (url == null || url.isEmpty) return placeholder;
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      cacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).round(),
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

/// Place name of the capsule, looked up once (cached by GeocodingService)
/// instead of by every tile on every scroll.
class _PlaceName extends StatefulWidget {
  const _PlaceName({required this.capsule});

  final Capsule capsule;

  @override
  State<_PlaceName> createState() => _PlaceNameState();
}

class _PlaceNameState extends State<_PlaceName> {
  Future<String?>? _name;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _name ??= _lookup();
  }

  @override
  void didUpdateWidget(_PlaceName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.capsule.location != widget.capsule.location) {
      _name = _lookup();
    }
  }

  Future<String?> _lookup() async {
    final location = widget.capsule.location;
    if (location == null) return null;
    return context.read<GeocodingService>().placeName(location);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _name,
      builder: (context, snapshot) {
        final name = snapshot.data;
        return _pillText(
          context,
          name ??
              (widget.capsule.location == null
                  ? context.l10n.placeNoLocation
                  : ''),
        );
      },
    );
  }
}

class _Distance extends StatelessWidget {
  const _Distance({required this.capsule});

  final Capsule capsule;

  @override
  Widget build(BuildContext context) {
    final here = context.select<CurrentLocation, GeoPosition?>(
      (l) => l.position,
    );
    final meters = HistoryController.distanceMeters(here, capsule.location);
    final l10n = context.l10n;
    return _ellipsized(
      meters == null
          ? l10n.historyDistanceUnknown
          : l10n.historyDistanceFromYou(
              // One decimal with the language's separator ("12.3", "12,3").
              NumberFormat('0.0', l10n.localeName).format(meters / 1000),
            ),
    );
  }
}

/// "Capsule is opened!" or the time left until it opens.
class CapsuleCountdown extends StatefulWidget {
  const CapsuleCountdown({super.key, required this.openAt});

  final DateTime? openAt;

  /// The countdown text in the app's language: widgets pass `context.l10n`,
  /// without it [AppL10n.current] is used.
  static String format(
    DateTime? openAt,
    DateTime now, {
    AppLocalizations? l10n,
  }) {
    final strings = l10n ?? AppL10n.current;
    if (openAt == null) return strings.historyCapsuleOpened;
    final diff = openAt.difference(now);
    if (diff.inSeconds <= 0) return strings.historyCapsuleOpened;

    final years = diff.inDays ~/ 365;
    final days = diff.inDays % 365;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;
    return years > 0
        ? strings.historyCountdownYears(years, days, hours, minutes)
        : strings.historyCountdown(days, hours, minutes, seconds);
  }

  @override
  State<CapsuleCountdown> createState() => _CapsuleCountdownState();
}

class _CapsuleCountdownState extends State<CapsuleCountdown> {
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void didUpdateWidget(CapsuleCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openAt != widget.openAt) _schedule();
  }

  /// Ticks once per second while the capsule is closed and the page is
  /// visible (TickerMode is off for hidden tabs of the IndexedStack).
  void _schedule() {
    final openAt = widget.openAt;
    final shouldTick =
        TickerMode.of(context) &&
        openAt != null &&
        openAt.isAfter(DateTime.now());
    if (!shouldTick) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
        if (!widget.openAt!.isAfter(DateTime.now())) _schedule();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ellipsized(
      CapsuleCountdown.format(
        widget.openAt,
        DateTime.now(),
        l10n: context.l10n,
      ),
    );
  }
}
