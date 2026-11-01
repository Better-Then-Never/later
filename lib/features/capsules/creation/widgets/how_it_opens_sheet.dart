import 'package:flutter/material.dart';

import '../../../../core/l10n/app_dates.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/capsule.dart';
import '../../../../shared/widgets/app_radio.dart';
import '../../../../shared/widgets/app_sheets.dart';
import '../capsule_creation_controller.dart';
import 'open_date_calendar.dart';

/// When a capsule opens, as the "How it opens" sheet sets it.
enum OpenWhen { anytime, month, year, pick }

/// "How does it open?" (Figma "v3c Create / How sheet"): When (anytime, in a
/// month, in a year, a picked day) and Where (anywhere, or only back at this
/// spot, within 150 m: the server's lock, functions/lib/locks.js), the rule
/// in words in green, and Done. Returns the day it opens (null: anytime) and
/// where, or nothing when closed without Done.
class HowItOpensSheet extends StatefulWidget {
  const HowItOpensSheet({
    super.key,
    required this.openAt,
    required this.now,
    this.openWhere = OpenWhere.anywhere,
  });

  /// The day chosen so far (null: anytime).
  final DateTime? openAt;
  final DateTime now;

  /// Where chosen so far.
  final OpenWhere openWhere;

  /// The day the capsule opens and where, or `(cancelled: true)` when
  /// closed.
  static Future<({bool cancelled, DateTime? openAt, OpenWhere openWhere})> show(
    BuildContext context, {
    required DateTime? openAt,
    OpenWhere openWhere = OpenWhere.anywhere,
  }) async {
    final picked = await showEdgeSheet<({DateTime? openAt, OpenWhere where})>(
      context,
      (_) => HowItOpensSheet(
        openAt: openAt,
        openWhere: openWhere,
        now: DateTime.now(),
      ),
    );
    return (
      cancelled: picked == null,
      openAt: picked?.openAt,
      openWhere: picked?.where ?? openWhere,
    );
  }

  @override
  State<HowItOpensSheet> createState() => _HowItOpensSheetState();
}

class _HowItOpensSheetState extends State<HowItOpensSheet> {
  late OpenWhen _when;
  late OpenWhere _where = widget.openWhere;
  DateTime? _picked;

  DateTime get _month => CapsuleCreationController.addMonths(widget.now, 1);
  DateTime get _year => CapsuleCreationController.addMonths(widget.now, 12);

  @override
  void initState() {
    super.initState();
    final at = widget.openAt;
    if (at == null) {
      _when = OpenWhen.anytime;
    } else if (DateUtils.isSameDay(at, _month)) {
      _when = OpenWhen.month;
    } else if (DateUtils.isSameDay(at, _year)) {
      _when = OpenWhen.year;
    } else {
      _when = OpenWhen.pick;
      _picked = at;
    }
  }

  DateTime? get _openAt => switch (_when) {
    OpenWhen.anytime => null,
    OpenWhen.month => _month,
    OpenWhen.year => _year,
    OpenWhen.pick => _picked,
  };

  Future<void> _pick() async {
    final now = widget.now;
    final day = await OpenDateCalendar.show(
      context,
      first: now.add(const Duration(days: 1)),
      last: DateTime(now.year + 5, 12, 31),
      selected: _picked,
    );
    if (day != null && mounted) {
      setState(() {
        _picked = day;
        _when = OpenWhen.pick;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final openAt = _openAt;
    TextStyle label() => TextStyle(
      fontFamily: kAppFontFamily,
      fontSize: 12,
      height: 1.2,
      letterSpacing: 0.72,
      fontWeight: FontWeight.bold,
      color: palette.textSecondary,
    );
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: SheetHandle.v2()),
              Text(
                l10n.capsulesHowTitle,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: palette.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(l10n.capsulesHowWhen.toUpperCase(), style: label()),
              _Option(
                on: _when == OpenWhen.anytime,
                title: l10n.capsulesCreationAnytime,
                hint: l10n.capsulesHowAnytimeHint,
                onTap: () => setState(() => _when = OpenWhen.anytime),
              ),
              _Option(
                on: _when == OpenWhen.month,
                title: l10n.capsulesOpenInMonth,
                hint: AppDates.medium(_month, locale),
                onTap: () => setState(() => _when = OpenWhen.month),
              ),
              _Option(
                on: _when == OpenWhen.year,
                title: l10n.capsulesOpenInYear,
                hint: AppDates.medium(_year, locale),
                onTap: () => setState(() => _when = OpenWhen.year),
              ),
              _Option(
                on: _when == OpenWhen.pick,
                title: l10n.capsulesHowPick,
                hint: _picked == null
                    ? l10n.capsulesHowPickHint
                    : AppDates.medium(_picked!, locale),
                onTap: _pick,
              ),
              const SizedBox(height: 4),
              Text(l10n.capsulesHowWhere.toUpperCase(), style: label()),
              _Option(
                on: _where == OpenWhere.anywhere,
                title: l10n.capsulesHowAnywhere,
                hint: l10n.capsulesHowAnywhereHint,
                onTap: () => setState(() => _where = OpenWhere.anywhere),
              ),
              _Option(
                on: _where == OpenWhere.here,
                title: l10n.capsulesHowHere,
                hint: l10n.capsulesHowHereHint,
                onTap: () => setState(() => _where = OpenWhere.here),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  switch ((openAt, _where)) {
                    (null, OpenWhere.anywhere) =>
                      l10n.capsulesHowSummaryAnytime,
                    (null, OpenWhere.here) =>
                      l10n.capsulesHowSummaryAnytimeHere,
                    (final at?, OpenWhere.anywhere) =>
                      l10n.capsulesHowSummaryDate(AppDates.medium(at, locale)),
                    (final at?, OpenWhere.here) =>
                      l10n.capsulesHowSummaryDateHere(
                        AppDates.medium(at, locale),
                      ),
                  },
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.bold,
                    color: palette.accentText,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: AppColors.onAccent,
                    disabledBackgroundColor: palette.disabled,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  // A picked day must be picked first.
                  onPressed: _when == OpenWhen.pick && _picked == null
                      ? null
                      : () => Navigator.of(
                          context,
                        ).pop((openAt: openAt, where: _where)),
                  child: Text(
                    l10n.capsulesComposerDone,
                    style: const TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
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

/// One choice: a radio, the words and a grey line under them.
class _Option extends StatelessWidget {
  const _Option({
    required this.on,
    required this.title,
    required this.hint,
    required this.onTap,
  });

  final bool on;
  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: on,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              AppRadio(on: on, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 16,
                        height: 1.25,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      hint,
                      style: TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 13,
                        height: 1.25,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
