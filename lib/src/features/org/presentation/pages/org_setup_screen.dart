import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_place/google_place.dart';

import 'package:awesome_dialog/awesome_dialog.dart';

import 'package:ismart_login/src/features/org/presentation/pages/time_setup_screen.dart';

// Result class to pass back location data
class OrgSetupResult {
  final double latitude;
  final double longitude;
  final String address;
  final int radius;

  OrgSetupResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.radius,
  });
}

class OrgSetupScreen extends StatefulWidget {
  final String orgName;
  final Function(double lat, double lng, String address, int radius)?
      onCreateOrg;

  const OrgSetupScreen({
    Key? key,
    required this.orgName,
    this.onCreateOrg,
  }) : super(key: key);

  @override
  _OrgSetupScreenState createState() => _OrgSetupScreenState();
}

class _OrgSetupScreenState extends State<OrgSetupScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = LatLng(13.736717, 100.523186); // Default: Bangkok
  String _address = 'กรุณาเลือกตำแหน่งบนแผนที่';
  int _radius = 50; // Default radius in meters
  bool _isLoading = false;
  bool _hasSelectedLocation = false; // Track if user has selected location
  final TextEditingController _radiusController =
      TextEditingController(text: '50');
  late TextEditingController _orgNameController;

  @override
  void initState() {
    super.initState();
    _orgNameController = TextEditingController(text: widget.orgName);
    // Auto-get current location to center map, but do not select it
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _radiusController.dispose();
    _orgNameController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        blocSetState(() {
          _isLoading = false;
          _address = 'Location services disabled';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          blocSetState(() {
            _isLoading = false;
            _address = 'Location permission denied';
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      blocSetState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // _getAddressFromLatLng(_currentPosition); // Don't fetch address on auto-locate

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(_currentPosition),
        );
      }
      // Note: We do NOT call _getAddressFromLatLng here to keep it unselected
    } catch (e) {
      if (mounted) {
        blocSetState(() {
          _isLoading = false;
          // _address = 'Could not get location'; // Don't show error to keep UI clean
        });
      }
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      // Set Thai locale for address
      await geocoding.setLocaleIdentifier('th_TH');
      List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks[0];
        blocSetState(() {
          _address =
              '${place.street ?? ''} ${place.subLocality ?? ''} ${place.locality ?? ''} ${place.administrativeArea ?? ''} ${place.postalCode ?? ''}';
        });
      }
    } catch (e) {
      blocSetState(() {
        _address = 'ไม่สามารถโหลดที่อยู่ได้';
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    blocSetState(() {
      _currentPosition = position.target;
    });
  }

  void _onCameraIdle() {
    if (_hasSelectedLocation) {
      _getAddressFromLatLng(_currentPosition);
    }
  }

  void _openFullMapPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => FullMapPickerScreen(
          initialPosition: _currentPosition,
          orgName: widget.orgName,
        ),
      ),
    );

    if (result != null) {
      blocSetState(() {
        _currentPosition = result;
        _hasSelectedLocation = true; // User has selected location
      });
      _getAddressFromLatLng(result);
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(result));
      }
    }
  }

  // Navigate to TimeSetupScreen
  void _onNextPressed() {
    String orgName = _orgNameController.text.trim();

    // Validate Org Name
    if (orgName.isEmpty) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.bottomSlide,
        title: 'ข้อมูลไม่ครบถ้วน',
        desc: 'กรุณากรอกชื่อกลุ่มหรือองค์กร',
        btnOkOnPress: () {},
        btnOkText: 'ตกลง',
      ).show();
      return;
    }

    // Validate location selection
    if (!_hasSelectedLocation) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.bottomSlide,
        title: 'ยังไม่ได้เลือกตำแหน่ง',
        desc: 'กรุณาเลือกตำแหน่งบนแผนที่',
        btnOkOnPress: () {},
        btnOkColor: Colors.orange,
        btnOkText: 'ตกลง',
      ).show();
      return;
    }

    // Navigate to TimeSetupScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimeSetupScreen(
          orgName: orgName,
          latitude: _currentPosition.latitude,
          longitude: _currentPosition.longitude,
          address: _address,
          radius: _radius,
          onCreateOrg: widget.onCreateOrg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Layer 1: Background image - covers upper portion
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/other/bg_regis.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Layer 2: White background behind form (starts below the card's top)
            Positioned(
              top:
                  200, // Start below form card's top so rounded corners show on blue
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.white,
              ),
            ),
            // Layer 3: Content on top
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Section
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 24, top: 40, bottom: 16),
                    child: Text(
                      'ตั้งค่าการเข้าออกงาน',
                      style: GoogleFonts.kanit(
                        fontSize: 25,
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                        height: 38 / 25,
                      ),
                    ),
                  ),

                  // Content Card - Floating on white background
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Organization Name Section
                                    Text(
                                      'ชื่อกลุ่ม/องค์กร',
                                      style: GoogleFonts.kanit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                        color: Color(0xFF000000),
                                        height: 1.5,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    SizedBox(
                                      height: 43,
                                      child: TextField(
                                        controller: _orgNameController,
                                        style: GoogleFonts.kanit(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: Colors.grey[300]!,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: Colors.grey[300]!,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: Color(0xFF000000),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 20),

                                    // Map Section
                                    Text(
                                      'ปักหมุดตำแหน่งสำหรับเข้าออกงาน',
                                      style: GoogleFonts.kanit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                        color: Color(0xFF000000),
                                        height: 1.5,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: _openFullMapPicker,
                                      child: Stack(
                                        children: [
                                          Container(
                                            height: 150,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey[300]!,
                                                width: 1,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: _isLoading
                                                  ? Center(
                                                      child:
                                                          CircularProgressIndicator())
                                                  : AbsorbPointer(
                                                      child: GoogleMap(
                                                        onMapCreated:
                                                            (controller) {
                                                          _mapController =
                                                              controller;
                                                        },
                                                        initialCameraPosition:
                                                            CameraPosition(
                                                          target:
                                                              _currentPosition,
                                                          zoom: 16,
                                                        ),
                                                        onCameraMove:
                                                            _onCameraMove,
                                                        onCameraIdle:
                                                            _onCameraIdle,
                                                        zoomControlsEnabled:
                                                            false,
                                                        mapToolbarEnabled:
                                                            false,
                                                        myLocationButtonEnabled:
                                                            false,
                                                        scrollGesturesEnabled:
                                                            false,
                                                        zoomGesturesEnabled:
                                                            false,
                                                        rotateGesturesEnabled:
                                                            false,
                                                        tiltGesturesEnabled:
                                                            false,
                                                        circles:
                                                            _hasSelectedLocation
                                                                ? {
                                                                    Circle(
                                                                      circleId:
                                                                          CircleId(
                                                                              'radiusCircle'),
                                                                      center:
                                                                          _currentPosition,
                                                                      radius: _radius
                                                                          .toDouble(),
                                                                      fillColor: Color(
                                                                              0xFF0663F7)
                                                                          .withValues(
                                                                              alpha: 0.2),
                                                                      strokeColor:
                                                                          Color(
                                                                              0xFF0663F7),
                                                                      strokeWidth:
                                                                          1,
                                                                    ),
                                                                  }
                                                                : {},
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          // Pin overlay - Shifted up to align tip with center, only if selected
                                          if (_hasSelectedLocation)
                                            Positioned.fill(
                                              child: Center(
                                                child: Transform.translate(
                                                  offset: Offset(0, -18),
                                                  child: Icon(
                                                    Icons.location_pin,
                                                    size: 36,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          // Edit button - only this is tappable
                                          Positioned(
                                            bottom: 8,
                                            left: 8,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black12,
                                                    blurRadius: 2,
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.edit_location_alt,
                                                      size: 14,
                                                      color: Colors.grey[600]),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'แก้ไขตำแหน่งในแผนที่',
                                                    style: GoogleFonts.kanit(
                                                      fontSize: 11,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      _address,
                                      style: GoogleFonts.kanit(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),

                                    SizedBox(height: 24),

                                    // Radius Section
                                    Row(
                                      children: [
                                        Text(
                                          'รัศมีในการเข้าออกงาน',
                                          style: GoogleFonts.kanit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.normal,
                                            color: Color(0xFF000000),
                                            height: 1.5,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Container(
                                          width: 60,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey[300]!),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: TextField(
                                              textAlign: TextAlign.center,
                                              keyboardType:
                                                  TextInputType.number,
                                              style: GoogleFonts.kanit(
                                                  fontSize: 14),
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.zero,
                                                isDense: true,
                                              ),
                                              controller: _radiusController,
                                              onChanged: (value) {
                                                int? val = int.tryParse(value);
                                                if (val != null) {
                                                  if (val > 100) {
                                                    val = 100;
                                                    _radiusController.text =
                                                        '100';
                                                    _radiusController
                                                            .selection =
                                                        TextSelection
                                                            .fromPosition(
                                                      TextPosition(
                                                          offset:
                                                              _radiusController
                                                                  .text.length),
                                                    );
                                                  }
                                                  blocSetState(() {
                                                    _radius = val!;
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'เมตร',
                                          style: GoogleFonts.kanit(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'ระยะห่างจากหมุดที่ยังสามารถล็อคอินเข้า-ออกงานได้',
                                      style: GoogleFonts.kanit(
                                        fontSize: 14,
                                        color: const Color.fromARGB(
                                            255, 110, 109, 109),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Next Button - Inside white card at bottom
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 20, right: 20, bottom: 24, top: 16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF21CCD4),
                                      Color(0xFF0663F7)
                                    ],
                                    begin: Alignment(-0.97, -0.24),
                                    end: Alignment(0.97, 0.24),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x29000000),
                                      offset: Offset(0, 3),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _onNextPressed,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'ถัดไป',
                                    style: GoogleFonts.kanit(
                                      fontSize: 21,
                                      color: Colors.white,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Full-screen map picker
class FullMapPickerScreen extends StatefulWidget {
  final LatLng initialPosition;
  final String orgName;

  const FullMapPickerScreen({
    Key? key,
    required this.initialPosition,
    required this.orgName,
  }) : super(key: key);

  @override
  _FullMapPickerScreenState createState() => _FullMapPickerScreenState();
}

class _FullMapPickerScreenState extends State<FullMapPickerScreen>
    with SingleTickerProviderStateMixin {
  late LatLng _selectedPosition;
  String _address = '';
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  bool _hasMoved = false;

  // Tutorial Animation
  late AnimationController _tutorialController;
  late Animation<Offset> _handSlideAnimation;
  late Animation<double> _handOpacityAnimation;
  bool _showTutorial = true;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _getAddressFromLatLng(_selectedPosition);

    _tutorialController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );

    // 1. Hand Sliding Animation (Grab at Center -> Slide Right)
    _handSlideAnimation = TweenSequence<Offset>([
      // Appear at slightly left of center or center
      TweenSequenceItem(
        tween: ConstantTween<Offset>(Offset(0, 0)),
        weight: 20, // Wait/Appear
      ),
      // Press (still at center)
      TweenSequenceItem(
        tween: ConstantTween<Offset>(Offset(0, 0)),
        weight: 10,
      ),
      // Slide Right (Dragging)
      TweenSequenceItem(
        tween: Tween<Offset>(
                begin: Offset(0, 0), end: Offset(0.4, 0)) // Move Right
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      // Release (at new pos)
      TweenSequenceItem(
        tween: ConstantTween<Offset>(Offset(0.4, 0)),
        weight: 10,
      ),
      // Fade out/Reset (doesn't matter)
      TweenSequenceItem(
        tween: ConstantTween<Offset>(Offset(0.4, 0)),
        weight: 20,
      ),
    ]).animate(_tutorialController);

    // 2. Hand Opacity
    _handOpacityAnimation = TweenSequence<double>([
      // Fade In
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      // Stay visible
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 60,
      ),
      // Fade Out
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_tutorialController);

    // Start tutorial loop
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _tutorialController.repeat(count: 2).then((_) {
          if (mounted) {
            blocSetState(() {
              _showTutorial = false;
            });
          }
        });

        // Sync Map Camera with Hand Animation
        _tutorialController.addListener(_onAnimationTick);
      }
    });
  }

  Offset _lastHandOffset = Offset(0, 0);
  bool _isTutorialMovingMap = false;

  void _onAnimationTick() {
    if (_mapController != null && _showTutorial) {
      final currentOffset = _handSlideAnimation.value;
      final delta = currentOffset - _lastHandOffset;
      _lastHandOffset = currentOffset;

      // Only move if there is significant change to avoid jitter
      if (delta.distance > 0.0001) {
        _isTutorialMovingMap = true;

        // Scale factor: 400 pixels seems reasonable for 0.3 offset on a typical screen
        double scale = 500.0;

        _mapController!.moveCamera(
          CameraUpdate.scrollBy(-delta.dx * scale, -delta.dy * scale),
        );

        // Reset flag after a tiny delay to allow onCameraMove to fire and be ignored
        Future.delayed(Duration(milliseconds: 50), () {
          if (mounted) _isTutorialMovingMap = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tutorialController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      // Set Thai locale for address
      await geocoding.setLocaleIdentifier('th_TH');
      List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks[0];
        blocSetState(() {
          _address =
              '${place.street ?? ''} ${place.subLocality ?? ''} ${place.locality ?? ''} ${place.administrativeArea ?? ''} ${place.postalCode ?? ''}';
        });
      }
    } catch (e) {
      blocSetState(() {
        _address = 'ไม่สามารถโหลดที่อยู่ได้';
      });
    }
  }

  // Google Places API key
  static const String _googleApiKey = 'AIzaSyB91yhHGMRWDgLYajpg8ACtG5Dl1YUFFEw';

  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) return;

    try {
      // Use Google Places API to search for places/businesses
      final googlePlace = GooglePlace(_googleApiKey);

      // Search with text search (supports business names, POIs)
      final result = await googlePlace.search.getTextSearch(
        query,
        language: 'th',
        region: 'th',
      );

      if (result != null &&
          result.results != null &&
          result.results!.isNotEmpty) {
        final place = result.results!.first;
        final lat = place.geometry?.location?.lat;
        final lng = place.geometry?.location?.lng;

        if (lat != null && lng != null) {
          LatLng newPosition = LatLng(lat, lng);

          blocSetState(() {
            _selectedPosition = newPosition;
            // Use place name and formatted address
            _address = place.formattedAddress ?? place.name ?? '';
          });

          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(newPosition, 16),
          );
        }
      } else {
        // Fallback to Geocoding for addresses
        List<geocoding.Location> locations =
            await geocoding.locationFromAddress(query);

        if (locations.isNotEmpty) {
          LatLng newPosition = LatLng(
            locations[0].latitude,
            locations[0].longitude,
          );

          blocSetState(() {
            _selectedPosition = newPosition;
          });

          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(newPosition, 16),
          );

          _getAddressFromLatLng(newPosition);
        } else {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.info,
            animType: AnimType.bottomSlide,
            title: 'ไม่พบสถานที่',
            desc: 'กรุณาลองค้นหาด้วยชื่ออื่น',
            btnOkOnPress: () {},
          ).show();
        }
      }
    } catch (e) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.bottomSlide,
        title: 'ไม่พบสถานที่',
        desc: 'เกิดข้อผิดพลาดในการค้นหา: $e',
        btnOkOnPress: () {},
      ).show();
    }
  }

  void _onCameraMove(CameraPosition position) {
    // If tutorial is moving the map, ignore interaction logic
    if (_isTutorialMovingMap) {
      // Just update position without stopping tutorial
      _selectedPosition = position.target;
      return;
    }

    // If user interacts, stop tutorial immediately
    if (_showTutorial) {
      _tutorialController.stop();
      blocSetState(() {
        _showTutorial = false;
        _hasMoved = true;
        _selectedPosition = position.target;
      });
    } else {
      blocSetState(() {
        _selectedPosition = position.target;
        _hasMoved = true;
      });
    }
  }

  void _onCameraIdle() {
    _getAddressFromLatLng(_selectedPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 16,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // Pin overlay
          Center(
            child: Transform.translate(
              offset: Offset(0, -25),
              child: Icon(
                Icons.location_pin,
                size: 50,
                color: Colors.red,
              ),
            ),
          ),

          // Tutorial Hand Overlay
          if (_showTutorial)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _tutorialController,
                    builder: (context, child) {
                      // Pin Bounce: Only bounce when hand stops (approx > 0.7 interval)
                      double bounceValue = 0;
                      if (_tutorialController.value > 0.7) {
                        double t = (_tutorialController.value - 0.7) / 0.3;
                        bounceValue = -10 *
                            (1 - math.cos(t * 2 * 3.14159).abs()) *
                            (1 - t);
                      }

                      // Ripple Effect: Only at the very end
                      double rippleRadius = 0;
                      double rippleOpacity = 0;
                      if (_tutorialController.value > 0.8) {
                        double t = (_tutorialController.value - 0.8) / 0.2;
                        rippleRadius = t * 60;
                        rippleOpacity = 1.0 - t;
                      }

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ripple
                          if (rippleRadius > 0)
                            Opacity(
                              opacity: rippleOpacity,
                              child: Container(
                                width: rippleRadius * 2,
                                height: rippleRadius * 2,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.redAccent, width: 2),
                                ),
                              ),
                            ),

                          // Bouncing Pin (Tutorial)
                          Transform.translate(
                            offset: Offset(0, -25 + bounceValue),
                            child: Icon(
                              Icons.location_pin,
                              size: 50,
                              color: Colors.red,
                            ),
                          ),

                          // Text Only (Stationary, no hand)
                          Positioned(
                            bottom:
                                80, // Adjust position to be below the center pin
                            child: Opacity(
                              opacity: _handOpacityAnimation.value,
                              child: Text(
                                'เลื่อนแผนที่เพื่อเลือกตำแหน่ง',
                                style: GoogleFonts.kanit(
                                  color: Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 2,
                                      color: Colors.white,
                                      offset: Offset(0, 1),
                                    ),
                                    Shadow(
                                      blurRadius: 2,
                                      color: Colors.white,
                                      offset: Offset(0, -1),
                                    ),
                                    Shadow(
                                      blurRadius: 2,
                                      color: Colors.white,
                                      offset: Offset(1, 0),
                                    ),
                                    Shadow(
                                      blurRadius: 2,
                                      color: Colors.white,
                                      offset: Offset(-1, 0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

          // Top bar with search and Title
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'ปักหมุดตำแหน่งสำหรับเข้าออกงาน',
                          style: GoogleFonts.kanit(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.kanit(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ค้นหาสถานที่...',
                              hintStyle: GoogleFonts.kanit(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 14),
                            ),
                            onSubmitted: (value) => _searchPlace(value),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.search, color: Color(0xFF0663F7)),
                          onPressed: () => _searchPlace(_searchController.text),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom card with address and confirm button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _address,
                    style: GoogleFonts.kanit(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _hasMoved ? Color(0xFF0663F7) : Colors.grey[400],
                    ),
                    child: ElevatedButton(
                      onPressed: _hasMoved
                          ? () {
                              Navigator.pop(context, _selectedPosition);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'เลือกตำแหน่งนี้',
                        style: GoogleFonts.kanit(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
