import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/widgets/oval_frame_painter.dart';

/// Face Detection Camera Screen with oval frame guidance
class FaceDetectionCamera extends StatefulWidget {
  final String title; // "เข้างาน" or "ออกงาน"
  final Function(File) onCapture;

  const FaceDetectionCamera({
    super.key,
    required this.title,
    required this.onCapture,
  });

  @override
  State<FaceDetectionCamera> createState() => _FaceDetectionCameraState();
}

class _FaceDetectionCameraState extends State<FaceDetectionCamera>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;

  late AnimationController _scanController;

  bool _isDetecting = false;
  bool _isCameraInitialized = false;
  bool _captureInProgress = false;

  List<Face> _faces = [];
  double _faceQuality = 0.0; // 0-100%
  String _statusMessage = 'กำลังเปิดกล้อง...';

  // Stability tracking
  int _stableFrameCount = 0;
  // static const int _requiredStableFrames = 20; // Removed as unused
  double _lastQuality = 0.0;
  Offset? _lastFaceCenter;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Setup scanning animation
    _scanController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    _initializeCamera();
    _initializeFaceDetector();
  }

  @override
  void dispose() {
    _scanController.dispose(); // Dispose animation
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector?.close();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No cameras available');

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      if (mounted) {
        blocSetState(() {
          _isCameraInitialized = true;
          _statusMessage = 'จัดตำแหน่งใบหน้าให้อยู่ในกรอบ';
        });

        // Delay to ensure UI is ready
        await Future.delayed(Duration(milliseconds: 500));
        _cameraController!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        blocSetState(() {
          _statusMessage = 'ไม่สามารถเปิดกล้องได้';
        });
      }
    }
  }

  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        enableTracking: false,
        minFaceSize: 0.15,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  DateTime? _lastProcessTime;

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || _captureInProgress || !_isCameraInitialized) return;

    // Throttle: Process every 450ms
    final now = DateTime.now();
    if (_lastProcessTime != null &&
        now.difference(_lastProcessTime!).inMilliseconds < 450) {
      return;
    }

    _isDetecting = true;
    _lastProcessTime = now;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final faces = await _faceDetector!.processImage(inputImage);

      if (mounted) {
        final currentFaceCenter =
            faces.isNotEmpty ? faces.first.boundingBox.center : null;

        blocSetState(() {
          _faces = faces;
          _faceQuality = _calculateFaceQuality(faces);
          _updateStatusMessage(faces);

          if (_faceQuality >= 95.0 && _lastQuality >= 95.0) {
            if (_lastFaceCenter != null && currentFaceCenter != null) {
              final distanceMoved =
                  (currentFaceCenter - _lastFaceCenter!).distance;
              if (distanceMoved < 15.0) {
                // Tolerant movement
                _stableFrameCount++;
              } else {
                _stableFrameCount = 0;
              }
            }
          } else {
            _stableFrameCount = 0;
          }

          _lastQuality = _faceQuality;
          _lastFaceCenter = currentFaceCenter;
        });

        if (_stableFrameCount >= 4 && !_captureInProgress) {
          //_autoCapture(); // Disable auto capture as requested
        }
      }
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      if (mounted) _isDetecting = false;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize =
          Size(image.width.toDouble(), image.height.toDouble());
      final InputImageRotation imageRotation = InputImageRotation
          .rotation0deg; // Front camera usually 0 or needs adjustment

      final InputImageFormat inputImageFormat = Platform.isAndroid
          ? InputImageFormat.nv21
          : InputImageFormat.bgra8888;

      // Handle iOS/Android rotation differences if needed
      // But for now, valid format is key to preventing crash

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (e) {
      print('Error converting camera image: $e');
      return null;
    }
  }

  double _calculateFaceQuality(List<Face> faces) {
    if (faces.isEmpty) return 0.0;

    final face = faces.first;
    double score = 0.0;

    // Get camera image size (not screen size!)
    if (_cameraController == null || !_isCameraInitialized) return 0.0;
    final previewSize = _cameraController!.value.previewSize;
    if (previewSize == null) return 0.0;

    // Camera preview size on iOS is rotated (width/height swapped for portrait)
    final imageWidth = previewSize.height; // Swapped for portrait
    final imageHeight = previewSize.width;

    // 1. Face Size (40 points) - Check if face is substantial part of frame
    final faceWidth = face.boundingBox.width;
    final faceHeight = face.boundingBox.height;
    final faceArea = faceWidth * faceHeight;
    final imageArea = imageWidth * imageHeight;
    final sizeRatio = faceArea / imageArea;

    // Relaxed thresholds: 8% - 60% of image area
    if (sizeRatio >= 0.08 && sizeRatio <= 0.60) {
      score += 40.0; // Good size
    } else if (sizeRatio >= 0.05 && sizeRatio <= 0.70) {
      score += 20.0; // Acceptable
    }

    // 2. Face Centering (40 points) - Percentage-based
    final faceCenterX = face.boundingBox.center.dx;
    final faceCenterY = face.boundingBox.center.dy;
    final imageCenterX = imageWidth / 2;
    final imageCenterY = imageHeight / 2;

    // Calculate offset as percentage of image dimension
    final offsetXPercent = (faceCenterX - imageCenterX).abs() / imageWidth;
    final offsetYPercent = (faceCenterY - imageCenterY).abs() / imageHeight;

    // Relaxed: within 15% of center is perfect, 25% is good
    if (offsetXPercent < 0.15 && offsetYPercent < 0.15) {
      score += 40.0; // Perfect center
    } else if (offsetXPercent < 0.25 && offsetYPercent < 0.25) {
      score += 25.0; // Good center
    } else if (offsetXPercent < 0.35 && offsetYPercent < 0.35) {
      score += 10.0; // Acceptable
    }

    // 3. Face Angle (20 points) - Be lenient
    final headEulerAngleY = face.headEulerAngleY ?? 0.0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0.0;

    if (headEulerAngleY.abs() < 15 && headEulerAngleZ.abs() < 15) {
      score += 20.0; // Face mostly straight
    } else if (headEulerAngleY.abs() < 25 && headEulerAngleZ.abs() < 25) {
      score += 10.0;
    }

    return score.clamp(0.0, 100.0);
  }

  void _updateStatusMessage(List<Face> faces) {
    if (faces.isEmpty) {
      _statusMessage = 'ไม่พบใบหน้า กรุณาเข้าใกล้';
      return;
    }

    if (_cameraController == null || !_isCameraInitialized) return;
    final previewSize = _cameraController!.value.previewSize;
    if (previewSize == null) return;

    final imageWidth = previewSize.height;
    final imageHeight = previewSize.width;

    final face = faces.first;
    final faceCenterX = face.boundingBox.center.dx;
    final faceCenterY = face.boundingBox.center.dy;
    final imageCenterX = imageWidth / 2;
    final imageCenterY = imageHeight / 2;

    final offsetXPercent = (faceCenterX - imageCenterX) / imageWidth;
    final offsetYPercent = (faceCenterY - imageCenterY) / imageHeight;

    // Check Centering - use signed value for direction
    if (offsetXPercent.abs() > 0.15) {
      // iOS front camera is mirrored, so directions need to be flipped
      if (offsetXPercent > 0) {
        _statusMessage = '< ขยับหน้าไปทางซ้าย';
      } else {
        _statusMessage = 'ขยับหน้าไปทางขวา >';
      }
      return;
    }

    if (offsetYPercent.abs() > 0.15) {
      if (offsetYPercent > 0) {
        _statusMessage = 'ขยับขึ้นบนอีกนิด ^';
      } else {
        _statusMessage = 'ขยับลงล่างอีกนิด v';
      }
      return;
    }

    // Check Size
    final faceArea = face.boundingBox.width * face.boundingBox.height;
    final imageArea = imageWidth * imageHeight;
    final sizeRatio = faceArea / imageArea;

    if (sizeRatio < 0.08) {
      _statusMessage = 'กรุณาขยับเข้ามาใกล้ๆ';
      return;
    } else if (sizeRatio > 0.60) {
      _statusMessage = 'ใกล้ไปแล้ว! ถอยออกหน่อย';
      return;
    }

    // All conditions met
    if (_faceQuality >= 80) {
      _statusMessage = 'กดปุ่มเพื่อถ่ายภาพ';
    } else {
      _statusMessage = 'จัดหน้าให้ตรงกรอบ...';
    }
  }

  // Auto-capture removed as per request
  // Future<void> _autoCapture() async { ... }

  Future<void> _manualCapture() async {
    if (_captureInProgress || !_isCameraInitialized) return;

    blocSetState(() {
      _captureInProgress = true;
      _statusMessage = 'กำลังถ่ายภาพ...';
    });

    try {
      // Optimization: No need to stop stream explicitly if takePicture works,
      // but stopping ensures no conflict on some devices.
      await _cameraController!.stopImageStream();

      // Small delay
      await Future.delayed(Duration(milliseconds: 200));

      final XFile file = await _cameraController!.takePicture();
      widget.onCapture(File(file.path));
    } catch (e) {
      print('Error in manual capture: $e');
      blocSetState(() {
        _captureInProgress = false;
        _statusMessage = 'เกิดข้อผิดพลาด กรุณาลองใหม่';
      });
      // Try to restart stream
      try {
        _cameraController!.startImageStream(_processCameraImage);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraInitialized && _cameraController != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize!.height,
                  height: _cameraController!.value.previewSize!.width,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),

          // Loading indicator while camera initializes
          if (!_isCameraInitialized)
            Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Oval Frame Overlay
          if (_isCameraInitialized)
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, child) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: OvalFramePainter(
                    faceQuality: _faceQuality,
                    screenSize: MediaQuery.of(context).size,
                    faces: _faces,
                    scanValue: _scanController.value,
                  ),
                );
              },
            ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.black.withValues(alpha: 0.5),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontFamily: FontStyles().FontFamily,
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
            ),
          ),

          // Bottom UI: Progress and Status
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quality Progress
                    Container(
                      width: double.infinity,
                      child: Column(
                        children: [
                          Text(
                            '${_faceQuality.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              fontFamily: FontStyles().FontFamily,
                            ),
                          ),
                          SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _faceQuality / 100,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _faceQuality >= 90
                                    ? Colors.green
                                    : _faceQuality >= 60
                                        ? Colors.yellow
                                        : Colors.cyan,
                              ),
                              minHeight: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Status Message
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          fontFamily: FontStyles().FontFamily,
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: 20),

                    // Manual Capture Button (Conditional)
                    if (!_captureInProgress)
                      GestureDetector(
                        onTap: () {
                          if (_faceQuality >= 80) {
                            _manualCapture();
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _faceQuality >= 80
                                    ? Colors.white
                                    : Colors.grey,
                                width: 4),
                            color: _faceQuality >= 80
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color:
                                _faceQuality >= 80 ? Colors.white : Colors.grey,
                            size: 36,
                          ),
                        ),
                      ),

                    if (_captureInProgress)
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),

                    SizedBox(height: 10),

                    Text(
                      'จัดตำแหน่งให้ตรงกรอบ แล้วกดถ่าย',
                      style: TextStyle(
                        fontFamily: FontStyles().FontFamily,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
