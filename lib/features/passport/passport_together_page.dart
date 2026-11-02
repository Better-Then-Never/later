import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/user/user_stamp.dart';
import 'passport_data.dart';
import 'passport_paper.dart';
import 'passport_stamps_page.dart';

/// You and a friend (Figma 7192:1306), in the friend's Passport: both
/// stamps, what you both have (the towns as stamps), the countries only
/// they have and only you have.
class PassportTogetherPage extends StatelessWidget {
  const PassportTogetherPage({
    super.key,
    required this.myUid,
    required this.friendUid,
    required this.friendName,
    required this.comparison,
    required this.countryName,
    required this.onTapTown,
  });

  final String myUid;
  final String friendUid;

  /// The friend's first name.
  final String friendName;
  final PassportComparison comparison;
  final String Function(String code) countryName;
  final void Function(PassportTown town, int index) onTapTown;

  /// Towns both have, shown as stamps; more are counted.
  static const shownTowns = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final towns = comparison.towns;
    final upper = friendName.toUpperCase();
    String list(List<String> codes) =>
        codes.isEmpty ? l10n.passportNone : codes.map(countryName).join(', ');
    return PassportPaper(
      label: l10n.passportTogetherLabel(upper),
      child: PassportFit(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SizedBox(
                width: 150,
                height: 86,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 4,
                      child: UserStamp(userId: myUid, size: 76, tilt: -6),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: UserStamp(userId: friendUid, size: 76, tilt: 5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                l10n.passportTogetherBoth(
                  l10n.profileCountries(comparison.countries.length),
                  l10n.profileTowns(towns.length),
                ),
                textAlign: TextAlign.center,
                style: PassportStyles.value.copyWith(
                  fontSize: 15,
                  color: AppColors.passportInk,
                ),
              ),
            ),
            const PassportRule(),
            Text(l10n.passportBothLabel, style: PassportStyles.field),
            const SizedBox(height: 6),
            if (towns.isEmpty)
              Text(
                l10n.passportNothingShared,
                style: PassportStyles.value.copyWith(
                  fontWeight: FontWeight.normal,
                ),
              )
            else
              SizedBox(
                height: 104,
                child: Row(
                  children: [
                    for (var i = 0; i < towns.length && i < shownTowns; i++)
                      Expanded(
                        child: Semantics(
                          button: true,
                          label:
                              '${towns[i].town}. '
                              '${countryName(towns[i].countryCode)}',
                          excludeSemantics: true,
                          child: GestureDetector(
                            onTap: () => onTapTown(towns[i], i),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Transform.rotate(
                                angle: PassportStyles.tiltAt(i),
                                child: FittedBox(
                                  child: Opacity(
                                    opacity: 0.9,
                                    child: PassportTownStamp(
                                      town: towns[i],
                                      index: i,
                                      countryName: countryName(
                                        towns[i].countryCode,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (towns.length > shownTowns)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          '+${towns.length - shownTowns}',
                          style: PassportStyles.value.copyWith(
                            color: AppColors.passportInk,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const PassportRule(),
            PassportField(
              name: l10n.passportOnlyThem(upper),
              value: list(comparison.onlyTheirs),
            ),
            const SizedBox(height: 4),
            PassportField(
              name: l10n.passportOnlyYou,
              value: list(comparison.onlyMine),
            ),
          ],
        ),
      ),
    );
  }
}
