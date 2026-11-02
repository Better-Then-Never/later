import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/profile_stamp.dart';

/// Someone's photo as a postage stamp (Profile v4, Figma page 13 Round 5):
/// one of six shapes with real cut-out perforations, on paper of the colour
/// they chose. Used wherever a person appears: their postcard, notifications,
/// friend lists, share sheets.
///
/// [photo] fills the window; without one the window shows [initial] on soft
/// green (a new user), with a camera badge when [onAddPhoto] is set.
class ProfileStamp extends StatelessWidget {
  const ProfileStamp({
    super.key,
    required this.style,
    required this.size,
    this.photo,
    this.initial = '',
    this.caption,
    this.tilt = 0,
    this.elevation = 3,
  });

  final ProfileStampStyle style;

  /// The stamp's width; every shape but Polaroid is square.
  final double size;
  final ImageProvider? photo;
  final String initial;

  /// The name under a Polaroid's photo.
  final String? caption;

  /// Degrees, positive is clockwise (the design tilts stamps 3-5 degrees).
  final double tilt;
  final double elevation;

  static Color paperColor(StampColor color) {
    final argb = color.argb;
    if (argb != null) return Color(argb);
    return switch (color.value) {
      'paper' => AppColors.passportPaper,
      'green' => AppColors.brandGreen,
      'yellow' => AppColors.placeYellow,
      'orange' => AppColors.capsuleOrange,
      'red' => AppColors.capsuleRed,
      'blue' => AppColors.capsuleBlue,
      'forest' => AppColors.passportCover,
      'black' => AppColors.mediaBlack,
      _ => AppColors.onAccent,
    };
  }

  /// The stamp's height for [shape] at [size].
  static double heightFor(StampShape shape, double size) =>
      shape == StampShape.polaroid ? size * 1.18 : size;

  @override
  Widget build(BuildContext context) {
    final height = heightFor(style.shape, size);
    final paper = paperColor(style.color);
    final window = StampGeometry.window(style.shape, Size(size, height));
    final stamp = SizedBox(
      width: size,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PaperPainter(
                shape: style.shape,
                color: paper,
                elevation: elevation,
              ),
            ),
          ),
          Positioned.fromRect(
            rect: window.rect,
            child: ClipPath(
              clipper: _WindowClipper(window),
              child: photo != null
                  ? Image(
                      image: photo!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  : ColoredBox(
                      color: Color.alphaBlend(
                        AppColors.brandGreen.withValues(alpha: 0.22),
                        AppColors.onAccent,
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: window.rect.width * 0.42,
                            color: AppColors.brandGreen,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          if (style.shape == StampShape.polaroid && caption != null)
            Positioned(
              left: size * 0.09,
              right: size * 0.09,
              top: size * 0.94,
              child: Text(
                caption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  fontSize: math.max(9, size * 0.12),
                  fontStyle: FontStyle.italic,
                  color: _captionColor(paper),
                ),
              ),
            ),
        ],
      ),
    );
    if (tilt == 0) return stamp;
    return Transform.rotate(angle: tilt * math.pi / 180, child: stamp);
  }

  static Color _captionColor(Color paper) => paper.computeLuminance() > 0.4
      ? AppColors.passportInk
      : AppColors.onMedia;
}

/// The photo's window inside a stamp: a rectangle, rounded or round.
class StampWindow {
  const StampWindow(this.rect, {this.radius = 0, this.oval = false});

  final Rect rect;
  final double radius;
  final bool oval;

  Path path() => oval
      ? (Path()..addOval(rect))
      : (Path()
          ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius))));
}

/// The shapes of the six stamps, in the proportions of the Figma board.
abstract final class StampGeometry {
  static StampWindow window(StampShape shape, Size s) {
    final w = s.width;
    return switch (shape) {
      StampShape.classic => StampWindow(
        Rect.fromLTWH(w * .11, w * .11, w * .78, w * .78),
        radius: 2,
      ),
      StampShape.rounded => StampWindow(
        Rect.fromLTWH(w * .11, w * .11, w * .78, w * .78),
        radius: w * .096,
      ),
      StampShape.round => StampWindow(
        Rect.fromLTWH(w * .11, w * .11, w * .78, w * .78),
        oval: true,
      ),
      StampShape.soft => StampWindow(
        Rect.fromLTWH(w * .07, w * .07, w * .86, w * .86),
        radius: w * .18,
      ),
      StampShape.ticket => StampWindow(
        Rect.fromLTWH(w * .15, w * .09, w * .7, w * .82),
        radius: w * .05,
      ),
      StampShape.polaroid => StampWindow(
        Rect.fromLTWH(w * .07, w * .07, w * .86, w * .86),
      ),
    };
  }

