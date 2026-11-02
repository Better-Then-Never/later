import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../stamps/guilloche.dart';
import '../stamps/ink_stamp.dart';

/// One page of the Passport booklet (Figma page 8): passport paper with
/// 16 dp corners, the faint security print, the spine's shade on the left,
/// the page's [label] printed on top and its [number] at the bottom right.
/// The same in light and dark, like a printed booklet.
class PassportPaper extends StatelessWidget {
  const PassportPaper({
    super.key,
    required this.child,
    this.label,
    this.number,
  });

  final Widget child;
  final String? label;
  final int? number;

  static const radius = 16.0;

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    final number = this.number;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.passportPaper,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: AppColors.passportShadow,
            offset: Offset(0, 6),
            blurRadius: 18,
          ),
        ],
      ),
      child: Stack(
        children: [
          // The security print, faint, in the middle of the page.
          const Positioned.fill(
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 1.05,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Opacity(
                    opacity: 0.12,
                    child: CustomPaint(painter: GuillochePainter()),
                  ),
                ),
              ),
            ),
          ),
          // The spine's shade.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.mediaBlack.withValues(alpha: 0.22),
                    AppColors.mediaBlack.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          if (label != null)
            Positioned(
              left: 24,
              right: 12,
              top: 14,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: PassportStyles.label,
              ),
            ),
          if (number != null)
            Positioned(
              right: 16,
              bottom: 12,
              child: Text('$number', style: PassportStyles.pageNumber),
            ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 36, 18, 30),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// The page's content at its natural height, shrunk to fit a short page
/// (a small phone, a large text size) instead of overflowing.
class PassportFit extends StatelessWidget {
  const PassportFit({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: SizedBox(width: box.maxWidth, child: child),
    ),
  );
}

/// The printed type of the Passport: small caps labels and values in ink.
abstract final class PassportStyles {
  /// The page's title on top ("STAMPS · PIECZĘCIE").
  static const label = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 9,
    height: 1.1,
    letterSpacing: 0.72,
    color: AppColors.passportInk,
  );

  static const pageNumber = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 13,
    height: 1.25,
    color: AppColors.passportInk,
  );

  /// A field's name ("SURNAME").
  static const field = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 8.5,
    height: 1.2,
    letterSpacing: 0.6,
    color: AppColors.passportInk,
  );

  /// A field's value ("WALKER").
  static const value = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.bold,
    color: AppColors.passportText,
  );

  /// A big number ("102").
  static const number = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 24,
    height: 1.1,
    fontWeight: FontWeight.bold,
    color: AppColors.passportText,
  );

  /// The machine-readable lines.
  static const mrz = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 11,
    height: 1.4,
    letterSpacing: 1.6,
    fontWeight: FontWeight.bold,
    color: AppColors.passportInk,
  );

  static const quote = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 13.5,
    height: 1.35,
    fontStyle: FontStyle.italic,
    color: AppColors.passportText,
  );

  /// The inks of the stamps and the visas' bands, in turn (yellow is too
  /// light on paper).
  static const inks = [
    AppColors.capsuleGreen,
    AppColors.capsuleBlue,
    AppColors.capsuleOrange,
    AppColors.capsuleRed,
    AppColors.passportInk,
    AppColors.capsulePurple,
    AppColors.passportCover,
  ];

  static Color inkAt(int i) => inks[i % inks.length];

  /// The stamps' outlines, in turn.
  static const shapes = [
    InkStampShape.round,
    InkStampShape.rect,
    InkStampShape.oval,
    InkStampShape.round,
    InkStampShape.oval,
    InkStampShape.rect,
    InkStampShape.oval,
  ];

  static InkStampShape shapeAt(int i) => shapes[i % shapes.length];

  /// Each stamp leans a little, as if pressed by hand (fixed, never
  /// animated).
  static const _tilts = [-0.10, 0.07, -0.05, 0.09, -0.08, 0.04, 0.06, -0.03];

  static double tiltAt(int i) => _tilts[i % _tilts.length];
}

/// A field on a passport page: its small caps name over its value.
class PassportField extends StatelessWidget {
  const PassportField({super.key, required this.name, required this.value});

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: PassportStyles.field),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: PassportStyles.value,
        ),
      ],
    ),
  );
}

/// A number with its small caps name under it ("102 / CAPSULES").
class PassportNumber extends StatelessWidget {
  const PassportNumber({super.key, required this.value, required this.name});

  final int value;
  final String name;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text('$value', style: PassportStyles.number),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(name, maxLines: 1, style: PassportStyles.field),
        ),
      ],
    ),
  );
}

/// A hairline across the page in faint ink.
class PassportRule extends StatelessWidget {
  const PassportRule({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(vertical: 10),
    color: AppColors.passportInk.withValues(alpha: 0.3),
  );
}
