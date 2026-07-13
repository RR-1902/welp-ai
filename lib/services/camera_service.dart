import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  Future<void> initialize() async {
    if (isInitialized) {
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No camera available on this device.');
    }

    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await controller.initialize();
    _controller = controller;
  }

  Future<String?> captureFrameBase64() async {
    if (!isInitialized) {
      return null;
    }

    final file = await _controller!.takePicture();
    final bytes = await File(file.path).readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
