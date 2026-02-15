// ignore_for_file: unused_field, unused_local_variable

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ismart_login/src/app/pages/main_page.dart';
import 'package:ismart_login/src/features/front/presentation/pages/future/attend_future.dart';
import 'package:ismart_login/utils/image_helper.dart';
import 'package:ismart_login/utils/dialog_helper.dart';

import 'package:ismart_login/src/features/outside/presentation/pages/future/attend_outside_future.dart';
import 'package:ismart_login/src/features/outside/presentation/pages/model/attendOutsideStart.dart';

class OutsideScreen extends StatefulWidget {
  final double lat;
  final double long;
  final String uid;
  final bool isOvertime;
  final String timeId;

  const OutsideScreen({
    super.key,
    required this.lat,
    required this.long,
    required this.uid,
    this.isOvertime = false,
    this.timeId = '',
  });

  @override
  _OutsideScreenState createState() => _OutsideScreenState();
}

class _OutsideScreenState extends State<OutsideScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _inputTopic = TextEditingController();
  TextEditingController _inputTime = TextEditingController();
  TextEditingController _inputDescription = TextEditingController();
  //Setup
  XFile? _imageFile_login;
  dynamic _pickImageError;

  var timeNow = DateTime.now();
  //-----
  bool _login = false;
  bool _logout = false;
  //-----
  ////---- MAP
  Completer<GoogleMapController> _controller = Completer();
  late BitmapDescriptor pinLocationIcon;

  @override
  void initState() {
    super.initState();
  }

  //-----
  mapMark() {
    print(widget.lat);
    print(widget.long);
    CameraPosition _kGooglePlex = CameraPosition(
      target: LatLng(widget.lat, widget.long),
      zoom: 18,
    );
    return _kGooglePlex;
  }

  addMarker(context) {
    Set<Marker> markers = {};
    markers.add(Marker(
      markerId: MarkerId('Marker_user'),
      position: LatLng(widget.lat, widget.long),
      infoWindow: InfoWindow(title: 'ตำแหน่งคุณ'),
      icon: BitmapDescriptor.defaultMarkerWithHue(200),
    ));
    return markers;
  }

  //---
  //---
  /// ---- Server - OT Flow (Upload -> Post) ---
  Future<bool> processOvertimeCheckIn() async {
    if (_imageFile_login == null) {
      DialogHelper.showError(context, 'เกิดข้อผิดพลาด', 'กรุณาถ่ายรูป');
      return false;
    }

    try {
      AwesomeDialog loadingDialog =
          DialogHelper.showLoading(context, 'กำลังประมวลผล...');

      // 1. Prepare Note
      String noteStr = _inputTopic.text;
      if (_inputDescription.text.isNotEmpty) {
        noteStr += "\nรายละเอียด: ${_inputDescription.text}";
      }

      // 2. Generate Upload Key
      final uploadKey =
          DateTime.now().millisecondsSinceEpoch.toString() + '_' + widget.uid;

      // 3. Compress Image
      File originalFile = File(_imageFile_login!.path);
      File compressedFile = await ImageHelper.compressImage(originalFile);

      // 4. Upload Image (AttandFuture refactored to accept context, but we use it here inside loading dialog)
      // Since AttandFuture might show its own loading or we want to avoid double loading,
      // let's check AttandFuture.uploadAttend. It shows loading.
      // So we should dismiss our loading first? Or rely on AttandFuture's loading?
      // AttandFuture uses a loading dialog if no progress callback.

      loadingDialog.dismiss(); // Dismiss initial "Processing"

      final uploadResult = await AttandFuture().uploadAttend(
        context: context,
        file: compressedFile,
        cmd: 'attend',
        uid: widget.uid,
        uploadKey: uploadKey,
        attact_type: 'i_start',
      );

      if (uploadResult['success'] != true) {
        // allow checking bool or map
        throw Exception(uploadResult['error'] ?? 'Upload failed');
      }

      AwesomeDialog savingDialog =
          DialogHelper.showLoading(context, 'กำลังบันทึกข้อมูล...');

      // 5. Post Attendance Data
      Map map = {
        "uid": widget.uid,
        "time": DateFormat("HH:mm:ss")
            .format(DateTime.now()), // Server expect time?
        "image": _imageFile_login!.path, // path only
        "latitude": widget.lat.toString(),
        "longitude": widget.long.toString(),
        "start_status": '5', // OT Status
        "start_note": noteStr,
        "start_location_status": '1', // Outside
        "log": 'timeid_${widget.timeId}',
        "uploadKey": uploadKey,
      };

      print("OT CHECK-IN DATA: $map");

      final response = await AttandFuture().apiPostAttandStart(map);

      savingDialog.dismiss();

      if (response.isNotEmpty && response[0].STATUS == 'success') {
        DialogHelper.showSuccess(context, 'บันทึกสำเร็จ');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
        return true;
      } else {
        throw Exception(
            response.isNotEmpty ? response[0].MSG : 'Failed to save data');
      }
    } catch (e) {
      DialogHelper.showError(context, 'เกิดข้อผิดพลาด', e.toString());
      return false;
    }
  }

  /// ---- Server - Normal Outside Flow (Post -> Upload) ---
  List<ItemsAttandOutsideStartResult> _resultAttandStart = [];
  Future<bool> onLoadAttandOutside() async {
    // If OT mode, redirect to OT flow
    if (widget.isOvertime) {
      return await processOvertimeCheckIn();
    }

    // Normal Flow
    String dateNow = DateFormat("HH:mm:ss").format(timeNow);
    List note = [
      {
        "topic": _inputTopic.text,
        "description": _inputDescription.text,
        "times": _inputTime.text
      }
    ];
    Map map = {
      "uid": widget.uid,
      "cid": '3',
      "latitude": widget.lat.toString(),
      "longitude": widget.long.toString(),
      "time": dateNow,
      "start_note": json.encode(note),
    };
    print(map);

    try {
      AwesomeDialog loadingDialog =
          DialogHelper.showLoading(context, 'กำลังบันทึก...');
      await AttandOutsideFuture()
          .apiPostAttandOutsideStart(map)
          .then((onValue) {
        loadingDialog.dismiss();

        if (onValue[0].STATUS == 'success') {
          _resultAttandStart = onValue;
          if (_imageFile_login != null) {
            onUploadFiles('i_start'); // This will show its own loading
          }
          // Dismiss after successful post/upload init
          // onUploadFiles handles its own loading? Checked source: yes it uses EasyLoading (now DialogHelper).

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MainPage(),
            ),
          );
        } else {
          DialogHelper.showError(context, 'เกิดข้อผิดพลาด', 'ล้มเหลว');
        }
      });
    } catch (e) {
      // Ensure loading is dismissed if still active (though we dismissed it inside .then, need careful handling if async error)
      // Actually we should await properly.
      DialogHelper.showError(context, 'Error', e.toString());
    }
    return true;
  }

  Future<dynamic> onUploadFiles(String statusFile) async {
    if (_imageFile_login != null) {
      await AttandOutsideFuture().uploadAttendOutside(
        context: context,
        file: File(_imageFile_login!.path),
        cmd: 'attend',
        uid: widget.uid,
        uploadKey: _resultAttandStart[0].UPLOADKEY,
        attact_type: statusFile,
      );
    }
    return true;
  }

  ///-----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF21CCD4), Color(0xFF0663F7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.isOvertime
                              ? 'ทำงานล่วงเวลา'
                              : 'ทำงานนอกสถานที่',
                          style: GoogleFonts.kanit(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 48), // Balance back button
                  ],
                ),
              ),

              // 2. White Curved Body
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location Header
                          Center(
                            child: Text(
                              'ตำแหน่งที่คุณล็อกอิน',
                              style: GoogleFonts.kanit(
                                fontSize: 18,
                                color: Color(0xFF089AE5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 15),

                          // Google Map Container
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: GoogleMap(
                                mapType: MapType.normal,
                                markers: addMarker(context),
                                myLocationEnabled: true,
                                initialCameraPosition: mapMark(),
                                onMapCreated: (GoogleMapController controller) {
                                  _controller.complete(controller);
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 25),

                          // Form Fields
                          _buildModernTextField(
                            controller: _inputTopic,
                            hint: 'เรื่อง',
                            icon: Icons.topic_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกข้อมูล';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 15),
                          _buildModernTextField(
                            controller: _inputDescription,
                            hint: 'รายละเอียด',
                            icon: Icons.description_outlined,
                            maxLines: 3,
                          ),
                          SizedBox(height: 15),
                          _buildModernTextField(
                            controller: _inputTime,
                            hint: 'ใช้เวลากี่ชั่วโมง',
                            icon: Icons.timer_outlined,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                          ),
                          SizedBox(height: 25),

                          // Camera Section
                          GestureDetector(
                            onTap: () {
                              _imgFromCamera_in(context);
                            },
                            child: Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.grey[300]!, width: 2),
                              ),
                              child: _imageFile_login != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.file(
                                        File(_imageFile_login!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.camera_alt,
                                            size: 40, color: Colors.grey),
                                        SizedBox(height: 10),
                                        Text(
                                          'ถ่ายรูป',
                                          style: GoogleFonts.kanit(
                                            fontSize: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          SizedBox(height: 30),

                          // Submit Button
                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF21CCD4), Color(0xFF0663F7)],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Color(0xFF0663F7).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                )
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    onLoadAttandOutside();
                                  }
                                },
                                borderRadius: BorderRadius.circular(30),
                                child: Center(
                                  child: Text(
                                    'ตกลง',
                                    style: GoogleFonts.kanit(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.kanit(fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.kanit(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: Color(0xFF21CCD4)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        validator: validator,
      ),
    );
  }

  _imgFromCamera_in(BuildContext context) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
        preferredCameraDevice: CameraDevice.front,
      );
      blocSetState(() {
        _imageFile_login = pickedFile;
      });
    } catch (e) {
      blocSetState(() {
        _pickImageError = e;
      });
    }
  }
}
