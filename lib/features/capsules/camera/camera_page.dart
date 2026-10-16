import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/models/capsule.dart';

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
  bool _flashOn = false;
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_setup());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
      if (mounted) setState(() => _error = 'No camera available');
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
      await controller.setFlashMode(
        _flashOn ? FlashMode.always : FlashMode.off,
      );
      if (mounted) setState(() => _error = null);
    } on CameraException catch (e) {
      AppLogger.warning('Camera init failed', error: e);
      if (!mounted) return;
      setState(
        () => _error = e.code == 'CameraAccessDenied'
            ? 'Allow camera access in Settings to take a photo'
            : 'The camera could not be started',
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
    final next = !_flashOn;
    try {
      await controller.setFlashMode(next ? FlashMode.always : FlashMode.off);
      if (mounted) setState(() => _flashOn = next);
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
    setState(() => _capturing = true);
    try {
      final picture = await controller.takePicture();
      if (!mounted) return;
      await AppRoutes.toCapsuleCreation(
        context,
        imagePath: picture.path,
        privacy: widget.initialPrivacy,
        recipientId: widget.recipientId,
        replace: true,
      );
    } on CameraException catch (e) {
      AppLogger.warning('Taking the picture failed', error: e);
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black87, body: _buildBody());
  }

  Widget _buildBody() {
    final error = _error;
    if (error != null) return _ErrorView(message: error);
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
                child: CameraPreview(controller),
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
                      label: 'Back',
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
                      label: _flashOn ? 'Flash on' : 'Flash off',
                      child: GestureDetector(
                        onTap: _toggleFlash,
                        child: Image.asset(
                          _flashOn
                              ? AppIcons.cameraFlashOn
                              : AppIcons.cameraFlashOff,
                          width: 40,
                          height: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 5,
                left: 0,
                right: 0,
                child: Center(
                  child: Semantics(
                    button: true,
                    label: 'Take photo',
                    child: GestureDetector(
                      onTap: _capture,
                      child: Image.asset(
                        AppIcons.cameraShutter,
                        width: 100,
                        height: 100,
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
                  label: 'Switch camera',
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
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
