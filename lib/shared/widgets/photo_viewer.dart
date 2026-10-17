import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/assets/app_assets.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../data/services/app_image_cache.dart';
import 'buttons/default_icon_button.dart';
import 'loop_picture.dart';

/// A capsule's photo on its own, full screen: pinch or double-tap to zoom,
/// drag down (when not zoomed) or Back to close. [url] is a network photo or
/// a `file:` one (a capsule still on the phone).
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({
    super.key,
    required this.url,
    this.frames = const [],
    this.frameDelay = const Duration(milliseconds: 300),
  });

  final String url;

  /// A loop capsule's frames: played instead of [url].
  final List<String> frames;
  final Duration frameDelay;

  static Future<void> show(
    BuildContext context,
    String url, {
    List<String> frames = const [],
    Duration frameDelay = const Duration(milliseconds: 300),
  }) {
    final duration = AppMotion.of(context, AppMotion.standard);
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        pageBuilder: (_, _, _) =>
            PhotoViewer(url: url, frames: frames, frameDelay: frameDelay),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.emphasizedCurve,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: 0.94, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer>
    with SingleTickerProviderStateMixin {
  /// Dragged this far down (or up), the photo closes.
  static const _dismissDistance = 120.0;

  final _transform = TransformationController();
  late final AnimationController _anim = AnimationController(vsync: this);
  Animation<Matrix4>? _zoomAnimation;
  Animation<double>? _dragAnimation;
  Offset? _doubleTapAt;
  double _drag = 0;

  bool get _zoomed => _transform.value.getMaxScaleOnAxis() > 1.01;

  @override
  void initState() {
    super.initState();
    _anim.addListener(() {
      if (_zoomAnimation case final zoom?) _transform.value = zoom.value;
      if (_dragAnimation case final drag?) setState(() => _drag = drag.value);
    });
    // Zoomed or not decides whether a drag closes the photo.
    _anim.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _anim.duration = AppMotion.of(context, AppMotion.standard);
  }

  @override
  void dispose() {
    _anim.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _animateZoom(Matrix4 to) {
    _dragAnimation = null;
    _zoomAnimation = Matrix4Tween(
      begin: _transform.value,
      end: to,
    ).animate(CurvedAnimation(parent: _anim, curve: AppMotion.emphasizedCurve));
    _anim.forward(from: 0);
  }

  /// Double tap: 2.5x around the finger, or back to the whole photo.
  void _onDoubleTap() {
    if (_zoomed) {
      _animateZoom(Matrix4.identity());
    } else {
      final at = _doubleTapAt ?? Offset.zero;
      const scale = 2.5;
      _animateZoom(
        Matrix4.identity()
          ..translateByDouble(-at.dx * (scale - 1), -at.dy * (scale - 1), 0, 1)
          ..scaleByDouble(scale, scale, 1, 1),
      );
    }
    setState(() {});
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _anim.stop();
    setState(() => _drag += details.delta.dy);
  }

  void _onDragEnd(DragEndDetails details) {
    final fling = details.primaryVelocity?.abs() ?? 0;
    if (_drag.abs() > _dismissDistance || fling > 900) {
      Navigator.of(context).pop();
      return;
    }
    _zoomAnimation = null;
    _dragAnimation = Tween(
      begin: _drag,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _anim, curve: AppMotion.exit));
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final url = widget.url;
    // Decoded for a 2x zoom without blur.
    final width = AppImageCache.decodeWidth(
      size.width * 2,
      MediaQuery.devicePixelRatioOf(context),
    );
    final ImageProvider image = url.startsWith('file:')
        ? FileImage(File.fromUri(Uri.parse(url)))
        : AppImageCache.provider(url, width: width);
    // The black fades as the photo is dragged away.
    final fade = (1 - _drag.abs() / (_dismissDistance * 3)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      // Expand: every layer covers the screen (a loose stack would shrink to
      // the Back button).
      body: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: AppColors.mediaBlack.withValues(alpha: fade)),
          GestureDetector(
            onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
            onDoubleTap: _onDoubleTap,
            onVerticalDragUpdate: _zoomed ? null : _onDragUpdate,
            onVerticalDragEnd: _zoomed ? null : _onDragEnd,
            child: Transform.translate(
              offset: Offset(0, _drag),
              child: InteractiveViewer(
                transformationController: _transform,
                minScale: 1,
                maxScale: 4,
                onInteractionEnd: (_) => setState(() {}),
                child: widget.frames.length > 1
                    ? LoopPicture(
                        sources: widget.frames,
                        frameDelay: widget.frameDelay,
                        fit: BoxFit.contain,
                        decodeWidth: size.width * 2,
                      )
                    : Image(
                        image: image,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Opacity(
                  opacity: fade,
                  child: DefaultIconButton(
                    onTap: () => Navigator.of(context).pop(),
                    assetPath: AppIcons.cameraBack,
                    size: 44,
                    semanticLabel: context.l10n.commonBack,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
