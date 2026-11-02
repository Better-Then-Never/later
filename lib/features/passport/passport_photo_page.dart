import 'package:flutter/material.dart';

import '../../core/l10n/app_dates.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/world.dart';
import '../../shared/widgets/user/user_stamp.dart';
import '../stamps/ink_stamp.dart';
import 'passport_data.dart';
import 'passport_paper.dart';

/// The Passport's photo page (Figma 7039:799): the holder's stamp as the
/// photo, their name, username and home town, capsules / countries /
/// towns, their About me, the first country as a stamp, and the
/// machine-readable lines. The app does not know when an account was made,
/// so there is no "holder since".
class PassportPhotoPage extends StatelessWidget {
  const PassportPhotoPage({
    super.key,
    required this.uid,
    required this.profile,
    required this.world,
    required this.countryName,
  });

  final String uid;
  final UserProfile? profile;
  final WorldSummary world;
  final String Function(String code) countryName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = this.profile;
    final name = PassportData.splitName(profile?.name ?? '');
    final username = profile?.username ?? '';
    final homeTown = profile?.homeTown.trim() ?? '';
    final about = profile?.about.trim() ?? '';
    final capsules = profile?.stats.capsules ?? 0;
    final first = world.countries.isEmpty ? null : world.countries.first;
    final firstDay = first?.first;
    // Smaller on a short screen, where it would cover the words.
    final stampSize = MediaQuery.sizeOf(context).height < 700 ? 76.0 : 100.0;
    return PassportPaper(
      label: l10n.passportPhotoLabel,
      number: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                PassportFit(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UserStamp(userId: uid, size: 104, tilt: -2),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (name.hasSurname) ...[
                                  PassportField(
                                    name: l10n.passportSurname,
                                    value: name.surname.toUpperCase(),
                                  ),
                                  PassportField(
                                    name: l10n.passportGivenNames,
                                    value: name.given.toUpperCase(),
                                  ),
                                ] else if (name.given.isNotEmpty)
                                  PassportField(
                                    name: l10n.passportName,
                                    value: name.given.toUpperCase(),
                                  ),
                                if (username.isNotEmpty)
                                  PassportField(
                                    name: l10n.passportUsername,
                                    value: '@$username',
                                  ),
                                if (homeTown.isNotEmpty)
                                  PassportField(
                                    name: l10n.passportHomeTown,
                                    value: homeTown.toUpperCase(),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          PassportNumber(
                            value: capsules,
                            name: l10n.passportCapsulesLabel,
                          ),
                          PassportNumber(
                            value: world.countryCount,
                            name: l10n.passportCountriesLabel,
                          ),
                          PassportNumber(
                            value: world.cityCount,
                            name: l10n.passportTownsLabel,
                          ),
                        ],
                      ),
                      if (about.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text('“$about”', style: PassportStyles.quote),
                      ],
                    ],
                  ),
                ),
                // The first country, stamped low on the page.
                if (first != null && firstDay != null)
                  Positioned(
                    right: 4,
                    bottom: 0,
                    child: Transform.rotate(
                      angle: -0.14,
                      child: SizedBox(
                        width: stampSize,
                        height: stampSize,
                        child: FittedBox(
                          child: Opacity(
                            opacity: 0.85,
                            child: InkStamp(
                              ink: AppColors.capsuleGreen,
                              shape: InkStampShape.round,
                              top: countryName(first.code).toUpperCase(),
                              middle: AppDates.medium(
                                firstDay,
                                l10n.localeName,
                              ).toUpperCase(),
                              bottom: l10n.passportFirstEntry,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _Mrz(
            lines: [
              'P<LTR${PassportData.mrz([name.surname, name.given], length: 39)}',
              PassportData.mrz([
                username,
                '$capsules',
                '${world.countryCount}',
                '${world.cityCount}',
              ], length: 44),
            ],
          ),
        ],
      ),
    );
  }
}

/// The machine-readable lines at the foot of a page, shrunk to its width.
class _Mrz extends StatelessWidget {
  const _Mrz({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Text(line, maxLines: 1, softWrap: false, style: PassportStyles.mrz),
        ],
      ),
    ),
  );
}
