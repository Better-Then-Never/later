import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/perf_marks.dart';
import '../../../data/models/capsule.dart';
import '../../settings/device_settings_store.dart';
import 'package:later/core/theme/app_colors.dart';
import 'package:later/core/theme/app_motion.dart';
import 'package:later/core/theme/app_text_styles.dart';

/// Why the camera cannot be shown. The message is chosen when the error view
/// is built, so it follows the app's language.
enum _CameraError { unavailable, accessDenied, startFailed }

/// Full-screen camera used to take the photo of a new capsule.
///
/// Fixes BUG-050 (flash button did nothing), BUG-051 (camera not released
/// and re-initialised across app pause/resume), BUG-052 (black screen forever
/// without a camera or when init fails) and BUG-053 (double captures).
class CameraPage extends StatefulWidget {
  const CameraPage({super.key, this.initialPrivacy, this.recipientId});

  final CapsulePrivacy? initialPrivacy;

  /// The friend the capsule will be sent to, if any.
  final String? recipientId;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  CameraLensDirection _lens = CameraLensDirection.back;

  /// Off, then automatic (fires when it is dark), then always.
  FlashMode _flash = FlashMode.off;

  // Pinch to zoom and tap to focus (F-20/F-21).
  double _minZoom = 1;
  double _maxZoom = 1;
  double _zoom = 1;
  double _zoomAtStart = 1;
  bool _showZoom = false;
  Timer? _zoomHint;
  Offset? _focusAt;
  int _focusTick = 0;

  /// The white blink when the shutter fires (F-22: instant feedback).
  bool _shutterBlink = false;
  bool _capturing = false;

  /// The preview as it was at the tap, held still while CameraX takes the
  /// picture (about a second on the reference phone): the moment is
  /// visibly caught at once, and moving the phone afterwards changes
  /// nothing on screen (docs/feel/PERFORMANCE.md, camera).
  final _previewKey = GlobalKey();
  ui.Image? _frozen;

