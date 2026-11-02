import 'package:flutter/material.dart';

import '../../core/l10n/app_dates.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/pill_v2.dart';
import '../stamps/ink_stamp.dart';
import 'passport_data.dart';
import 'passport_paper.dart';

/// A town's stamp as the Passport presses it: its outline and ink from its
/// place in the book ([index]), the town, the first day when known (else
/// its capsules), the country.
class PassportTownStamp extends StatelessWidget {
  const PassportTownStamp({
    super.key,
    required this.town,
    required this.index,
    required this.countryName,
  });

  final PassportTown town;
  final int index;
  final String countryName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final first = town.first;
    return InkStamp(
      ink: PassportStyles.inkAt(index),
      shape: PassportStyles.shapeAt(index),
      top: town.town.toUpperCase(),
      middle: first != null
          ? AppDates.medium(first, l10n.localeName).toUpperCase()
          : l10n.worldCapsules(town.capsules).toUpperCase(),
      bottom: countryName.toUpperCase(),
    );
  }
}

/// A page of town stamps (Figma 7039:889): up to seven, two by two, each
/// leaning a little; a tap opens the stamp's sheet.
class PassportStampsPage extends StatelessWidget {
  const PassportStampsPage({
    super.key,
    required this.towns,
    required this.first,
    required this.number,
    required this.countryName,
    required this.onTap,
  });

  final List<PassportTown> towns;

  /// The index of [towns]' first stamp in the whole book (its ink, shape).
  final int first;
  final int number;
  final String Function(String code) countryName;
  final void Function(PassportTown town, int index) onTap;

  static const _rows = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PassportPaper(
      label: l10n.stampsPageLabel,
      number: number,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / 2;
          final h = box.maxHeight / _rows;
          return Stack(
            children: [
              for (var i = 0; i < towns.length; i++)
                Positioned(
                  // Two columns, every other row nudged right: pressed by
                  // hand, not in a grid.
                  left: (i % 2) * w + ((i ~/ 2).isOdd ? 6 : -4),
                  top: (i ~/ 2) * h,
                  width: w,
                  height: h,
                  child: _Slot(
                    town: towns[i],
                    index: first + i,
                    countryName: countryName(towns[i].countryCode),
                    onTap: () => onTap(towns[i], first + i),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.town,
    required this.index,
    required this.countryName,
    required this.onTap,
  });

  final PassportTown town;
  final int index;
  final String countryName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      button: true,
      label: [
        town.town,
        countryName,
        l10n.worldCapsules(town.capsules),
      ].join('. '),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Transform.rotate(
            angle: PassportStyles.tiltAt(index),
            child: FittedBox(
              child: Opacity(
                opacity: 0.9,
                child: PassportTownStamp(
                  town: town,
                  index: index,
                  countryName: countryName,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An empty Passport's stamps page (Figma 7039:1226): a dashed circle with
/// the pin where the first stamp will go, what earns it, and (in your own
/// Passport) Make a capsule.
class PassportEmptyPage extends StatelessWidget {
  const PassportEmptyPage({
    super.key,
    required this.text,
    required this.number,
    this.onMake,
  });

  final String text;
  final int number;
  final VoidCallback? onMake;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onMake = this.onMake;
    return PassportPaper(
      label: l10n.stampsPageLabel,
      number: number,
      child: PassportFit(
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 104,
              height: 104,
              child: CustomPaint(painter: _DashedRingPainter()),
            ),
            const SizedBox(height: 16),
            if (onMake != null)
              Text(
                l10n.passportEmptyTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  height: 1.2,
                  color: AppColors.passportInk,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: PassportStyles.quote.copyWith(
                fontStyle: FontStyle.normal,
                color: AppColors.passportInk,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.worldNote,
              textAlign: TextAlign.center,
              style: PassportStyles.field.copyWith(letterSpacing: 0),
            ),
            if (onMake != null) ...[
              const SizedBox(height: 16),
              PillV2(label: l10n.passportMakeCapsule, onTap: onMake),
            ],
          ],
        ),
      ),
    );
  }
}

/// The place of the first stamp: a dashed ring with the pin inside.
class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1;
    final paint = Paint()
      ..color = AppColors.passportInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dashes = 36;
    const step = 2 * 3.141592653589793 / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        i * step,
        step * 0.55,
        false,
        paint,
      );
    }
    // The pin, 24 × 32 in the middle.
    canvas
      ..save()
      ..translate(c.dx - 12, c.dy - 18);
    final pin = Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(12, 0)
      ..cubicTo(5.4, 0, 0, 5.4, 0, 12)
      ..cubicTo(0, 21, 12, 32, 12, 32)
      ..cubicTo(12, 32, 24, 21, 24, 12)
      ..cubicTo(24, 5.4, 18.6, 0, 12, 0)
      ..close()
      ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 4.8));
    canvas
      ..drawPath(pin, Paint()..color = AppColors.passportInk)
      ..restore();
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => false;
}
