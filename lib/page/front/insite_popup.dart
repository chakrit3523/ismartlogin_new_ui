import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ismart_login/page/front/future/attend_future.dart';

import 'package:ismart_login/page/main.dart';
import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/utils/image_helper.dart';
import 'package:ismart_login/utils/dialog_helper.dart';

Completer<GoogleMapController> _controller = Completer();
final currentTime = DateTime.now();

class InsiteDialog extends StatefulWidget {
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
  final String ot_note;
  final String time_server;
  InsiteDialog({
    required this.uid,
    required this.pathImage,
    required this.lat,
    required this.long,
    required this.time,
    required this.myLat,
    required this.myLng,
    required this.radius,
    required this.timeId,
    required this.holiday,
    required this.ot_note,
    required this.time_server,
    super.key,
  });
  @override
  _InsiteDialogState createState() => _InsiteDialogState();
}

class _InsiteDialogState extends State<InsiteDialog> {
  double myLat = 0.0;
  double myLong = 0.0;
  double setLat = 0.0;
  double setLong = 0.0;
  double totalDistance = 0;
  List sortTimeOthers = [
    'สาย',
    'ลาไม่เต็มวัน',
    'ลืมลงชื่อเข้างาน',
    'ทำงานนอกสถานที่'
  ];
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
    print('holiday final : ${widget.holiday}');
  }

  @override
  void dispose() {
    super.dispose();
  }

  distanc() {
    setState(() {
      totalDistance = Geolocator.distanceBetween(double.parse(widget.lat),
          double.parse(widget.long), widget.myLat, widget.myLng);
    });
    print('คุณอยู่ห่างจากองค์กร ' + totalDistance.toString() + ' เมตร');
    if (totalDistance <= widget.radius) {
      return true;
    } else {
      return false;
    }
  }

