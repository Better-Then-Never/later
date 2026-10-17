import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_sheets.dart';

/// The day a capsule opens, on the app's own calendar (F-27): a month at a
/// time (arrows or a swipe), days before [first] greyed out, a tap chooses.
class OpenDateCalendar extends StatefulWidget {
  const OpenDateCalendar({
    super.key,
    required this.first,
    required this.last,
    this.selected,
  });

  final DateTime first;
  final DateTime last;
  final DateTime? selected;

  /// The chosen day (midnight), or null when the sheet is dismissed.
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime first,
    required DateTime last,
    DateTime? selected,
  }) => showEdgeSheet<DateTime>(
    context,
    (_) => OpenDateCalendar(first: first, last: last, selected: selected),
  );

  @override
  State<OpenDateCalendar> createState() => _OpenDateCalendarState();
}

class _OpenDateCalendarState extends State<OpenDateCalendar> {
  late final DateTime _firstMonth = DateTime(
    widget.first.year,
    widget.first.month,
  );
  late final int _months =
      (widget.last.year - _firstMonth.year) * 12 +
      widget.last.month -
      _firstMonth.month +
      1;
  late final PageController _pages = PageController(
    initialPage: _monthIndex(widget.selected ?? widget.first),
  );
  late int _page = _pages.initialPage;

  int _monthIndex(DateTime d) =>
      ((d.year - _firstMonth.year) * 12 + d.month - _firstMonth.month).clamp(
        0,
        _months - 1,
      );

  DateTime _month(int index) =>
      DateTime(_firstMonth.year, _firstMonth.month + index);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final target = (_page + delta).clamp(0, _months - 1);
    _pages.animateToPage(
      target,
      duration: AppMotion.of(context, AppMotion.standard),
      curve: AppMotion.standardCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final title = DateFormat.yMMMM(locale).format(_month(_page));
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSheets.radius),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              Row(
                children: [
                  _Arrow(
                    left: true,
                    label: l10n.capsulesCalendarPrevious,
                    onTap: _page > 0 ? () => _go(-1) : null,
                  ),
                  Expanded(
                    child: Text(
                      // "октябрь 2026" -> "Октябрь 2026".
                      toBeginningOfSentenceCase(title, locale),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.pageTitle(
                        context,
                      ).copyWith(fontSize: 20),
                    ),
                  ),
                  _Arrow(
                    left: false,
                    label: l10n.capsulesCalendarNext,
                    onTap: _page < _months - 1 ? () => _go(1) : null,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _Weekdays(locale: locale),
              SizedBox(
                // Six rows of 44 dp at most.
                height: 6 * 46,
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _months,
                  onPageChanged: (p) => setState(() => _page = p),
                  itemBuilder: (context, i) => _MonthGrid(
                    month: _month(i),
                    first: widget.first,
                    last: widget.last,
                    selected: widget.selected,
                    onChosen: (day) {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop(day);
                    },
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

class _Arrow extends StatelessWidget {
  const _Arrow({required this.left, required this.label, this.onTap});

  final bool left;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = onTap == null
        ? context.palette.textMuted
        : context.palette.icon;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: 48,
          child: CustomPaint(
            painter: _ChevronPainter(left: left, color: color),
          ),
        ),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.left, required this.color});

  final bool left;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final c = size.center(Offset.zero);
    final d = left ? 1.0 : -1.0;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx + 4 * d, c.dy - 8)
        ..lineTo(c.dx - 4 * d, c.dy)
        ..lineTo(c.dx + 4 * d, c.dy + 8),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) =>
      old.left != left || old.color != color;
}

/// The day initials in the order of the language's week.
class _Weekdays extends StatelessWidget {
  const _Weekdays({required this.locale});

  final String locale;

  @override
  Widget build(BuildContext context) {
    final symbols = DateFormat.E(locale).dateSymbols;
    final first = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Text(
              symbols.STANDALONENARROWWEEKDAYS[(first + i) % 7],
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.palette.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.first,
    required this.last,
    required this.selected,
    required this.onChosen,
  });

  final DateTime month;
  final DateTime first;
  final DateTime last;
  final DateTime? selected;
  final ValueChanged<DateTime> onChosen;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final firstWeekday = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    // DateTime.weekday: Monday 1 ... Sunday 7; the index: Sunday 0.
    final lead = (month.weekday % 7 - firstWeekday) % 7;
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final today = DateTime.now();
    final firstDay = DateTime(first.year, first.month, first.day);
    final lastDay = DateTime(last.year, last.month, last.day);
    final format = DateFormat.yMMMMd(context.l10n.localeName);
    return GridView.count(
      crossAxisCount: 7,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      childAspectRatio: 1.1,
      children: [
        for (var i = 0; i < lead; i++) const SizedBox.shrink(),
        for (var d = 1; d <= days; d++)
          Builder(
            builder: (context) {
              final day = DateTime(month.year, month.month, d);
              final enabled = !day.isBefore(firstDay) && !day.isAfter(lastDay);
              final isSelected = selected != null && _sameDay(day, selected!);
              final isToday = _sameDay(day, today);
              return Semantics(
                button: enabled,
                selected: isSelected,
                label: format.format(day),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: enabled ? () => onChosen(day) : null,
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.brandGreen : null,
                        border: isToday && !isSelected
                            ? Border.all(color: palette.textMuted)
                            : null,
                      ),
                      child: ExcludeSemantics(
                        child: Text(
                          '$d',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.onAccent
                                : enabled
                                ? palette.textPrimary
                                : palette.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
