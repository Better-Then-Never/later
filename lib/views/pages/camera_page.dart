import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? cameraController;
  bool isCameraReady = false;
  List<CameraDescription>? cameras;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  Future<void> initialize() async {
    final statuses = await [Permission.camera, Permission.microphone].request();

    final camGranted = statuses[Permission.camera]?.isGranted ?? false;
    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;

    if (!camGranted || !micGranted) {
      closeCam();
      return;
    }

    cameras = await availableCameras();

    if (cameras!.isEmpty) {
      closeCam();
      return;
    }

    cameraController = CameraController(cameras!.first, ResolutionPreset.max);

    try {
      await cameraController!.initialize();
      setState(() {
        isCameraReady = true;
      });
    } catch (e) {
      closeCam();
      return;
    }
  }

  void closeCam() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraReady) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: CameraPreview(cameraController!),
      ),
    );
  }
}
