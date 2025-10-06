import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:later/views/pages/capsule_related_pages/capsule_creation_page.dart';
import 'package:page_transition/page_transition.dart';

class CameraPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const CameraPage({super.key, this.arguments});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  List<CameraDescription> cameras = [];
  CameraController? cameraController;

  CameraDescription? frontCamera;
  CameraDescription? backCamera;
  bool isFront = false;

  @override
  void initState() {
    super.initState();
    _setupCameraController();
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black87, body: _buildUI());
  }

  Widget _buildUI() {
    if (cameraController == null ||
        cameraController?.value.isInitialized == false) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: CameraPreview(cameraController!),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Image.asset(
                        'assets/images/icons/camera/whitearrow.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // TODO: Add action for right button
                      },
                      child: Image.asset(
                        'assets/images/icons/camera/Flashoff.png',
                        width: 40,
                        height: 40,
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
                  child: GestureDetector(
                    onTap: () async {
                      if (cameraController == null) return;

                      XFile picture = await cameraController!.takePicture();

                      if (!mounted) return;

                      Navigator.pushReplacement(
                        context,
                        PageTransition(
                          type: PageTransitionType.fade,
                          duration: const Duration(milliseconds: 10),
                          reverseDuration: const Duration(milliseconds: 10),
                          child: CapsuleCreationPage(
                            imagePath: picture.path,
                            initialPrivacy: widget.arguments?['privacy'],
                          ),
                        ),
                      );
                    },
                    child: Image.asset(
                      'assets/images/icons/camera/123.png',
                      width: 100,
                      height: 100,
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
                GestureDetector(
                  onTap: _switchCamera,
                  child: Image.asset(
                    'assets/images/icons/camera/Camera.png',
                    width: 50,
                    height: 50,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setupCameraController() async {
    List<CameraDescription> cameras = await availableCameras();

    frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    await _initCameraController(backCamera!);
    isFront = false;
  }

  Future<void> _initCameraController(
    CameraDescription cameraDescription,
  ) async {
    final oldController = cameraController;
    if (oldController != null) {
      await oldController.dispose();
    }

    cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
    );

    try {
      await cameraController!.initialize();
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }

    if (mounted) setState(() {});
  }

  void _switchCamera() {
    if (frontCamera != null && backCamera != null) {
      isFront = !isFront;
      _initCameraController(isFront ? frontCamera! : backCamera!);
    }
  }
}
