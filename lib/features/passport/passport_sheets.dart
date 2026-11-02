import 'package:flutter/material.dart';

import '../../core/l10n/app_dates.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/world.dart';
import '../../shared/widgets/app_sheets.dart';
import '../../shared/widgets/v2/card_v2.dart';
import 'passport_data.dart';
import 'passport_paper.dart';
import 'passport_stamps_page.dart';

/// A town's stamp opened (Figma 7039:1060): the stamp, the town, its
/// country, the first capsule (in the town when the app knows the day,
/// else in the country) and the capsules there. The app keeps no
/// position per town, so there is no "Show on the map".
class PassportStampSheet extends StatelessWidget {
  const PassportStampSheet({
    super.key,
    required this.town,
    required this.index,
    required this.countryName,
  });

  final PassportTown town;
  final int index;
  final String countryName;

  static Future<void> show(
    BuildContext context, {
    required PassportTown town,
    required int index,
    required String countryName,
  }) => showEdgeSheet<void>(
    context,
    (_) =>
        PassportStampSheet(town: town, index: index, countryName: countryName),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final firstHere = town.first;
    final firstThere = town.countryFirst;
    final when = firstHere != null
        ? l10n.passportStampFirstHere(
            AppDates.medium(firstHere, l10n.localeName),
          )
        : firstThere != null
        ? l10n.passportStampFirstIn(
            countryName,
            AppDates.medium(firstThere, l10n.localeName),
          )
        : null;
    return _Sheet(
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: FittedBox(
              child: PassportTownStamp(
                town: town,
                index: index,
                countryName: countryName,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  town.town,
                  style: AppTextStyles.sectionTitle.copyWith(
                    height: 1.2,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  countryName,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15,
                    color: palette.textSecondary,
                  ),
                ),
                if (when != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    when,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  l10n.worldCapsules(town.capsules),
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: palette.accentText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A visa opened: the visa again and its towns with their capsules.
class PassportVisaSheet extends StatelessWidget {
  const PassportVisaSheet({
    super.key,
    required this.country,
    required this.index,
    required this.name,
  });

  final CountryVisit country;
  final int index;
  final String name;

  static Future<void> show(
    BuildContext context, {
    required CountryVisit country,
    required int index,
    required String name,
  }) => showEdgeSheet<void>(
    context,
    (_) => PassportVisaSheet(country: country, index: index, name: name),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final first = country.first;
    final towns = country.towns;
    return _Sheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: AppTextStyles.sectionTitle.copyWith(
              height: 1.2,
              color: palette.textPrimary,
            ),
          ),
          if (first != null) ...[
            const SizedBox(height: 2),
            Text(
              l10n.passportStampFirstIn(
                name,
                AppDates.medium(first, l10n.localeName),
              ),
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: palette.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (towns.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: SingleChildScrollView(
                child: CardV2Rows(
                  children: [
                    for (var i = 0; i < towns.length; i++)
                      RowV2(
                        leading: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: PassportStyles.inkAt(index),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: towns[i],
                        value: l10n.worldCapsules(country.cities[towns[i]]!),
                        arrow: false,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The v2 sheet: surface, 28 dp top corners, the grabber.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.palette.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: SheetHandle.v2()),
            child,
          ],
        ),
      ),
    ),
  );
}
