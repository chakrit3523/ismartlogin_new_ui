import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ismart_login/page/front/future/attend_future.dart';
import 'package:ismart_login/page/front/model/attendEnd.dart';
import 'package:ismart_login/page/front/model/attendStart.dart';
import 'package:ismart_login/page/front/outside_popup.dart';
import 'package:ismart_login/page/main.dart';
import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/system/clock.dart';
import 'package:ismart_login/system/widht_device.dart';
import 'package:ismart_login/utils/image_helper.dart';

Completer<GoogleMapController> _controller = Completer();
final currentTime = DateTime.now();

class OffsideDialog extends StatefulWidget {
  final String uid;
  final String timeId;
  final String pathImage;
  final String lat;
  final String long;
  final String time;
  final double myLat;
  final double myLng;
  final double radius;
  final bool holiday;
  final String time_server;
  const OffsideDialog({
    super.key,
    required this.uid,
    required this.pathImage,
    required this.lat,
    required this.long,
    required this.time,
    required this.myLat,
    required this.myLng,
    required this.holiday,
    required this.radius,
    required this.timeId,
    required this.time_server,
  });
  @override
  _OffsideDialogState createState() => _OffsideDialogState();
}

class _OffsideDialogState extends State<OffsideDialog> {
  double myLat = 0.0;
  double myLong = 0.0;
  double setLat = 0.0;
  double setLong = 0.0;
  double totalDistance = 0;
  List sortTimeOthers = ['ลาไม่เต็มวัน', 'ทำงานนอกสถานที่'];
  int currentIndex = 0;
  TextEditingController _inputNote = TextEditingController();

  // Loading states
  bool _isUploading = false;
  String _uploadStatus = '';
  double _uploadProgress = 0.0;
  //----
  @override
  void initState() {
    super.initState();
    setLat = double.parse(widget.lat);
    setLong = double.parse(widget.long);
    (widget.holiday == true)
        ? print("holiday, ${widget.holiday}")
        : print("NOT holiday, ${widget.holiday}");
    print(widget.time);
  }

  @override
  void dispose() {
    super.dispose();
  }

  distanc() {
    setState(() {
      totalDistance = Geolocator.distanceBetween(
          setLat, setLong, widget.myLat, widget.myLng);
    });

    if (totalDistance <= widget.radius) {
      return true;
    } else {
      return false;
    }
  }

// --- Time

  checkTimr(String time) {
    print(time);
    if (time == null || time == "") {
      return true;
    }
    var now = new DateTime.now();
    // var insite = DateFormat("HH:mm").format(DateTime.parse(time + ':00'));
    DateTime timeInsite = DateFormat("HH:mm").parse(time);
    String insiteNow = DateFormat("HH:mm").format(now);
    DateTime timeNow = DateFormat("HH:mm").parse(insiteNow);
    if (timeNow.isAfter(timeInsite)) {
      return true;
    } else {
      return false;
    }
  }

  //---
  /// ---- Server - Synchronous Upload Flow ---
  Future<bool> processCheckOut(Map map) async {
    try {
      setState(() {
        _isUploading = true;
        _uploadStatus = 'กำลังบีบอัดรูปภาพ...';
        _uploadProgress = 0.0;
      });

      // Step 1: Compress image
      final originalFile = File(widget.pathImage);
      final compressedFile = await ImageHelper.compressImage(originalFile);

      setState(() {
        _uploadStatus = 'กำลังอัพโหลดรูปภาพ...';
      });

      // Step 2: Upload image using V2 API (server gets uploadKey from today's record)
      final uploadResult = await AttandFuture().uploadImageV2(
        file: compressedFile,
        uid: widget.uid,
        attactType: 'i_end', // checkout
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (!uploadResult['success']) {
        throw Exception(uploadResult['error'] ?? 'Upload failed');
      }

      // Get uploadKey from server response (same as check-in)
      final uploadKey = uploadResult['uploadKey'];

      setState(() {
        _uploadStatus = 'กำลังบันทึกข้อมูล...';
      });

      // Step 3: Save attendance data with uploadKey from server
      map['uploadKey'] = uploadKey;
      final response = await AttandFuture().apiPostAttendEnd(map);

      if (response[0].STATUS == 'success') {
        setState(() {
          _uploadStatus = 'บันทึกสำเร็จ';
        });
        return true;
      } else {
        throw Exception(response[0].MSG ?? 'Failed to save attendance data');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadStatus = 'เกิดข้อผิดพลาด: ${e.toString()}';
      });
      EasyLoading.showError('เกิดข้อผิดพลาด: ${e.toString()}');
      return false;
    }
  }

