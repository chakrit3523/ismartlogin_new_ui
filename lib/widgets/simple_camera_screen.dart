import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Simple Camera Screen without AI face detection
class SimpleCameraScreen extends StatefulWidget {
  final String title;

  const SimpleCameraScreen({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  _SimpleCameraScreenState createState() => _SimpleCameraScreenState();
}

class _SimpleCameraScreenState extends State<SimpleCameraScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  FlashMode _flashMode = FlashMode.off; // Flash off by default

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('No cameras available');
        return;
      }

      // Use front camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      // Set flash mode to off by default
      await _cameraController!.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      FlashMode newFlashMode;
      if (_flashMode == FlashMode.off) {
        newFlashMode = FlashMode.torch; // Use torch for continuous light
      } else {
        newFlashMode = FlashMode.off;
      }

      await _cameraController!.setFlashMode(newFlashMode);
      setState(() {
        _flashMode = newFlashMode;
      });
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final image = await _cameraController!.takePicture();

      // Return image path to previous screen
      if (mounted) {
        Navigator.pop(context, image.path);
      }
    } catch (e) {
      print('Error capturing photo: $e');
      setState(() {
        _isCapturing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. Camera Preview
            if (_isCameraInitialized && _cameraController != null)
              Container(
                width: size.width,
                height: size.height,
                child: CameraPreview(_cameraController!),
              ),

            // Loading indicator
            if (!_isCameraInitialized)
              Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // 2. Flash Toggle Button (Top Left)
            Positioned(
              top: 20,
              left: 20,
              child: SafeArea(
                child: GestureDetector(
                  onTap: _toggleFlash,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _flashMode == FlashMode.torch
                          ? Colors.yellow.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _flashMode == FlashMode.torch
                          ? Icons.flash_on
                          : Icons.flash_off,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

            // 3. Close Button (Top Right)
            Positioned(
              top: 20,
              right: 20,
              child: SafeArea(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: 0.8), // Semi-transparent white
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.black, size: 24),
                  ),
                ),
              ),
            ),

            // 3. Shutter Button (Bottom Center)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _isCapturing ? null : _capturePhoto,
                  child: Container(
                    width: 80,
                    height: 80,
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _isCapturing
                          ? Center(
                              child: CircularProgressIndicator(
                                color: Colors.blue,
                                strokeWidth: 2,
                              ),
                            )
                          : SizedBox(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
