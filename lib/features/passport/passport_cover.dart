import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'passport_paper.dart';

/// The Passport's cover (Figma 7039:727): the closed booklet in green
/// leather, LATER and PASSPORT in foil over a globe with a pin, and whose
/// places they are. [onOpen] turns to the first page.
class PassportCover extends StatelessWidget {
  const PassportCover({super.key, required this.line, required this.onOpen});

  /// "Places where you left a capsule".
  final String line;
  final VoidCallback onOpen;

  /// The foil: the paper's colour pressed into the leather.
  static const foil = AppColors.passportPaper;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      button: true,
      label: '${l10n.passportCoverTitle}. $line',
      hint: l10n.passportTapToOpen,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onOpen,
        child: AspectRatio(
          aspectRatio: 0.71,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: AppColors.passportCover,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(6),
                right: Radius.circular(PassportPaper.radius),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.passportShadow,
                  offset: Offset(0, 8),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Stack(
              children: [
                // The leather's grain: faint diagonal lines.
                const Positioned.fill(
                  child: CustomPaint(painter: _GrainPainter()),
                ),
                // The spine's shade.
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 14,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.mediaBlack.withValues(alpha: 0.35),
                          AppColors.mediaBlack.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 16, 24),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 220,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.passportCoverBrand,
                              style: const TextStyle(
                                fontFamily: kAppFontFamily,
                                fontSize: 32,
                                height: 1.1,
                                letterSpacing: 8,
                                fontWeight: FontWeight.bold,
                                color: foil,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const SizedBox(
                              width: 96,
                              height: 96,
                              child: CustomPaint(painter: GlobePainter(foil)),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              l10n.passportCoverTitle,
                              style: const TextStyle(
                                fontFamily: kAppFontFamily,
                                fontSize: 15,
                                height: 1.1,
                                letterSpacing: 4.5,
                                fontWeight: FontWeight.bold,
                                color: foil,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              line,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: kAppFontFamily,
                                fontSize: 12,
                                height: 1.3,
                                color: foil.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The cover's globe (Figma "Passport / Cover"): a sphere of meridians and
/// parallels in foil lines, a pin on its shoulder.
class GlobePainter extends CustomPainter {
  const GlobePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    final r = s * 0.40;
    final c = Offset(size.width / 2 - s * 0.04, size.height / 2 + s * 0.06);
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.022;
    canvas.drawCircle(c, r, line);
    // Meridians: ellipses narrowing to the middle line.
    for (final f in [0.38, 0.75]) {
      canvas.drawOval(
        Rect.fromCenter(center: c, width: 2 * r * f, height: 2 * r),
        line,
      );
    }
    canvas.drawLine(c.translate(0, -r), c.translate(0, r), line);
    // Parallels: chords of the circle.
    for (final y in [-0.5, 0.0, 0.5]) {
      final dy = r * y;
      final half = math.sqrt(r * r - dy * dy);
      canvas.drawLine(c.translate(-half, dy), c.translate(half, dy), line);
    }
    // The pin on the globe's shoulder, its point on the sphere.
    final tip = c + Offset(math.cos(-0.9), math.sin(-0.9)) * r;
    final pr = s * 0.11;
    final head = tip.translate(0, -pr * 2.1);
    final pin = Path()
      ..moveTo(tip.dx, tip.dy)
      ..quadraticBezierTo(
        head.dx - pr * 1.2,
        head.dy + pr * 0.9,
        head.dx - pr,
        head.dy,
      )
      ..arcTo(
        Rect.fromCircle(center: head, radius: pr),
        math.pi,
        math.pi,
        false,
      )
      ..quadraticBezierTo(
        head.dx + pr * 1.2,
        head.dy + pr * 0.9,
        tip.dx,
        tip.dy,
      )
      ..close()
      ..addOval(Rect.fromCircle(center: head, radius: pr * 0.4))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(pin, Paint()..color = color);
  }

  @override
  bool shouldRepaint(GlobePainter old) => old.color != color;
}

/// The leather's grain: thin diagonal lines, barely there.
class _GrainPainter extends CustomPainter {
  const _GrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.mediaBlack.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 9) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => false;
}
