// ignore_for_file: unused_field

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_switch/flutter_switch.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:ismart_login/page/managements/future/org_manage_future.dart';
import 'package:ismart_login/page/managements/model/itemOrgManage.dart';
import 'package:ismart_login/page/managements/org_screen.dart';
import 'package:ismart_login/page/org/future/getJoinOrg_future.dart';
import 'package:ismart_login/page/org/model/itemSwitchOrg.dart';
import 'package:ismart_login/page/org/org_setup_screen.dart';
import 'package:ismart_login/page/splashscreen/splashscreen_screen.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/style/font_style.dart';

import 'package:ismart_login/system/shared_preferences.dart';
import 'package:ismart_login/system/widht_device.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:share/share.dart';

Completer<GoogleMapController> _controller = Completer();

class OrganizationCreateScreen extends StatefulWidget {
  final String type;
  final String title;
  final String id;
  final String invite;
  final String history;
  final String noti;
  final String logout;
  final String ot;
  final String time_status;
  final bool action;
  final String leave_cancel_status;
  final Function refresh;
  OrganizationCreateScreen({
    required this.type,
    required this.title,
    required this.id,
    required this.invite,
    required this.action,
    required this.history,
    required this.noti,
    required this.refresh,
    required this.logout,
    required this.ot,
    required this.time_status,
    required this.leave_cancel_status,
    super.key,
  });
  _OrganizationCreateScreenState createState() =>
      _OrganizationCreateScreenState();
}

class _OrganizationCreateScreenState extends State<OrganizationCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  GlobalKey globalKey = new GlobalKey();
  String _presetOrgId = "";
  // FToast fToast;
  bool _switchHistory = true;
  bool _switchNoti = true;
  bool _switchOT = true;
  bool _switchLogout = true;
  bool _switchSwapTime = true;
  bool _switchCancelLeave = false;
  TimeOfDay _timeOfDay = TimeOfDay.now();
  //
  TextEditingController _inputSubject = TextEditingController();
  FocusNode _focusSubject = FocusNode();
