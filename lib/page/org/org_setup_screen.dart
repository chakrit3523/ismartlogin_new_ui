import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class OrgSetupScreen extends StatefulWidget {
  final String orgName;
  final String orgId;
  final VoidCallback onComplete;

  const OrgSetupScreen({
    Key? key,
    required this.orgName,
    required this.orgId,
    required this.onComplete,
  }) : super(key: key);

  @override
  _OrgSetupScreenState createState() => _OrgSetupScreenState();
}

class _OrgSetupScreenState extends State<OrgSetupScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = LatLng(13.736717, 100.523186); // Default: Bangkok
  String _address = 'กำลังโหลดที่อยู่...';
  int _radius = 50; // Default radius in meters
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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
      });
      _getAddressFromLatLng(result);
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(result));
      }
    }
  }

  void _onNextPressed() {
    // TODO: Save location and radius to backend
    // For now, just call onComplete
    widget.onComplete();
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
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/other/bg_regis.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'ตั้งค่าการเข้าออกงาน',
                          style: GoogleFonts.kanit(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Card
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Organization Name Section
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ชื่อกลุ่มหรือองค์กร',
                                  style: GoogleFonts.kanit(
                                    fontSize: 16,
                                    color: Color(0xFF0663F7),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    widget.orgName,
                                    style: GoogleFonts.kanit(
                                      fontSize: 18,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Map Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ปักหมุดบนแผนที่สำหรับล็อกอินเข้าออกงาน',
                                  style: GoogleFonts.kanit(
                                    fontSize: 16,
                                    color: Color(0xFF0663F7),
                                  ),
                                ),
                                SizedBox(height: 12),
                                GestureDetector(
                                  onTap: _openFullMapPicker,
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: 180,
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
                                              : GoogleMap(
                                                  onMapCreated: (controller) {
                                                    _mapController = controller;
                                                  },
                                                  initialCameraPosition:
                                                      CameraPosition(
                                                    target: _currentPosition,
                                                    zoom: 16,
                                                  ),
                                                  onCameraMove: _onCameraMove,
                                                  onCameraIdle: _onCameraIdle,
                                                  zoomControlsEnabled: false,
                                                  mapToolbarEnabled: false,
                                                  myLocationButtonEnabled:
                                                      false,
                                                ),
                                        ),
                                      ),
                                      // Pin overlay
                                      Positioned.fill(
                                        child: Center(
                                          child: Icon(
                                            Icons.location_pin,
                                            size: 40,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                      // Edit button
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
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_location_alt,
                                                  size: 16, color: Colors.grey),
                                              SizedBox(width: 4),
                                              Text(
                                                'แก้ไขตำแหน่งในแผนที่',
                                                style: GoogleFonts.kanit(
                                                  fontSize: 12,
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
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          // Radius Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Text(
                                  'รัศมีในการล็อกอิน',
                                  style: GoogleFonts.kanit(
                                    fontSize: 16,
                                    color: Color(0xFF0663F7),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Container(
                                  width: 80,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: TextField(
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.kanit(fontSize: 16),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      controller: TextEditingController(
                                          text: _radius.toString()),
                                      onChanged: (value) {
                                        setState(() {
                                          _radius = int.tryParse(value) ?? 50;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'เมตร',
                                  style: GoogleFonts.kanit(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),

                // Next Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [Color(0xFF21CCD4), Color(0xFF0663F7)],
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

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _getAddressFromLatLng(_selectedPosition);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
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
            onMapCreated: (controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 16,
            ),
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
                      child: Text(
                        widget.orgName,
                        style: GoogleFonts.kanit(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.search, color: Color(0xFF0663F7)),
                      onPressed: () {
                        // TODO: Implement search
                      },
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
