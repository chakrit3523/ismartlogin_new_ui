import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:ismart_login/page/org/time_setup_screen.dart';

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
    // Do not auto-get current location - user must select manually
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
        setState(() {
          _isLoading = false;
          _address = 'Location services disabled';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _address = 'Location permission denied';
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      _getAddressFromLatLng(_currentPosition);

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(_currentPosition),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _address = 'Could not get location';
      });
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      // Set Thai locale for address
      await setLocaleIdentifier('th_TH');
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address =
              '${place.street ?? ''} ${place.subLocality ?? ''} ${place.locality ?? ''} ${place.administrativeArea ?? ''} ${place.postalCode ?? ''}';
        });
      }
    } catch (e) {
      setState(() {
        _address = 'ไม่สามารถโหลดที่อยู่ได้';
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _currentPosition = position.target;
    });
  }

  void _onCameraIdle() {
    _getAddressFromLatLng(_currentPosition);
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
      setState(() {
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
    // Validate org name
    String orgName = _orgNameController.text.trim();
    if (orgName.isEmpty) {
      EasyLoading.showError('กรุณากรอกชื่อกลุ่มหรือองค์กร');
      return;
    }

    // Validate location selection
    if (!_hasSelectedLocation) {
      EasyLoading.showError('กรุณาเลือกตำแหน่งบนแผนที่');
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
                            color: Colors.black.withOpacity(0.1),
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
                                      'ชื่อกลุ่มหรือองค์กร',
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
                                      'ปักหมุดบนแผนที่สำหรับล็อกอินเข้าออกงาน',
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
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          // Pin overlay
                                          Positioned.fill(
                                            child: Center(
                                              child: Icon(
                                                Icons.location_pin,
                                                size: 36,
                                                color: Colors.red,
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
                                          'รัศมีในการล็อกอิน',
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
                                                setState(() {
                                                  _radius =
                                                      int.tryParse(value) ?? 50;
                                                });
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

class _FullMapPickerScreenState extends State<FullMapPickerScreen> {
  late LatLng _selectedPosition;
  String _address = '';
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _getAddressFromLatLng(_selectedPosition);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      // Set Thai locale for address
      await setLocaleIdentifier('th_TH');
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address =
              '${place.street ?? ''} ${place.subLocality ?? ''} ${place.locality ?? ''} ${place.administrativeArea ?? ''} ${place.postalCode ?? ''}';
        });
      }
    } catch (e) {
      setState(() {
        _address = 'ไม่สามารถโหลดที่อยู่ได้';
      });
    }
  }

  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) return;

    try {
      EasyLoading.show(status: 'กำลังค้นหา...');
      List<Location> locations = await locationFromAddress(query);
      EasyLoading.dismiss();

      if (locations.isNotEmpty) {
        LatLng newPosition = LatLng(
          locations[0].latitude,
          locations[0].longitude,
        );

        setState(() {
          _selectedPosition = newPosition;
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newPosition, 16),
        );

        _getAddressFromLatLng(newPosition);
      } else {
        EasyLoading.showError('ไม่พบสถานที่');
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('ไม่พบสถานที่');
    }
  }

  void _showSearchDialog() {
    _searchController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ค้นหาสถานที่',
          style: GoogleFonts.kanit(fontSize: 18),
        ),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          style: GoogleFonts.kanit(),
          decoration: InputDecoration(
            hintText: 'พิมพ์ชื่อสถานที่...',
            hintStyle: GoogleFonts.kanit(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            _searchPlace(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: GoogleFonts.kanit()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _searchPlace(_searchController.text);
            },
            child: Text('ค้นหา', style: GoogleFonts.kanit()),
          ),
        ],
      ),
    );
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _selectedPosition = position.target;
    });
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
            child: Icon(
              Icons.location_pin,
              size: 50,
              color: Colors.red,
            ),
          ),

          // Top bar with search
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
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
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [Color(0xFF21CCD4), Color(0xFF0663F7)],
                          begin: Alignment(-0.97, -0.24),
                          end: Alignment(0.97, 0.24),
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, _selectedPosition);
                        },
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