//-----
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _requestPermission();
    print(widget.id);
    print(widget.history);
    // fToast = FToast();
    // fToast.init(context);
    if (widget.type == 'update') {
      _inputSubject.text = widget.title;
    }
    if (widget.history == "0") {
      _switchHistory = false;
    } else {
      _switchHistory = true;
    }

    //noti
    if (widget.noti == "0") {
      _switchNoti = false;
    } else {
      _switchNoti = true;
    }

    //ot
    if (widget.ot == "0") {
      _switchOT = false;
    } else {
      _switchOT = true;
    }

    //logout
    if (widget.logout == "0") {
      _switchLogout = false;
    } else {
      _switchLogout = true;
    }

    //time status
    if (widget.time_status == "0") {
      _switchSwapTime = true;
    } else {
      _switchSwapTime = false;
    }

    //leave cancel status
    if (widget.leave_cancel_status == "0") {
      _switchCancelLeave = false;
    } else {
      _switchCancelLeave = true;
    }
  }

  _releaseData() async {
    String _subject = _inputSubject.text;
    Map _map = {
      "subject": _subject,
      "type": widget.type == "insert" ? widget.type : "update",
      "id": widget.type == "insert" ? "0" : widget.id,
      "uid": await SharedCashe.getItemsWay(name: 'id'),
    };
    print(_map);
    onLoadPostUpdateOrg(_map);
  }

  _releaseDataWithLocation(
      double lat, double lng, String address, int radius) async {
    String _subject = _inputSubject.text;
    Map _map = {
      "subject": _subject,
      "type": "insert",
      "id": "0",
      "uid": await SharedCashe.getItemsWay(name: 'id'),
      "lat": lat.toString(),
      "lng": lng.toString(),
      "address": address,
      "radius": radius.toString(),
    };
    print("Creating org with location: $_map");
    alert(context, "กำลังสร้างทีม/องค์กร");
    onLoadPostUpdateOrg(_map);
  }

  _updateHistoryStatus(String status, String id) async {
    Map _map = {};
    _map.addAll({
      "id": id,
      "history_status": status,
    });
    print("_map : $_map");
    var body = json.encode(_map);
    final response = await http.Client().post(
      Uri.parse(Server().updateHistoryStatus),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    var data = json.decode(response.body);
    print('insertSeq : $data');
  }

  _updateNotiStatus(String status, String id) async {
    Map _map = {};
    _map.addAll({
      "id": id,
      "noti_status": status,
    });
    print("_map : $_map");
    var body = json.encode(_map);
    final response = await http.Client().post(
      Uri.parse(Server().updateNotiStatus),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    var data = json.decode(response.body);
    print('insertSeq : $data');
  }

  _updateOTStatus(String status, String id) async {
    Map _map = {};
    _map.addAll({
      "id": id,
      "ot_status": status,
    });
    print("_map : $_map");
    var body = json.encode(_map);
    final response = await http.Client().post(
      Uri.parse(Server().updateOTStatus),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    var data = json.decode(response.body);
    print('insertSeq : $data');
  }

  _updateLogoutStatus(String status, String id) async {
    Map _map = {};
    _map.addAll({
      "id": id,
      "logout_status": status,
    });
    print("_map : $_map");
    var body = json.encode(_map);
    final response = await http.Client().post(
      Uri.parse(Server().updateLogoutStatus),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    var data = json.decode(response.body);
    print('insertSeq : $data');
  }

  _updateTimeStatus(String status, String id) async {
    Map _map = {};
    _map.addAll({
      "id": id,
      "time_status": status,
    });
    print("_map : $_map");
    var body = json.encode(_map);
    final response = await http.Client().post(
      Uri.parse(Server().updateTimeStatus),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    var data = json.decode(response.body);
    print('insertSeq : $data');
  }

  _updateLeaveCancelStatus(String status, String id) async {
    Map _map = {};
    _map.addAll({
      "id": id,
      "cancel_status": status,
    });
    print("_map : $_map");
    var body = json.encode(_map);
    final response = await http.Client().post(
      Uri.parse(Server().updateLeaveCancelStatus),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    var data = json.decode(response.body);
    print('insertSeq : $data');
  }

  //---
  List<ItemsOrgPostManage> _resultOrgPost = [];
  Future<bool> onLoadPostUpdateOrg(Map map) async {
    await OrgManageFuture().apiPostOrgManageList(map).then((onValue) async {
      if (onValue[0].STATUS == true) {
        if (widget.type == "update") {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrgManageScreen(),
            ),
          );
        } else {
          print("add org success");
          EasyLoading.showSuccess('สร้างทีม/องค์กรเรียบร้อยแล้ว');

          // Fetch the new org details to get the Invite Code
          String? newOrgId = onValue[0].ID;
          if (newOrgId != null && newOrgId.isNotEmpty) {
            try {
              var publicOrg =
                  await OrgManageFuture().apiGetPublicOrg({"ID": newOrgId});
              if (publicOrg.isNotEmpty) {
                String newInviteCode = publicOrg[0].INVITE;
                String newSubject = publicOrg[0].SUBJECT;
                // Dismiss loading before showing dialog
                // Wait a bit for the success message to be visible
                Future.delayed(Duration(milliseconds: 1000), () {
                  _showInviteSuccessDialog(newInviteCode, newSubject, newOrgId);
                });
                return true; // Stop here, don't pop yet
              }
            } catch (e) {
              print("Failed to fetch new org details: $e");
            }
          }

          // Fallback if fetch fails or no ID
          Future.delayed(Duration(milliseconds: 200), () {
            _goToOrgManage();
          });
        }
      } else {
        setState(() {
          btn = true;
          alert(context, 'ล้มเหลว');
        });
      }
    });
    return true;
  }

  _goToOrgManage() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SplashscreenScreen(),
      ),
    );
  }

  ///-----
  List<ItemsSwitchOrg> _resultSwitch = [];
  Future<bool> onLoadUpdateSwitchOrg() async {
    var orgSubId = await SharedCashe.getItemsWay(name: 'org_sub_id');
    FirebaseMessaging.instance.unsubscribeFromTopic("org_" + orgSubId);

    Map map = {
      "uid": await SharedCashe.getItemsWay(name: 'id'),
      "org_id": widget.id,
    };
    await GetOrgFuture().apiUpdateSwitchOrgList(map).then((onValue) async {
      if (onValue[0].STATUS == "true") {
        FirebaseMessaging.instance
            .subscribeToTopic("org_" + widget.id.toString());

        EasyLoading.showSuccess('สลับแล้ว');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SplashscreenScreen(),
          ),
        );
      } else {
        EasyLoading.showError('ล้มเหลว');
      }
    });
    return true;
  }

  _requestPermission() async {
    Map<Permission, dynamic> statuses = await [
      Permission.storage,
    ].request();
    final info = statuses[Permission.storage].toString();
    print(info);
  }

  ///-----
  Future<void> _captureAndSharePng() async {
    try {
      final boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // เพิ่มความคมชัดตามที่ใช้เดิม
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        EasyLoading.showError("ไม่สามารถแปลงภาพได้");
        return;
      }

      final Uint8List bytes = byteData.buffer.asUint8List();

      // เรียกใช้แพ็กเกจใหม่ (เปลี่ยนชื่อคลาส)
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 80,
        name: "invitecode_${widget.id}",
      );

      // รองรับได้ทั้งกรณีที่คืนค่าเป็น Map ที่มีคีย์แตกต่างกันเล็กน้อย
      bool isSuccess = false;
      String? filePath;

      if (result is Map) {
        isSuccess = (result['isSuccess'] == true) ||
            (result['success'] == true) ||
            (result['status'] == 'success');
        filePath = (result['filePath'] ?? result['file_path'] ?? result['file'])
            as String?;
        // กันเคสที่ lib บางเวอร์ชันไม่ใส่ isSuccess แต่มี path
        isSuccess = isSuccess || (filePath != null && filePath.isNotEmpty);
      }

      if (isSuccess) {
        EasyLoading.showSuccess("บันทึกลง Gallery แล้ว");
        // debug:
        // print("Saved to: $filePath");
      } else {
        EasyLoading.showError("ล้มเหลว");
        // debug:
        // print("Save result: $result");
      }
    } catch (e) {
      // debug:
      // print("Error saving image: $e");
      EasyLoading.showError("เกิดข้อผิดพลาดในการบันทึก");
    }
  }
  // Future<void> _captureAndSharePng() async {
  //   try {
  //     RenderRepaintBoundary boundary =
  //         globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

  //     ui.Image image =
  //         await boundary.toImage(pixelRatio: 3.0); // เพิ่มความคมชัด
  //     ByteData? byteData =
  //         await image.toByteData(format: ui.ImageByteFormat.png);

  //     if (byteData != null) {
  //       final result = await ImageGallerySaver.saveImage(
  //         byteData.buffer.asUint8List(),
  //         quality: 80,
  //         name: "invitecode_${widget.id}",
  //       );

  //       print(result);

  //       if (result['filePath'] != null && result['filePath'] != "") {
  //         EasyLoading.showSuccess("บันทึกลง Gallery แล้ว");
  //       } else {
  //         EasyLoading.showError("ล้มเหลว");
  //       }
  //     } else {
  //       EasyLoading.showError("ไม่สามารถแปลงภาพได้");
  //     }
  //   } catch (e) {
  //     print("Error saving image: $e");
  //     EasyLoading.showError("เกิดข้อผิดพลาดในการบันทึก");
  //   }
  // }

  Future<void> _captureAndShareOtherPng() async {
    try {
      final boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        print("❌ byteData is null – ไม่สามารถแปลงภาพเป็น PNG ได้");
        return;
      }

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final filename = 'invitecode_${widget.id}.png';
      final file = await File('${tempDir.path}/$filename').create();
      await file.writeAsBytes(bytes);

      final text = '''
                  iSmartLogin ได้เชิญท่านเข้าร่วม ทีม/องค์กร "${widget.title}"

                  สแกน QR Code หรือกรอกรหัส ${widget.invite}

                  ** สำหรับสมาชิกที่ลงทะเบียนใหม่
                  ''';

      // ถ้าอยากให้พรีวิวไฟล์ถูกต้อง ใส่ mimeType และ name
      final xfile = XFile(file.path, name: filename, mimeType: 'image/png');

      // บน iPad จำเป็นต้องส่ง rect ตำแหน่งป๊อปโอเวอร์ (กันแครช)
      final box = globalKey.currentContext!.findRenderObject() as RenderBox;
      final origin = box.localToGlobal(Offset.zero) & box.size;

      await Share.shareXFiles(
        [xfile],
        text: text,
        subject: 'iSmartLogin Invitation',
        sharePositionOrigin: origin, // iPad safe
      );
    } catch (e) {
      print("❌ Error in _captureAndShareOtherPng: $e");
    }
  }

  ///-----

  var btn = true;

  @override
  Widget build(BuildContext context) {
    // Use new design for insert mode, keep old design for update mode
    if (widget.type == "insert") {
      return _buildInsertModeUI();
    }
    return _buildUpdateModeUI();
  }

  // New design for creating organization
  Widget _buildInsertModeUI() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        extendBodyBehindAppBar: true,
        extendBody: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              widget.refresh();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.3, -1.0),
              end: Alignment(0.3, 1.0),
              colors: [
                Color(0xFF21CCD4), // 0%
                Color(0xFF0663F7), // 100%
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Spacer(flex: 2),

                // Icon / Header Graphic (Optional addition for modern feel, keeping it simple for now)

                SizedBox(height: 10),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    "ตั้งชื่อกลุ่ม/องค์กร",
                    style: TextStyle(
                      fontFamily: FontStyles().FontFamily,
                      fontSize: 28, // Slightly larger
                      color: Colors.white,
                      fontWeight: FontWeight.w500, // Thicker font
                      shadows: [
                        Shadow(
                          color: Colors.black12,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        )
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 40),

                // Glassmorphism Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Form(
                    key: _formKey,
                    child: Container(
                      height: 60, // Taller touch target
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2), // Glass effect
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: TextFormField(
                          controller: _inputSubject,
                          focusNode: _focusSubject,
                          keyboardType: TextInputType.text,
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(
                            fontFamily: FontStyles().FontFamily,
                            fontSize: 24,
                            color: Colors.white, // White text
                          ),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            hintText: 'ชื่อกลุ่ม/องค์กร',
                            hintStyle: TextStyle(
                              fontFamily: FontStyles().FontFamily,
                              fontSize: 24,
                              color: Colors.white70, // Key change: White70 hint
                            ),
                            prefixIcon: Icon(
                              Icons.business,
                              color: Colors.white70,
                              size: 28,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 40), // More spacing

                // Action Button Glow
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60, // Taller button
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF0663F7)
                                .withOpacity(0.4), // Glow color
                            offset: Offset(0, 8),
                            blurRadius: 20,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_inputSubject.text == '') {
                            alert(context, 'กรุณาป้อนข้อมูลให้ครบถ้วน');
                          } else {
                            if (_formKey.currentState?.validate() ?? false) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrgSetupScreen(
                                    orgName: _inputSubject.text,
                                    onCreateOrg: (lat, lng, address, radius) {
                                      _releaseDataWithLocation(
                                          lat, lng, address, radius);
                                    },
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF0663F7),
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "สร้าง",
                          style: TextStyle(
                            fontFamily: FontStyles().FontFamily,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 60),
                Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Original design for updating organization
  Widget _buildUpdateModeUI() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.3, -1.0),
              end: Alignment(0.3, 1.0),
              colors: [
                Color(0xFF21CCD4),
                Color(0xFF0663F7),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // AppBar-like header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios,
                              color: Colors.white, size: 26),
                          onPressed: () {
                            widget.refresh();
                            Navigator.of(context).pop();
                          },
                        ),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              fontFamily: FontStyles().FontFamily,
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Input Section (White Card)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        // Removed border or made it very subtle
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: TextFormField(
                                controller: _inputSubject,
                                focusNode: _focusSubject,
                                keyboardType: TextInputType.text,
                                style: TextStyle(
                                  fontFamily: FontStyles().FontFamily,
                                  fontSize: 24,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'ชื่อทีม/องค์กร',
                                  hintStyle: TextStyle(
                                    fontFamily: FontStyles().FontFamily,
                                    fontSize: 24,
                                    color: Colors.grey,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.business,
                                    size: 26,
                                    color: Colors.grey,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 15),
                                ),
                              ),
                            ),
                            SizedBox(height: 15),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  if (_inputSubject.text == '') {
                                    alert(context, 'กรุณาป้อนข้อมูลให้ครบถ้วน');
                                  } else {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      _releaseData();
                                    }
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Color(0xFF0663F7).withOpacity(0.3),
                                        offset: Offset(0, 6),
                                        blurRadius: 15,
                                        spreadRadius: -3,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    "บันทึก",
                                    style: TextStyle(
                                      fontFamily: FontStyles().FontFamily,
                                      color: Color(0xFF0663F7),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
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

                  SizedBox(height: 15),

                  // Settings Toggle Section
                  if (widget.type == "update")
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            _buildToggleRow('ประวัติการเข้า/ออกงานของสมาชิก',
                                _switchHistory, (state) {
                              setState(() {
                                _switchHistory = state;
                                _updateHistoryStatus(
                                    state ? "1" : "0", widget.id);
                              });
                            }),
                            Divider(color: Colors.grey[200], height: 30),
                            _buildToggleRow(
                                'การแจ้งเตือนก่อนเข้างาน 5 นาที', _switchNoti,
                                (state) {
                              setState(() {
                                _switchNoti = state;
                                _updateNotiStatus(state ? "1" : "0", widget.id);
                              });
                            }),
                            Divider(color: Colors.grey[200], height: 30),
                            _buildToggleRow('ทำงานนอกเวลา (OT)', _switchOT,
                                (state) {
                              setState(() {
                                _switchOT = state;
                                _updateOTStatus(state ? "1" : "0", widget.id);
                              });
                            }),
                            Divider(color: Colors.grey[200], height: 30),
                            _buildToggleRow('ออกจากงานอัตโนมัติ', _switchLogout,
                                (state) {
                              setState(() {
                                _switchLogout = state;
                                _updateLogoutStatus(
                                    state ? "1" : "0", widget.id);
                              });
                            }),
                            Divider(color: Colors.grey[200], height: 30),
                            _buildToggleRow(
                                'สลับเวลาทำงานด้วยตนเอง', _switchSwapTime,
                                (state) {
                              setState(() {
                                _switchSwapTime = state;
                                _updateTimeStatus(state ? "0" : "1", widget.id);
                              });
                            }),
                            Divider(color: Colors.grey[200], height: 30),
                            _buildToggleRow(
                                'อนุมัติยกเลิกการลา', _switchCancelLeave,
                                (state) {
                              setState(() {
                                _switchCancelLeave = state;
                                _updateLeaveCancelStatus(
                                    state ? "1" : "0", widget.id);
                              });
                            }),

                            SizedBox(height: 20),

                            // Invite Code Section
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'รหัสทีม',
                                    style: TextStyle(
                                      fontFamily: FontStyles().FontFamily,
                                      fontSize: 22,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[100],
                                  ),
                                  child: Text(
                                    widget.invite.toString().substring(0, 3) +
                                        " " +
                                        widget.invite
                                            .toString()
                                            .substring(3, 6) +
                                        " " +
                                        widget.invite
                                            .toString()
                                            .substring(6, 9),
                                    style: TextStyle(
                                      fontFamily: FontStyles().FontFamily,
                                      fontSize: 24,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(
                                        ClipboardData(text: widget.invite));
                                    _showToast();
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(Icons.copy_sharp,
                                        color: Colors.grey, size: 28),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 25),

                            // QR Code
                            RepaintBoundary(
                              key: globalKey,
                              child: Container(
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        Border.all(color: Colors.grey[200]!)),
                                child: QrImageView(
                                  data: widget.invite,
                                  version: QrVersions.auto,
                                  size: 240.0,
                                  embeddedImage: AssetImage(
                                      'assets/images/other/logo_app.png'),
                                  embeddedImageStyle: QrEmbeddedImageStyle(
                                    size: Size(80, 80),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 20),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _captureAndSharePng,
                                    child: Container(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF0663F7)
                                                .withOpacity(0.3),
                                            offset: Offset(0, 6),
                                            blurRadius: 15,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.save,
                                              color: Color(0xFF0663F7)),
                                          SizedBox(width: 8),
                                          Text(
                                            "บันทึก",
                                            style: TextStyle(
                                              fontFamily:
                                                  FontStyles().FontFamily,
                                              color: Color(0xFF0663F7),
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 15),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _captureAndShareOtherPng,
                                    child: Container(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF0663F7)
                                                .withOpacity(0.3),
                                            offset: Offset(0, 6),
                                            blurRadius: 15,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.share,
                                              color: Color(0xFF0663F7)),
                                          SizedBox(width: 8),
                                          Text(
                                            "แบ่งปัน",
                                            style: TextStyle(
                                              fontFamily:
                                                  FontStyles().FontFamily,
                                              color: Color(0xFF0663F7),
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(height: 15),

                  // Switch Organization Button
                  if (widget.type == 'update' && !widget.action)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: () {
                          onLoadUpdateSwitchOrg();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(
                                FontAwesomeIcons.retweet,
                                color: Color(0xFF0663F7),
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'ใช้งานบน ทีม/องค์กร นี้',
                                style: TextStyle(
                                  fontFamily: FontStyles().FontFamily,
                                  fontSize: 24,
                                  color: Color(0xFF0663F7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, Function(bool) onToggle) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: FontStyles().FontFamily,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
        ),
        FlutterSwitch(
          value: value,
          width: 60.0,
          height: 30.0,
          toggleSize: 26.0,
          borderRadius: 20.0,
          padding: 2.0,
          activeColor: Color(0xFF4CAF50),
          inactiveColor: Colors.grey.shade400,
          onToggle: onToggle,
        ),
      ],
    );
  }

  _showToast() async {
    final snack = SnackBar(
      content: Row(
        children: [
          Icon(
            Icons.copy,
            color: Colors.white,
          ),
          SizedBox(
            width: 12.0,
          ),
          Text(
            'คัดลอกแล้ว',
            style: TextStyle(
                fontFamily: FontStyles().FontFamily,
                fontSize: 22,
                color: Colors.white),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.black,
      duration: Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  alert(BuildContext context, String text) async {
    return showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          contentPadding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
          content: Container(
            width: WidhtDevice().widht(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      EdgeInsets.only(top: 10, bottom: 10, left: 3, right: 3),
                  alignment: Alignment.center,
                  child: Text(
                    text,
                    style: TextStyle(
                        fontFamily: FontStyles().FontFamily,
                        fontSize: 24,
                        height: 1),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (btn)
                  Container(
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(20.0),
                                  bottomRight: Radius.circular(20.0),
                                ),
                              ),
                              height: 50,
                              alignment: Alignment.center,
                              child: Text(
                                'ปิด',
                                style: TextStyle(
                                    fontFamily: FontStyles().FontFamily,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold),
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
        );
      },
    );
  }

  alert_new_org(BuildContext context, String text) async {
    return showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          contentPadding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
          content: Container(
            width: WidhtDevice().widht(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      EdgeInsets.only(top: 10, bottom: 10, left: 3, right: 3),
                  alignment: Alignment.center,
                  child: Text(
                    text,
                    style: TextStyle(
                        fontFamily: FontStyles().FontFamily,
                        fontSize: 24,
                        height: 1),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20.0),
                              ),
                            ),
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(
                              'ปิด',
                              style: TextStyle(
                                  fontFamily: FontStyles().FontFamily,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              btn = false;
                              Navigator.pop(context);
                              alert(context, "กำลังสร้างทีม/องค์กร");
                              _releaseData();
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(20.0),
                              ),
                            ),
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(
                              'ใช่/ตกลง',
                              style: TextStyle(
                                  fontFamily: FontStyles().FontFamily,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
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
        );
      },
    );
  }

  _showInviteSuccessDialog(String inviteCode, String orgName, String orgId) {
    GlobalKey qrKey = GlobalKey();

    showDialog(
        context: context,
        barrierDismissible: false, // User must tap a button to close
        builder: (BuildContext context) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "เชิญสมาชิกเข้ากลุ่ม/องค์กร",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: FontStyles().FontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "กลุ่ม/องค์กร: $orgName",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: FontStyles().FontFamily,
                      fontSize: 18,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "รหัสเข้าองค์กร",
                    style: TextStyle(
                      fontFamily: FontStyles().FontFamily,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          inviteCode.length == 9
                              ? "${inviteCode.substring(0, 3)} ${inviteCode.substring(3, 6)} ${inviteCode.substring(6, 9)}"
                              : inviteCode,
                          style: TextStyle(
                            fontFamily: FontStyles().FontFamily,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: inviteCode));
                            EasyLoading.showToast("คัดลอกแล้ว");
                          },
                          child: Icon(Icons.copy, color: Colors.blue, size: 24),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  RepaintBoundary(
                    key: qrKey,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data: inviteCode,
                            version: QrVersions.auto,
                            size: 200.0,
                            embeddedImage:
                                AssetImage('assets/images/other/logo_app.png'),
                            embeddedImageStyle: QrEmbeddedImageStyle(
                              size: Size(40, 40),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => _captureAndSaveQr(qrKey, inviteCode),
                    icon: Icon(Icons.save_alt, size: 20),
                    label: Text(
                      "บันทึก QR Code",
                      style: TextStyle(fontFamily: FontStyles().FontFamily),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Logic to share text
                            Share.share(
                                'iSmartLogin ขอเชิญท่านเข้าร่วมกลุ่ม/องค์กร "$orgName"\nกรอกรหัส: $inviteCode',
                                subject: 'คำเชิญเข้าร่วมกลุ่ม/องค์กร $orgName');
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                "แชร์คำเชิญ",
                                style: TextStyle(
                                  fontFamily: FontStyles().FontFamily,
                                  color: Colors.blue,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // Close dialog
                            _goToOrgManage(); // Go logic
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF21CCD4), Color(0xFF0663F7)],
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                "เสร็จสิ้น",
                                style: TextStyle(
                                  fontFamily: FontStyles().FontFamily,
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        });
  }

  Future<void> _captureAndSaveQr(GlobalKey key, String inviteCode) async {
    try {
      EasyLoading.show(status: 'กำลังบันทึก...');
      // Wait for build to complete if needed, but key context should be ready
      // Small delay might help if UI is animating
      await Future.delayed(Duration(milliseconds: 200));

      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        EasyLoading.showError("ไม่สามารถแปลงภาพได้");
        return;
      }

      final Uint8List bytes = byteData.buffer.asUint8List();
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: "ismart_invite_$inviteCode",
      );

      // Handle different result types from the library
      bool isSuccess = false;
      if (result is Map) {
        isSuccess =
            (result['isSuccess'] == true) || (result['success'] == true);
      } else if (result == true) {
        // Sometimes returns boolean true
        isSuccess = true;
      } else if (result != null) {
        isSuccess = true;
      }

      if (isSuccess) {
        EasyLoading.showSuccess("บันทึกภาพแล้ว");
      } else {
        EasyLoading.showError("บันทึกไม่สำเร็จ");
      }
    } catch (e) {
      print("Save QR Error: $e");
      EasyLoading.showError("เกิดข้อผิดพลาดในการบันทึก");
    }
  }
}
