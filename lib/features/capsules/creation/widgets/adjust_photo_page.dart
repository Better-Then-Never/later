import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/capsule.dart';

/// Adjust (Figma "v3c Create / Adjust"): the whole photo with a square
/// window; drag the window anywhere and pinch to zoom up to 3× to pick what
/// the capsule shows wherever it is square. The whole photo still opens on a
/// tap. Returns the chosen square, or null when cancelled.
class AdjustPhotoPage extends StatefulWidget {
  const AdjustPhotoPage({super.key, required this.imagePath, this.crop});

  final String imagePath;
  final CapsuleCrop? crop;

  /// The most it zooms in: the window is then a third of the short side.
  static const maxZoom = 3.0;

  static Future<CapsuleCrop?> show(
    BuildContext context, {
    required String imagePath,
    CapsuleCrop? crop,
  }) => Navigator.of(context).push(
    PageRouteBuilder<CapsuleCrop>(
      opaque: false,
      barrierColor: AppColors.mediaScrimStrong,
      transitionDuration: AppMotion.of(context, AppMotion.standard),
      reverseTransitionDuration: AppMotion.of(context, AppMotion.fast),
      pageBuilder: (_, _, _) =>
          AdjustPhotoPage(imagePath: imagePath, crop: crop),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );

  @override
  State<AdjustPhotoPage> createState() => _AdjustPhotoPageState();
}

class _AdjustPhotoPageState extends State<AdjustPhotoPage> {
  late final FileImage _image = FileImage(File(widget.imagePath));

  /// The photo's width over its height, once it is read.
  double? _aspect;

  /// The window as shares of the photo (x, y of its corner; its side as a
  /// share of the photo's short side).
  double _x = 0;
  double _y = 0;
  double _side = 1;

  // At the start of a gesture.
  double _startSide = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_aspect != null) return;
    final stream = _image.resolve(createLocalImageConfiguration(context));
    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      stream.removeListener(listener);
      if (!mounted) return;
      setState(() => _start(info.image.width / info.image.height));
    });
    stream.addListener(listener);
  }

  /// Opens on the square chosen before, or on the middle one.
  void _start(double aspect) {
    _aspect = aspect;
    final crop = widget.crop ?? CapsuleCrop.centre(aspect);
    // Shares of width/height back to the short side.
    final short = aspect >= 1 ? crop.h : crop.w;
    _side = short.clamp(1 / AdjustPhotoPage.maxZoom, 1.0);
    _x = crop.x;
    _y = crop.y;
    _clamp();
  }

  /// The window's width and height as shares of the photo's.
  (double, double) get _wh {
    final aspect = _aspect!;
    return aspect >= 1 ? (_side / aspect, _side) : (_side, _side * aspect);
  }

  void _clamp() {
    final (w, h) = _wh;
    _x = _x.clamp(0.0, 1 - w);
    _y = _y.clamp(0.0, 1 - h);
  }

  CapsuleCrop get _crop {
    final (w, h) = _wh;
    return CapsuleCrop(x: _x, y: _y, w: w, h: h);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final media = MediaQuery.of(context);
    final aspect = _aspect;
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: [
              Text(
                l10n.capsulesAdjustTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 18,
                  height: 1.2,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onMedia,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.capsulesAdjustHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 13,
                  height: 1.25,
                  color: AppColors.onMediaMuted,
                ),
              ),
              const SizedBox(height: 12),
              // As tall as the photo needs; the buttons right under it
              // (the room left over stays at the bottom).
              Flexible(
                child: aspect == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: aspect,
                            child: _editor(),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _Button(
                      label: l10n.commonCancel,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Button(
                      label: l10n.capsulesComposerDone,
                      solid: true,
                      onTap: aspect == null
                          ? null
                          : () => Navigator.of(context).pop(_crop),
                    ),
                  ),
                ],
              ),
              SizedBox(height: media.padding.bottom > 0 ? 0 : 8),
            ],
          ),
        ),
      ),
    );
  }

  /// The photo, darkened outside the window, the window with its corners,
  /// and the zoom.
  Widget _editor() => LayoutBuilder(
    builder: (context, box) {
      final size = box.biggest;
      final (w, h) = _wh;
      final window = Rect.fromLTWH(
        _x * size.width,
        _y * size.height,
        w * size.width,
        h * size.height,
      );
      return GestureDetector(
        onScaleStart: (_) => _startSide = _side,
        onScaleUpdate: (d) {
          setState(() {
            // Pinch: the window grows or shrinks around its middle.
            if (d.pointerCount > 1) {
              final (w0, h0) = _wh;
              final centre = Offset(_x + w0 / 2, _y + h0 / 2);
              _side = (_startSide / d.scale).clamp(
                1 / AdjustPhotoPage.maxZoom,
                1.0,
              );
              final (w1, h1) = _wh;
              _x = centre.dx - w1 / 2;
              _y = centre.dy - h1 / 2;
            }
            // Drag: the window follows the finger.
            _x += d.focalPointDelta.dx / size.width;
            _y += d.focalPointDelta.dy / size.height;
            _clamp();
          });
        },
        onScaleEnd: (_) => unawaited(HapticFeedback.selectionClick()),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(image: _image, fit: BoxFit.fill),
            CustomPaint(painter: _WindowPainter(window)),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.mediaScrim,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${(1 / _side).toStringAsFixed(1)}×',
                  style: const TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onMedia,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// The dark outside of the window, its white frame and its four corners.
class _WindowPainter extends CustomPainter {
  const _WindowPainter(this.window);

  final Rect window;

  @override
  void paint(Canvas canvas, Size size) {
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(window);
    canvas.drawPath(outside, Paint()..color = AppColors.mediaScrim);
    final line = Paint()
      ..color = AppColors.onMedia
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(window, line);
    // The corners: short thick marks a thumb can find.
    final corner = Paint()
      ..color = AppColors.onMedia
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final arm = math.min(18.0, window.shortestSide / 3);
    for (final (p, dx, dy) in [
      (window.topLeft, 1.0, 1.0),
      (window.topRight, -1.0, 1.0),
      (window.bottomLeft, 1.0, -1.0),
      (window.bottomRight, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(p, p + Offset(arm * dx, 0), corner)
        ..drawLine(p, p + Offset(0, arm * dy), corner);
    }
  }

  @override
  bool shouldRepaint(_WindowPainter old) => old.window != window;
}

/// Cancel (white outline) and Done (green).
class _Button extends StatelessWidget {
  const _Button({required this.label, required this.onTap, this.solid = false});

  final String label;
  final VoidCallback? onTap;
  final bool solid;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: solid
        ? ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: AppColors.onAccent,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            onPressed: onTap,
            child: Text(label, style: _style),
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.onMedia,
              side: const BorderSide(color: AppColors.onMedia, width: 1.5),
              shape: const StadiumBorder(),
            ),
            onPressed: onTap,
            child: Text(label, style: _style),
          ),
  );

  static const _style = TextStyle(
    fontFamily: kAppFontFamily,
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.bold,
  );
}
