import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ismart_login/page/org/future/getJoinOrg_future.dart';
import 'package:ismart_login/page/org/join_detail_screen.dart';
import 'package:ismart_login/page/org/model/getorglist.dart';
import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/style/page_style.dart';
import 'package:ismart_login/system/scan_qr.dart';
import 'package:ismart_login/system/widht_device.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:location/location.dart';

class OrganizationJoinScreen extends StatefulWidget {
  @override
  _OrganizationJoinScreenState createState() => _OrganizationJoinScreenState();
}

class _OrganizationJoinScreenState extends State<OrganizationJoinScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _inputCode = TextEditingController();
  Location location = new Location();
  //----
  String _receiveKey = "";
  bool _btn = false;
  //---
  _navigateAndDisplaySelection(BuildContext context) async {
    // Navigator.push returns a Future that completes after calling
    // Navigator.pop on the Selection Screen.
    _receiveKey = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RScanCameraDialog()),
    );

    setState(() {
      _inputCode.text = _receiveKey;
      if (_inputCode.text.length == 9) {
        EasyLoading.show();
        onLoadSelectOrganization(_inputCode.text);
      }
    });
  }
  //---

  // --- Post Data Member
  List<ItemsGetOrgList> _resultOrg = [];
  Future<bool> onLoadSelectOrganization(String codeKey) async {
    Map map = {"INVITE_CODE": codeKey};
    await GetOrgFuture().apiGetOrganization(map).then((onValue) {
      print("=========> " + onValue[0].MSG);
      if (onValue[0].MSG == 'success') {
        _resultOrg = onValue[0].RESULT;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrganizationJoinDetailScreen(
              itemsGetOrgList: _resultOrg[0],
            ),
          ),
        );
      } else {
        EasyLoading.dismiss();
        alert_null(context, "ไม่พบทีม/องค์กร\nรหัสเชิญ " + codeKey);
      }
    });
    setState(() {});
    return true;
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
        resizeToAvoidBottomInset: true,
        extendBodyBehindAppBar: true,
        extendBody: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
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
                // Spacer
                Spacer(flex: 2),

                SizedBox(height: 20),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    "ป้อนรหัสเข้าร่วมกลุ่ม/องค์กร",
                    style: GoogleFonts.kanit(
                      fontSize: 25,
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                      height: 38 / 25,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 30),

                // Text input with QR icon (QR outside input)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    children: [
                      // Input field
                      Expanded(
                        child: Form(
                          key: _formKey,
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: TextFormField(
                                controller: _inputCode,
                                maxLength: 9,
                                keyboardType: TextInputType.number,
                                textAlignVertical: TextAlignVertical.center,
                                style: GoogleFonts.kanit(
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  isCollapsed: true,
                                  counterText: "",
                                  hintText: 'รหัสเข้าร่วมกลุ่มหรือองค์กร',
                                  hintStyle: GoogleFonts.kanit(
                                    fontSize: 18,
                                    color: Colors.grey[400],
                                  ),
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 16),
                                ),
                                onChanged: (val) {
                                  if (val.length != 9) {
                                    setState(() {
                                      _btn = false;
                                    });
                                  } else {
                                    setState(() {
                                      _btn = true;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      // QR Scan Icon (outside input)
                      if (!kIsWeb)
                        GestureDetector(
                          onTap: () {
                            _navigateAndDisplaySelection(context);
                          },
                          child: Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Image.asset(
                              'assets/images/other/scan-qrcode.png',
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                // Join Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
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
                        onPressed: () {
                          if (_inputCode.text.length == 9) {
                            EasyLoading.show();
                            onLoadSelectOrganization(_inputCode.text);
                          } else {
                            alert_null(context, 'กรุณากรอกรหัส 9 หลัก');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "เข้าร่วม",
                          style: GoogleFonts.kanit(
                            fontSize: 21,
                            color: Colors.white,
                            fontWeight: FontWeight.normal,
                            height: 30 / 21,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  alert_null(BuildContext context, String text) async {
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
                  alignment: Alignment.center,
                  height: 100,
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        height: 1,
                        fontFamily: FontStyles().FontFamily,
                        fontSize: 30,
                        fontWeight: FontWeight.bold),
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
}