  checkHoliday(bool holiday) {
    print(holiday);
    if (holiday == true) {
      return true;
    } else {
      return false;
    }
  }
  //---

  @override
  Widget build(BuildContext context) {
    bool isOffside = !distanc(); // Check if offside

    return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Map & Photo Header
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Stack(
                    children: [
                      // Map
                      ClipRRect(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(widget.myLat, widget.myLng),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId('curr_loc'),
                              position: LatLng(widget.myLat, widget.myLng),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueOrange),
                            )
                          },
                          myLocationEnabled: false,
                          zoomControlsEnabled: false,
                        ),
                      ),
                      // Photo Overlay
                      Positioned(
                        bottom: 0,
                        left: 20,
                        child: Container(
                          width: 100,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(15)),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4)
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(12)),
                            child: Image.file(
                              File(widget.pathImage),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      // Close Button
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Info Header (Time & Location)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  color: Color(0xFF0099CC),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_filled, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            widget.time_server,
                            style: TextStyle(
                              fontFamily: FontStyles().FontFamily,
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Location Name Placeholder (In real app, reverse geocode)
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'ตำแหน่งของคุณ', // Placeholder
                            style: TextStyle(
                              fontFamily: FontStyles().FontFamily,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                // 3. Warning & Reason
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Warning Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_rounded,
                              color: Colors.redAccent, size: 30),
                          SizedBox(width: 10),
                          Text(
                            'เหตุผลที่คุณอยู่นอกพื้นที่',
                            style: TextStyle(
                              fontFamily: FontStyles().FontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Input Field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextFormField(
                          controller: _inputNote,
                          style: TextStyle(
                              fontFamily: FontStyles().FontFamily,
                              fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'กรุณาระบุเหตุผล',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 15),
                            suffixIcon: Icon(Icons.edit, color: Colors.grey),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Quick Reason Chips
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildReasonChip('ทำงานที่บ้าน', 0),
                          _buildReasonChip('พบลูกค้า', 1),
                          _buildReasonChip('ตำแหน่งผิดพลาด', 2),
                        ],
                      ),
                      SizedBox(height: 30),

                      // Submit Button
                      GestureDetector(
                        onTap: _isUploading ? null : _submitOffsideForm,
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF21CCD4), Color(0xFF0663F7)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: _isUploading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    'ลงเวลา',
                                    style: TextStyle(
                                      fontFamily: FontStyles().FontFamily,
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildReasonChip(String label, int index) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          currentIndex = index;
          _inputNote.text = label; // Auto-fill text
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFE0F7FA) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFF21CCD4) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: FontStyles().FontFamily,
            color: isSelected ? Color(0xFF0099CC) : Colors.black54,
          ),
        ),
      ),
    );
  }

  void _submitOffsideForm() async {
    Map _map = {
      "uid": widget.uid,
      "time": widget.time_server.toString(),
      "image": widget.pathImage,
      "latitude": widget.myLat.toString(),
      "longitude": widget.myLng.toString(),
      "end_status": (currentIndex + 1)
          .toString(), // +1 to match old logic (1-based index?)
      "end_note": _inputNote.text,
      "log": 'timeid_${widget.timeId}',
    };
    print("OFFSIDE SUBMIT: " + _map.toString());

    final success = await processCheckOut(_map);

    if (success) {
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage()),
      );
    }
  }
}
