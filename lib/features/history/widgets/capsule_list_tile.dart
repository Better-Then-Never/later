import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../../../data/models/geo_position.dart';
import '../../../data/services/app_image_cache.dart';
import '../../../data/services/geocoding_service.dart';
import '../../map/current_location.dart';
import '../../../shared/styles/box_decorations.dart';
import '../../../shared/widgets/default_text.dart';
import '../../../shared/widgets/profile_page_divider.dart';
import '../capsule_labels.dart';
import '../history_controller.dart';
import '../../../core/l10n/app_dates.dart';
import '../../settings/device_settings_store.dart';

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

    final heart = screen.height * 0.03;
    // The heart's 44 dp tap target, centred on the heart and reaching into
    // the card's padding, so the card keeps its height (D-24).
    const padding = 14.0;
    final heartTarget = padding + heart / 2 - 22;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecorations.whiteCard(
          context,
        ).copyWith(color: isSelected ? context.palette.selectedCapsule : null),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(padding),
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
                            // Taps land on the target over it (below).
                            ExcludeSemantics(
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: heart,
                                color: isFavorite
                                    ? AppColors.materialRed
                                    : context.palette.iconMuted,
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
                                    child: CapsuleCountdown(
                                      openAt: capsule.openAt,
                                    ),
                                  ),
                                  SizedBox(height: screen.height * 0.008),
                                  _InfoRow(
                                    iconPath: AppIcons.capsulePrivacy,
                                    child: _ellipsized(
                                      capsule.privacy.visibilityLabel(
                                        context.l10n,
                                      ),
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
                                // Waiting → uploaded morphs in place (the capsule
                                // keeps its id): the pill crossfades and resizes.
                                AnimatedSize(
                                  duration: AppMotion.of(
                                    context,
                                    AppMotion.standard,
                                  ),
                                  curve: AppMotion.standardCurve,
                                  alignment: Alignment.centerRight,
                                  child: AnimatedSwitcher(
                                    duration: AppMotion.of(
                                      context,
                                      AppMotion.standard,
                                    ),
                                    switchInCurve: AppMotion.enter,
                                    switchOutCurve: AppMotion.exit,
                                    transitionBuilder: (child, animation) =>
                                        FadeTransition(
                                          opacity: animation,
                                          child: ScaleTransition(
                                            scale: Tween(
                                              begin: 0.85,
                                              end: 1.0,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        ),
                                    child: capsule.pending
                                        ? _Pill(
                                            key: const ValueKey('pending'),
                                            color: AppColors.warningOrange,
                                            child: _pillText(
                                              context,
                                              context.l10n.historyWaitingUpload,
                                            ),
                                          )
                                        : createdAt != null
                                        ? _Pill(
                                            key: const ValueKey('date'),
                                            color: AppColors.brandGreen,
                                            // Day.month.year like the app's other
                                            // date pills, in the app's language.
                                            child: _pillText(
                                              context,
                                              AppDates.short(
                                                createdAt,
                                                context.l10n.localeName,
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
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
            Positioned(
              top: heartTarget,
              right: heartTarget,
              width: 44,
              height: 44,
              child: Semantics(
                button: true,
                label: isFavorite
                    ? context.l10n.historyRemoveFromFavorites
                    : context.l10n.historyAddToFavorites,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onFavoriteTap,
                ),
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
  const _Pill({super.key, required this.color, required this.child});

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
    // A capsule waiting in the outbox shows its photo from the phone.
    if (url.startsWith('file:')) {
      return Image.file(
        File.fromUri(Uri.parse(url)),
        width: width,
        height: height,
        fit: BoxFit.cover,
        cacheWidth: AppImageCache.decodeWidth(
          width,
          MediaQuery.devicePixelRatioOf(context),
        ),
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    return Image(
      image: AppImageCache.provider(
        url,
        width: AppImageCache.decodeWidth(
          width,
          MediaQuery.devicePixelRatioOf(context),
        ),
      ),
      width: width,
      height: height,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, sync) =>
          sync || frame != null ? child : placeholder,
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
        final l10n = context.l10n;
        // Never an empty pill: a quiet ellipsis while looking it up, the
        // same fallback as the other place pills when the lookup fails
        // (offline, geocoder not ready).
        return _pillText(
          context,
          name ??
              (widget.capsule.location == null
                  ? l10n.placeNoLocation
                  : snapshot.connectionState == ConnectionState.done
                  ? l10n.placeUnknown
                  : '…'),
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
    final miles =
        context.select<DeviceSettingsStore, DistanceUnit>(
          (s) => s.distanceUnit,
        ) ==
        DistanceUnit.miles;
    if (meters == null) return _ellipsized(l10n.historyDistanceUnknown);
    // One decimal with the language's separator ("12.3", "12,3").
    final number = NumberFormat(
      '0.0',
      l10n.localeName,
    ).format(miles ? meters / metersPerMile : meters / 1000);
    return _ellipsized(
      miles
          ? l10n.historyDistanceFromYouMiles(number)
          : l10n.historyDistanceFromYou(number),
    );
  }
}

/// Metres in a statute mile.
const metersPerMile = 1609.344;

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
