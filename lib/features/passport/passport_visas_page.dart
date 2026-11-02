import 'package:flutter/material.dart';

import '../../core/l10n/app_dates.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/world.dart';
import '../stamps/guilloche.dart';
import 'passport_data.dart';
import 'passport_paper.dart';

/// A page of visas (Figma 7192:980): up to three countries, each a framed
/// block with a coloured band; a tap opens the country's towns.
class PassportVisasPage extends StatelessWidget {
  const PassportVisasPage({
    super.key,
    required this.countries,
    required this.first,
    required this.number,
    required this.countryName,
    required this.onTap,
  });

  final List<CountryVisit> countries;

  /// The index of [countries]' first visa in the book (its colour).
  final int first;
  final int number;
  final String Function(String code) countryName;
  final void Function(CountryVisit country, int index) onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PassportPaper(
      label: l10n.passportVisasLabel,
      number: number,
      child: Column(
        children: [
          for (var i = 0; i < PassportData.visasPerPage; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Expanded(
              child: i < countries.length
                  ? PassportVisa(
                      country: countries[i],
                      name: countryName(countries[i].code),
                      ink: PassportStyles.inkAt(first + i),
                      onTap: () => onTap(countries[i], first + i),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }
}

/// One country's visa: "VISA · PL", the name in big type, the first entry,
/// its towns and capsules in Later, and a machine-readable line of towns.
class PassportVisa extends StatelessWidget {
  const PassportVisa({
    super.key,
    required this.country,
    required this.name,
    required this.ink,
    this.onTap,
  });

  final CountryVisit country;
  final String name;
  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final first = country.first;
    final inLater = [
      l10n.profileTowns(country.cities.length),
      l10n.worldCapsules(country.capsules),
    ].join(' · ');
    return Semantics(
      button: onTap != null,
      label: [
        name,
        if (first != null) AppDates.medium(first, l10n.localeName),
        inLater,
      ].join('. '),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.passportPaper,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ink, width: 1.5),
          ),
          child: Stack(
            children: [
              // The visa's own print, at its right edge.
              const Positioned(
                right: -60,
                top: -20,
                bottom: -20,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Opacity(
                    opacity: 0.16,
                    child: CustomPaint(painter: GuillochePainter()),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 8,
                child: ColoredBox(color: ink),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 10, 6),
                  child: PassportFit(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.passportVisa} · ${country.code}',
                          style: PassportStyles.field.copyWith(
                            color: ink,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: kAppFontFamily,
                            fontSize: 22,
                            height: 1.15,
                            letterSpacing: 1,
                            fontWeight: FontWeight.bold,
                            color: AppColors.passportInk,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (first != null)
                              Expanded(
                                child: _Cell(
                                  name: l10n.passportFirstEntry,
                                  value: AppDates.medium(
                                    first,
                                    l10n.localeName,
                                  ).toUpperCase(),
                                ),
                              ),
                            Expanded(
                              child: _Cell(
                                name: l10n.passportInLater,
                                value: inLater,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ExcludeSemantics(
                          child: Text(
                            'V<${PassportData.mrz([country.code, country.towns.join(' ')], length: 34)}',
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                            style: PassportStyles.mrz.copyWith(
                              fontSize: 9.5,
                              letterSpacing: 1.1,
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
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.name, required this.value});

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(name, style: PassportStyles.field),
      Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: PassportStyles.value.copyWith(fontSize: 12.5),
      ),
    ],
  );
}
