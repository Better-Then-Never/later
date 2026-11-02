import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'passport_data.dart';
import 'passport_paper.dart';

/// The Passport's last page, your year (Figma 7192:1157): the year in big
/// type, the countries visited in it and the new ones, each country on the
/// month line at its latest visit, the new countries by name, your About
/// me. The summary keeps no towns or capsules per year (and no trips), so
/// the drawing's towns, capsules, "longest away" and "most capsules" are
/// left out.
class PassportYearPage extends StatelessWidget {
  const PassportYearPage({
    super.key,
    required this.year,
    required this.number,
    required this.countryName,
    this.about = '',
  });

  final PassportYear year;
  final int number;
  final String Function(String code) countryName;
  final String about;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final about = this.about.trim();
    return PassportPaper(
      label: l10n.passportYearLabel,
      number: number,
      child: PassportFit(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '${year.year}',
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 64,
                  height: 1.05,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  color: AppColors.passportInk,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                PassportNumber(
                  value: year.countryCount,
                  name: l10n.passportCountriesLabel,
                ),
                PassportNumber(
                  value: year.entered.length,
                  name: l10n.passportNewLabel,
                ),
              ],
            ),
            const PassportRule(),
            _MonthLine(year: year),
            const SizedBox(height: 4),
            Text(
              l10n.passportYearMonthsNote,
              style: PassportStyles.field.copyWith(letterSpacing: 0),
            ),
            const PassportRule(),
            if (year.entered.isNotEmpty)
              PassportField(
                name: l10n.passportNewThisYear,
                value: year.entered.map(countryName).join(', '),
              ),
            if (about.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('“$about”', style: PassportStyles.quote),
            ],
          ],
        ),
      ),
    );
  }
}

/// January to December on a line, the year's countries as small round
/// stamps over their months (three at most per month, then "+2").
class _MonthLine extends StatelessWidget {
  const _MonthLine({required this.year});

  final PassportYear year;

  static const _perMonth = 3;
  static const _stamp = 32.0;
  static const _step = 24.0;
  static const _lift = 12.0;

  @override
  Widget build(BuildContext context) {
    final locale = context.l10n.localeName;
    final byMonth = <int, List<PassportYearVisit>>{};
    for (final v in year.visits) {
      (byMonth[v.month] ??= []).add(v);
    }
    const height = _stamp + _step * (_perMonth - 1) + _lift + 4;
    return LayoutBuilder(
      builder: (context, box) {
        final col = box.maxWidth / 12;
        var ink = 0;
        return Column(
          children: [
            SizedBox(
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final entry in byMonth.entries)
                    for (
                      var i = 0;
                      i < entry.value.length && i < _perMonth;
                      i++
                    )
                      Positioned(
                        left: (entry.key - 1) * col + col / 2 - _stamp / 2,
                        // Every other month a little higher: neighbours overlap less.
                        bottom: i * _step + (entry.key.isEven ? _lift : 0),
                        child: Transform.rotate(
                          angle: PassportStyles.tiltAt(ink),
                          child: _CodeStamp(
                            code:
                                i == _perMonth - 1 &&
                                    entry.value.length > _perMonth
                                ? '+${entry.value.length - _perMonth + 1}'
                                : entry.value[i].code,
                            ink: PassportStyles.inkAt(ink++),
                          ),
                        ),
                      ),
                ],
              ),
            ),
            Container(
              height: 1.5,
              margin: const EdgeInsets.symmetric(vertical: 6),
              color: AppColors.passportInk.withValues(alpha: 0.6),
            ),
            Row(
              children: [
                for (var m = 1; m <= 12; m++)
                  Expanded(
                    child: Text(
                      DateFormat('MMMMM', locale).format(DateTime(2000, m)),
                      textAlign: TextAlign.center,
                      style: PassportStyles.field.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _CodeStamp extends StatelessWidget {
  const _CodeStamp({required this.code, required this.ink});

  final String code;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
    width: _MonthLine._stamp,
    height: _MonthLine._stamp,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.passportPaper,
      shape: BoxShape.circle,
      border: Border.all(color: ink, width: 1.6),
    ),
    child: Text(
      code,
      style: TextStyle(
        fontFamily: kAppFontFamily,
        fontSize: 11,
        height: 1,
        fontWeight: FontWeight.bold,
        color: ink,
      ),
    ),
  );
}
