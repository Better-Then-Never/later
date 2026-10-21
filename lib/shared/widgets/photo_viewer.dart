import 'dart:async';
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
    this.heroTag,
    this.aspect,
    this.fromRadius = 20,
  });

  final String url;

  /// The photo's width over its height, when known before it opens: the
  /// flying photo then turns from the tapped square into the whole photo.
  final double? aspect;

  /// The corners of the tapped picture the photo flies from.
  final double fromRadius;

  /// The tapped picture's [Hero] tag: the photo flies from it to full screen
  /// and back.
  final Object? heroTag;

  /// A loop capsule's frames: played instead of [url].
  final List<String> frames;
  final Duration frameDelay;

  /// Opens [url] full screen. With [heroTag] the photo flies from the
  /// tapped picture; the black behind it fades in as a painted colour (a
  /// page-wide fade would draw the whole screen offscreen every frame).
  ///
  /// With a hero, the full photo is decoded first (a moment, at most 400 ms):
  /// flying in empty showed the page behind it as a white flash.
  static Future<void> show(
    BuildContext context,
    String url, {
    List<String> frames = const [],
    Duration frameDelay = const Duration(milliseconds: 300),
    Object? heroTag,
    double fromRadius = 20,
  }) async {
    final reduced = AppMotion.reduced(context);
    double? aspect;
    if (heroTag != null && frames.length <= 1) {
      aspect = await _aspectOf(
        _providerFor(
          url,
          MediaQuery.sizeOf(context),
          MediaQuery.devicePixelRatioOf(context),
        ),
        createLocalImageConfiguration(context),
      );
      if (!context.mounted) return;
    }
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: reduced ? Duration.zero : AppMotion.emphasized,
        reverseTransitionDuration: reduced ? Duration.zero : AppMotion.standard,
        pageBuilder: (_, _, _) => PhotoViewer(
          url: url,
          frames: frames,
          frameDelay: frameDelay,
          heroTag: heroTag,
          aspect: aspect,
          fromRadius: fromRadius,
        ),
        // The page itself moves in only without a hero: the photo grows a
        // little as it fades (one picture-sized layer, briefly).
        transitionsBuilder: (_, animation, _, child) {
          if (heroTag != null || reduced) return child;
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.emphasizedCurve,
          );
          return ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          );
        },
      ),
    );
  }

  /// The full photo as the viewer shows it: decoded for a 2x zoom.
  static ImageProvider _providerFor(String url, Size size, double ratio) =>
      url.startsWith('file:')
      ? FileImage(File.fromUri(Uri.parse(url)))
      : AppImageCache.provider(
          url,
          width: AppImageCache.decodeWidth(size.width * 2, ratio),
        );

  /// Decodes [provider] (kept in the image cache for the viewer) and gives
  /// its width over height; null if it takes longer than 400 ms or fails.
  static Future<double?> _aspectOf(
    ImageProvider provider,
    ImageConfiguration configuration,
  ) {
    final done = Completer<double?>();
    final stream = provider.resolve(configuration);
    late final ImageStreamListener listener;
    void finish(double? value) {
      if (!done.isCompleted) done.complete(value);
      stream.removeListener(listener);
    }

    listener = ImageStreamListener(
      (info, _) => finish(info.image.width / info.image.height),
      onError: (_, _) => finish(null),
    );
    stream.addListener(listener);
    return done.future.timeout(
      const Duration(milliseconds: 400),
      onTimeout: () {
        stream.removeListener(listener);
        return null;
      },
    );
  }

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

/// The flying photo: at the start the tapped square (cropped, rounded), at
/// the end the whole photo fitted to the screen, and every step between, so
/// nothing jumps or blinks.
class _PhotoFlight extends StatelessWidget {
  const _PhotoFlight({
    required this.animation,
    required this.image,
    required this.aspect,
    required this.radius,
  });

  final Animation<double> animation;
  final ImageProvider image;
  final double aspect;
  final double radius;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value.clamp(0.0, 1.0);
        final size = box.biggest;
        // The whole photo fitted into the flight's rectangle.
        var width = size.width;
        var height = width / aspect;
        if (height > size.height) {
          height = size.height;
          width = height * aspect;
        }
        final whole = Rect.fromCenter(
          center: size.center(Offset.zero),
          width: width,
          height: height,
        );
        final window = Rect.lerp(Offset.zero & size, whole, t)!;
        return Stack(
          children: [
            Positioned.fromRect(
              rect: window,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius * (1 - t)),
                child: Image(
                  image: image,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
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
    final ImageProvider image = PhotoViewer._providerFor(
      url,
      size,
      MediaQuery.devicePixelRatioOf(context),
    );
    // The black fades as the photo is dragged away, and with the route.
    final route = ModalRoute.of(context)?.animation;
    final fade = (1 - _drag.abs() / (_dismissDistance * 3)).clamp(0.0, 1.0);
    Widget photo = widget.frames.length > 1
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
          );
    if (widget.heroTag case final tag?) {
      final aspect = widget.aspect;
      photo = Hero(
        tag: tag,
        // Straight from the square to the screen (the default arc bends it).
        createRectTween: (begin, end) => RectTween(begin: begin, end: end),
        flightShuttleBuilder: aspect == null
            ? null
            : (_, animation, _, _, _) => _PhotoFlight(
                animation: animation,
                image: image,
                aspect: aspect,
                radius: widget.fromRadius,
              ),
        child: photo,
      );
    } else if (route != null) {
      photo = FadeTransition(opacity: route, child: photo);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      // Expand: every layer covers the screen (a loose stack would shrink to
      // the Back button).
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (route == null)
            ColoredBox(color: AppColors.mediaBlack.withValues(alpha: fade))
          else
            AnimatedBuilder(
              animation: route,
              builder: (_, _) => ColoredBox(
                color: AppColors.mediaBlack.withValues(
                  alpha: fade * route.value.clamp(0, 1),
                ),
              ),
            ),
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
                child: photo,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FadeTransition(
                  // A small layer: just the button.
                  opacity: route == null
                      ? AlwaysStoppedAnimation(fade)
                      : route.drive(Tween(begin: 0, end: fade)),
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