  /// The paper, with its perforations cut out.
  static Path paper(StampShape shape, Size s) {
    final w = s.width, h = s.height;
    switch (shape) {
      case StampShape.classic:
        return _perforated(
          Path()..addRect(Offset.zero & s),
          s,
          d: w * .075,
          step: w * .095,
          inset: 0,
        );
      case StampShape.rounded:
        final r = w * .16;
        return _perforated(
          Path()..addRRect(
            RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(r)),
          ),
          s,
          d: w * .07,
          step: w * .1,
          inset: r * 1.1,
        );
      case StampShape.round:
        final holes = Path();
        const n = 31;
        final d = w * .075;
        for (var i = 0; i < n; i++) {
          final a = i * 2 * math.pi / n;
          holes.addOval(
            Rect.fromCircle(
              center: Offset(
                w / 2 + math.cos(a) * w / 2,
                w / 2 + math.sin(a) * w / 2,
              ),
              radius: d / 2,
            ),
          );
        }
        return Path.combine(
          PathOperation.difference,
          Path()..addOval(Offset.zero & s),
          holes,
        );
      case StampShape.soft:
        return Path()..addRRect(
          RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(w * .24)),
        );
      case StampShape.ticket:
        final notches = Path()
          ..addOval(Rect.fromCircle(center: Offset(0, h / 2), radius: w * .1))
          ..addOval(Rect.fromCircle(center: Offset(w, h / 2), radius: w * .1));
        return Path.combine(
          PathOperation.difference,
          Path()..addRRect(
            RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(w * .08)),
          ),
          notches,
        );
      case StampShape.polaroid:
        return Path()..addRRect(
          RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(w * .03)),
        );
    }
  }

  /// Round holes centred on the edges, [step] apart, leaving [inset] free at
  /// the corners (for rounded corners).
  static Path _perforated(
    Path base,
    Size s, {
    required double d,
    required double step,
    required double inset,
  }) {
    final w = s.width, h = s.height;
    final holes = Path();
    void hole(double x, double y) =>
        holes.addOval(Rect.fromCircle(center: Offset(x, y), radius: d / 2));
    final nx = math.max(1, ((w - 2 * inset) / step).round());
    final ny = math.max(1, ((h - 2 * inset) / step).round());
    for (var i = 0; i <= nx; i++) {
      final x = inset + i * (w - 2 * inset) / nx;
      hole(x, 0);
      hole(x, h);
    }
    for (var j = 1; j < ny; j++) {
      final y = inset + j * (h - 2 * inset) / ny;
      hole(0, y);
      hole(w, y);
    }
    return Path.combine(PathOperation.difference, base, holes);
  }
}

class _PaperPainter extends CustomPainter {
  _PaperPainter({
    required this.shape,
    required this.color,
    required this.elevation,
  });

  final StampShape shape;
  final Color color;
  final double elevation;

  @override
  void paint(Canvas canvas, Size size) {
    final path = StampGeometry.paper(shape, size);
    if (elevation > 0) {
      canvas.drawShadow(path, AppColors.mediaBlack, elevation, false);
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PaperPainter old) =>
      old.shape != shape || old.color != color || old.elevation != elevation;
}

class _WindowClipper extends CustomClipper<Path> {
  _WindowClipper(this.window);

  final StampWindow window;

  @override
  Path getClip(Size size) => window.oval
      ? (Path()..addOval(Offset.zero & size))
      : (Path()..addRRect(
          RRect.fromRectAndRadius(
            Offset.zero & size,
            Radius.circular(window.radius),
          ),
        ));

  @override
  bool shouldReclip(_WindowClipper old) =>
      old.window.radius != window.radius || old.window.oval != window.oval;
}
