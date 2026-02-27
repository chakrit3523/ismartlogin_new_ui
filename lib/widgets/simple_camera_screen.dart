import 'package:camera/camera.dart';
import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';

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
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
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
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        print('No cameras available');
        return;
      }

      // Try to find front camera first
      _selectedCameraIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;

      await _startCamera(_selectedCameraIndex);
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _startCamera(int index) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      // Set flash mode to off by default
      await _cameraController!.setFlashMode(FlashMode.off);
      _flashMode = FlashMode.off;

      if (mounted) {
        blocSetState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error starting camera: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;

    blocSetState(() {
      _isCameraInitialized = false;
    });

    await _startCamera(_selectedCameraIndex);
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      FlashMode newFlashMode;
      if (_flashMode == FlashMode.off) {
        // Use 'always' for front camera (often uses screen flash), 'torch' for back camera
        if (_cameras[_selectedCameraIndex].lensDirection ==
            CameraLensDirection.front) {
          newFlashMode = FlashMode.always;
        } else {
          newFlashMode = FlashMode.torch;
        }
      } else {
        newFlashMode = FlashMode.off;
      }

      await _cameraController!.setFlashMode(newFlashMode);
      blocSetState(() {
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

    blocSetState(() {
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
      blocSetState(() {
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

            // 2. Top Controls
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Flash & Switch Camera Group
                        Row(
                          children: [
                            // Flash Toggle
                            GestureDetector(
                              onTap: _toggleFlash,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _flashMode != FlashMode.off
                                      ? Colors.yellow.withValues(alpha: 0.9)
                                      : Colors.white.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _flashMode != FlashMode.off
                                      ? Icons.flash_on
                                      : Icons.flash_off,
                                  color: Colors.black,
                                  size: 24,
                                ),
                              ),
                            ),
                            SizedBox(width: 15),
                            // Switch Camera
                            if (_cameras.length > 1)
                              GestureDetector(
                                onTap: _switchCamera,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.flip_camera_ios,
                                    color: Colors.black,
                                    size: 24,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Close Button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                  alpha: 0.8), // Semi-transparent white
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close,
                                color: Colors.black, size: 24),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Kanit',
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ],
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