// --- Time

  checkTimr(String time) {
    print(time);
    if (time == "") {
      return true;
    }
    var now = new DateTime.now();
    print("checkTimr time : " + time);
    DateTime timeInsite = DateFormat("HH:mm:ss").parse(time);
    DateTime combinedTime = DateTime(
      1970,
      01,
      01,
      timeInsite.hour,
      timeInsite.minute,
      now.second,
    );
    String insiteNow = DateFormat("HH:mm:ss").format(now);
    DateTime timeNow = DateFormat("HH:mm:ss").parse(insiteNow);
    if (timeNow.isBefore(combinedTime) || timeNow == combinedTime) {
      return true;
    } else {
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
  /// ---- Server - Synchronous Upload Flow ---
  //---
  /// ---- Server - Synchronous Upload Flow ---
  Future<bool> processCheckIn(Map map) async {
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

      // Step 2: Generate uploadKey
      final uploadKey =
          DateTime.now().millisecondsSinceEpoch.toString() + '_' + widget.uid;

      // Step 3: Upload image first
      final uploadResult = await AttandFuture().uploadAttend(
        context: context,
        file: compressedFile,
        cmd: 'attend',
        uid: widget.uid,
        uploadKey: uploadKey,
        attact_type: 'i_start',
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (!uploadResult['success']) {
        throw Exception(uploadResult['error'] ?? 'Upload failed');
      }

      setState(() {
        _uploadStatus = 'กำลังบันทึกข้อมูล...';
      });

      // Step 4: Save attendance data with uploadKey
      map['uploadKey'] = uploadKey;
      final response = await AttandFuture().apiPostAttandStart(map);

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
      DialogHelper.showError(context, 'เกิดข้อผิดพลาด', e.toString());
      return false;
    }
  }

  // Offsite Reason Variables
  int currentOffsiteIndex = -1;
  TextEditingController _offsiteNote = TextEditingController();

  @override
  Widget build(BuildContext context) {
    bool isLate = !checkTimr(widget.time) && !checkHoliday(widget.holiday);
    bool isOffsite = !distanc();

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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                                BitmapDescriptor.hueGreen),
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

              // 2. Info Header (Time & Location) - Green for Check-in
              Container(
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                color: Color(0xFF4CAF50), // Green for check-in
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
                    // Status badge
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        'เข้างาน',
                        style: TextStyle(
                          fontFamily: FontStyles().FontFamily,
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Warning & Reason Section
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Late Warning
                    if (isLate) ...[
                      Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_rounded,
                                color: Colors.red, size: 30),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'คุณเข้างานสาย กรุณาระบุเหตุผล',
                                style: TextStyle(
                                  fontFamily: FontStyles().FontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15),
                    ],

                    // Offsite Warning
                    if (isOffsite) ...[
                      Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_off,
                                color: Colors.orange, size: 30),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'คุณไม่ได้อยู่ในพื้นที่',
                                style: TextStyle(
                                  fontFamily: FontStyles().FontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15),
                    ],

                    // Reason Input (Late)
                    if (isLate) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "เหตุผลการเข้าสาย",
                          style: TextStyle(
                              fontFamily: FontStyles().FontFamily,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.start,
                        children: [
                          _buildReasonChip('สาย', 0, false),
                          _buildReasonChip('ลาไม่เต็มวัน', 1, false),
                          _buildReasonChip('ลืมลงชื่อ', 2, false),
                          _buildReasonChip('นอกสถานที่', 3, false),
                        ],
                      ),
                      SizedBox(height: 15),
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
                            hintText: 'ระบุเหตุผลเข้าสาย (ถ้ามี)',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 15),
                            suffixIcon: Icon(Icons.edit, color: Colors.grey),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],

                    // Offsite Warning & Input (Aligned with OffsideDialog)
                    if (isOffsite) ...[
                      // Warning Header (Simple Row like OffsideDialog)
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

                      // Input Field (Top)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextFormField(
                          controller: _offsiteNote,
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

                      // Chips (Bottom)
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildReasonChip('WFH (ทำงานที่บ้าน)', 0, true),
                          _buildReasonChip('ทำงานนอกสถานที่', 1, true),
                          _buildReasonChip('ระบุตำแหน่งผิดพลาด', 2, true),
                          _buildReasonChip('อื่น ๆ', 3, true),
                        ],
                      ),
                      SizedBox(height: 30),
                    ],

                    // Submit Button
                    GestureDetector(
                      onTap:
                          _isUploading ? null : () => _submitCheckIn(isOffsite),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: _isUploading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      _uploadStatus +
                                          (_uploadProgress > 0
                                              ? ' ${(_uploadProgress * 100).toStringAsFixed(0)}%'
                                              : ''),
                                      style: TextStyle(
                                        fontFamily: FontStyles().FontFamily,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'ลงเวลาเข้างาน',
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
      ),
    );
  }

  Widget _buildReasonChip(String label, int index, bool isOffsiteGroup) {
    bool isSelected =
        isOffsiteGroup ? currentOffsiteIndex == index : currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isOffsiteGroup) {
            currentOffsiteIndex = index;
            // Auto fill suggest text
            if (index == 0) _offsiteNote.text = "WFH (ทำงานที่บ้าน)";
            if (index == 1) _offsiteNote.text = "ทำงานนอกสถานที่";
            if (index == 2) _offsiteNote.text = "ระบุตำแหน่งผิดพลาด";
            if (index == 3) _offsiteNote.text = "";
          } else {
            currentIndex = index;
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFE8F5E9) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFF4CAF50) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: FontStyles().FontFamily,
            color: isSelected ? Color(0xFF2E7D32) : Colors.black54,
          ),
        ),
      ),
    );
  }

  void _submitCheckIn(bool isOffsite) async {
    // Validate if offsite
    if (isOffsite && currentOffsiteIndex == -1 && _offsiteNote.text.isEmpty) {
      DialogHelper.showError(
          context, "กรุณาระบุ", "กรุณาระบุเหตุผลที่อยู่นอกพื้นที่");
      return;
    }

    Map _map = {
      "uid": widget.uid,
      "time": widget.time_server.toString(),
      "image": widget.pathImage,
      "latitude": widget.myLat.toString(),
      "longitude": widget.myLng.toString(),
      "start_status": checkHoliday(widget.holiday)
          ? '5'
          : checkTimr(widget.time)
              ? '0'
              : (currentIndex + 1),
      "start_note":
          checkHoliday(widget.holiday) ? widget.ot_note : _inputNote.text,
      "start_location_status": distanc() ? '0' : '1',
      "log": 'timeid_${widget.timeId}',
    };
    print("CHECK-IN DATA: " + _map.toString());

    // Synchronous upload flow
    final success = await processCheckIn(_map);

    if (!success) {
      return;
    }

    // If Offsite, update location note immediately (chaining)
    if (isOffsite) {
      try {
        setState(() {
          _uploadStatus = 'กำหลังอัพเดทข้อมูลตำแหน่ง...';
        });
        List<String> selectedReasons = [];
        if (currentOffsiteIndex != -1) {
          selectedReasons.add(currentOffsiteIndex.toString());
        }

        Map _mapOffsite = {
          "status": "1", // 1 = Check In
          "uid": widget.uid,
          "start_location_note": json.encode(selectedReasons),
          "start_location_sub_status": _offsiteNote.text,
        };

        await AttandFuture().apiUpdateAttandStart(_mapOffsite);
      } catch (e) {
        print("Offsite update error: $e");
        // We don't block success here, just log it, or maybe show toast
      }
    }

    // Success Navigation
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainPage()),
    );
  }
}