  /// Holding the shutter records a loop: frames one after another until
  /// it is released or [_maxFrames] are taken.
  static const _maxFrames = 10;
  bool _looping = false;
  final List<String> _frames = [];
  _CameraError? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The camera chosen in Settings > Map and camera.
    if (context.read<DeviceSettingsStore>().startCamera == StartCamera.front) {
      _lens = CameraLensDirection.front;
    }
    unawaited(_setup());
  }

  @override
  void dispose() {
    _zoomHint?.cancel();
    _frozen?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller?.dispose());
    super.dispose();
  }

  /// The system permission dialog is open: it makes the app inactive, which
  /// must not tear the camera down (the first open used to fail).
  bool _askingPermission = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_askingPermission) return;
    final controller = _controller;
    if (state == AppLifecycleState.inactive) {
      // Release the camera for other apps while we are in the background.
      _controller = null;
      if (mounted) setState(() {});
      unawaited(controller?.dispose());
    } else if (state == AppLifecycleState.resumed && controller == null) {
      unawaited(_start());
    }
  }

  Future<void> _setup() async {
    try {
      _cameras = await availableCameras();
    } on CameraException catch (e) {
      AppLogger.warning('Could not list cameras', error: e);
    }
    if (_cameras.isEmpty) {
      if (mounted) setState(() => _error = _CameraError.unavailable);
      return;
    }
    // Asked here, before the camera starts (the onboarding may have been
    // skipped): the camera plugin's own request raced the page lifecycle.
    _askingPermission = true;
    final PermissionStatus status;
    try {
      status = await Permission.camera.request();
    } finally {
      _askingPermission = false;
    }
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() => _error = _CameraError.accessDenied);
      return;
    }
    await _start();
  }

  CameraDescription _cameraFor(CameraLensDirection lens) => _cameras.firstWhere(
    (c) => c.lensDirection == lens,
    orElse: () => _cameras.first,
  );

  Future<void> _start() async {
    if (_cameras.isEmpty) return;
    final controller = CameraController(
      _cameraFor(_lens),
      ResolutionPreset.high,
      enableAudio: false,
    );
    final old = _controller;
    _controller = controller;
    await old?.dispose();
    try {
      await controller.initialize();
      await controller.setFlashMode(_flash);
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      if (mounted) {
        setState(() {
          _error = null;
          _minZoom = minZoom;
          // Beyond 8x the preview is mostly noise.
          _maxZoom = maxZoom.clamp(minZoom, 8.0);
          _zoom = minZoom;
        });
      }
    } on CameraException catch (e) {
      AppLogger.warning('Camera init failed', error: e);
      if (!mounted) return;
      setState(
        () => _error = e.code == 'CameraAccessDenied'
            ? _CameraError.accessDenied
            : _CameraError.startFailed,
      );
    }
  }

  Future<void> _switchCamera() async {
    final hasFront = _cameras.any(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
    final hasBack = _cameras.any(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    if (!hasFront || !hasBack || _capturing) return;
    _lens = _lens == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    await _start();
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final next = switch (_flash) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      _ => FlashMode.off,
    };
    try {
      await controller.setFlashMode(next);
      unawaited(HapticFeedback.selectionClick());
      if (mounted) setState(() => _flash = next);
    } on CameraException catch (e) {
      // e.g. front cameras without a flash.
      AppLogger.debug('Flash not available: ${e.code}');
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_capturing || controller == null || !controller.value.isInitialized) {
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    final frozen = _freeze();
    setState(() {
      _capturing = true;
      _shutterBlink = true;
      _frozen = frozen;
    });
    PerfMarks.nextFrame('camera.feedback');
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _shutterBlink = false);
    });
    try {
      final picture = await controller.takePicture();
      PerfMarks.now('camera.file');
      if (!mounted) return;
      PerfMarks.nextFrame('creation.firstFrame');
      await AppRoutes.toCapsuleCreation(
        context,
        imagePath: picture.path,
        privacy: widget.initialPrivacy,
        recipientId: widget.recipientId,
        replace: true,
      );
    } on CameraException catch (e) {
      AppLogger.warning('Taking the picture failed', error: e);
      if (mounted) {
        setState(() {
          _capturing = false;
          _frozen?.dispose();
          _frozen = null;
        });
      }
    }
  }

  /// A still of the preview as it is now, or null when it cannot be taken.
  ui.Image? _freeze() {
    if (AppMotion.reduced(context)) return null;
    final boundary = _previewKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary || !boundary.hasSize) return null;
    try {
      final still = boundary.toImageSync(
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
      AppLogger.debug('Camera freeze: ${still.width}x${still.height}');
      return still;
    } catch (e) {
      AppLogger.debug('Camera freeze unavailable: $e');
      return null;
    }
  }

  /// Records frames while the shutter is held (loop capsules).
  Future<void> _startLoop() async {
    final controller = _controller;
    if (_capturing || controller == null || !controller.value.isInitialized) {
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    setState(() {
      _capturing = true;
      _looping = true;
      _frames.clear();
    });
    try {
      while (_looping && _frames.length < _maxFrames) {
        final picture = await controller.takePicture();
        if (!mounted) return;
        setState(() => _frames.add(picture.path));
        unawaited(HapticFeedback.selectionClick());
      }
    } on CameraException catch (e) {
      AppLogger.warning('Recording the loop failed', error: e);
    }
    if (!mounted) return;
    _looping = false;
    final frames = List.of(_frames);
    if (frames.isEmpty) {
      setState(() => _capturing = false);
      return;
    }
    // One frame is simply a photo.
    await AppRoutes.toCapsuleCreation(
      context,
      imagePath: frames.first,
      framePaths: frames.length > 1 ? frames : const [],
      privacy: widget.initialPrivacy,
      recipientId: widget.recipientId,
      replace: true,
    );
  }

  /// Releasing the shutter: the frame being taken is the last one.
  void _stopLoop() {
    if (_looping) setState(() => _looping = false);
  }

  void _onScaleStart(ScaleStartDetails _) => _zoomAtStart = _zoom;

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    final controller = _controller;
    if (controller == null || details.pointerCount < 2) return;
    final next = (_zoomAtStart * details.scale).clamp(_minZoom, _maxZoom);
    if ((next - _zoom).abs() < 0.01) return;
    setState(() {
      _zoom = next;
      _showZoom = true;
    });
    _zoomHint?.cancel();
    _zoomHint = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showZoom = false);
    });
    try {
      await controller.setZoomLevel(next);
    } on CameraException catch (e) {
      AppLogger.debug('Zoom failed: ${e.code}');
    }
  }

  Future<void> _onTapToFocus(TapUpDetails details, Size size) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final point = Offset(
      (details.localPosition.dx / size.width).clamp(0.0, 1.0),
      (details.localPosition.dy / size.height).clamp(0.0, 1.0),
    );
    setState(() {
      _focusAt = details.localPosition;
      _focusTick++;
    });
    unawaited(HapticFeedback.selectionClick());
    try {
      if (controller.value.focusPointSupported) {
        await controller.setFocusPoint(point);
      }
      if (controller.value.exposurePointSupported) {
        await controller.setExposurePoint(point);
      }
    } on CameraException catch (e) {
      AppLogger.debug('Focus failed: ${e.code}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediaScrimStrong,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;
    final error = _error;
    if (error != null) {
      return _ErrorView(
        message: switch (error) {
          _CameraError.unavailable => l10n.capsulesCameraUnavailable,
          _CameraError.accessDenied => l10n.capsulesCameraAccessDenied,
          _CameraError.startFailed => l10n.capsulesCameraStartFailed,
        },
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center();
    }

    return SafeArea(
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: RepaintBoundary(
                  key: _previewKey,
                  child: CameraPreview(
                    controller,
                    child: LayoutBuilder(
                      builder: (context, constraints) => GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onScaleStart: _onScaleStart,
                        onScaleUpdate: _onScaleUpdate,
                        onTapUp: (d) => _onTapToFocus(d, constraints.biggest),
                        child: Stack(
                          children: [
                            if (_frozen case final frozen?)
                              Positioned.fill(
                                child: RawImage(
                                  image: frozen,
                                  fit: BoxFit.fill,
                                ),
                              ),
                            if (_focusAt case final Offset at)
                              Positioned(
                                left: at.dx - 32,
                                top: at.dy - 32,
                                child: _FocusRing(key: ValueKey(_focusTick)),
                              ),
                            Align(
                              alignment: const Alignment(0, 0.85),
                              child: AnimatedOpacity(
                                opacity: _showZoom ? 1 : 0,
                                duration: AppMotion.of(context, AppMotion.fast),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.mediaScrim,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_zoom.toStringAsFixed(1)}×',
                                    style: const TextStyle(
                                      color: AppColors.onMedia,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            IgnorePointer(
                              child: AnimatedOpacity(
                                opacity: _shutterBlink ? 0.85 : 0,
                                duration: AppMotion.quick,
                                child: const ColoredBox(
                                  color: AppColors.onMedia,
                                  child: SizedBox.expand(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Semantics(
                      button: true,
                      label: l10n.commonBack,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          AppIcons.cameraBack,
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: switch (_flash) {
                        FlashMode.off => l10n.capsulesCameraFlashOff,
                        FlashMode.auto => l10n.capsulesCameraFlashAuto,
                        _ => l10n.capsulesCameraFlashOn,
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleFlash,
                        // A 44 dp target around the 40 dp picture.
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Image.asset(
                                  _flash == FlashMode.off
                                      ? AppIcons.cameraFlashOff
                                      : AppIcons.cameraFlashOn,
                                  width: 40,
                                  height: 40,
                                ),
                                // Automatic: the lit bolt with an "A".
                                if (_flash == FlashMode.auto)
                                  Positioned(
                                    right: -4,
                                    bottom: -2,
                                    child: ExcludeSemantics(
                                      child: Text(
                                        l10n.capsulesCameraFlashAutoBadge,
                                        style: const TextStyle(
                                          fontFamily: kAppFontFamily,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.onMedia,
                                        ),
                                      ),
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
              // How to record a loop, until one is being recorded.
              if (FeatureFlags.loopCapsules && !_capturing)
                Positioned(
                  bottom: 112,
                  left: 0,
                  right: 0,
                  child: ExcludeSemantics(
                    child: Text(
                      l10n.capsulesCameraHoldForLoop,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onMedia,
                        shadows: [
                          Shadow(color: AppColors.mediaScrim, blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 5,
                left: 0,
                right: 0,
                child: Center(
                  child: Semantics(
                    button: true,
                    label: FeatureFlags.loopCapsules
                        ? l10n.capsulesCameraTakePhotoOrLoop
                        : l10n.capsulesCameraTakePhoto,
                    child: GestureDetector(
                      onTap: _capture,
                      onLongPressStart: FeatureFlags.loopCapsules
                          ? (_) => unawaited(_startLoop())
                          : null,
                      onLongPressEnd: FeatureFlags.loopCapsules
                          ? (_) => _stopLoop()
                          : null,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            AppIcons.cameraShutter,
                            width: 100,
                            height: 100,
                          ),
                          // How much of the loop is recorded.
                          if (_looping || _frames.isNotEmpty)
                            SizedBox(
                              width: 108,
                              height: 108,
                              child: CircularProgressIndicator(
                                value: _frames.length / _maxFrames,
                                strokeWidth: 5,
                                color: AppColors.brandGreen,
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
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Semantics(
                  button: true,
                  label: l10n.capsulesCameraSwitch,
                  child: GestureDetector(
                    onTap: _switchCamera,
                    child: Image.asset(
                      AppIcons.cameraSwitch,
                      width: 50,
                      height: 50,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Image.asset(AppIcons.cameraBack, width: 50, height: 50),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.onMedia, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The ring where the user tapped to focus: shrinks in, then fades out.
class _FocusRing extends StatefulWidget {
  const _FocusRing({super.key});

  @override
  State<_FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<_FocusRing>
    with SingleTickerProviderStateMixin {
  // Shrinks in, holds, fades: 350 ms in all (the style rule's longest).
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.reveal,
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = AppMotion.reduced(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          if (t >= 1) return const SizedBox.shrink();
          // Reduced motion: the ring just shows where it focused, then goes.
          final scale = still
              ? 1.0
              : 1.25 - 0.25 * Curves.easeOut.transform((t / 0.4).clamp(0, 1));
          final fade = still || t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Faded through the colour: no opacity layer.
                border: Border.all(
                  color: AppColors.onMedia.withValues(alpha: fade),
                  width: 2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
