import 'dart:async';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_countdown_timer/index.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ismart_login/page/org/organization_screen.dart';
import 'package:ismart_login/page/sign/future/member_future.dart';
import 'package:ismart_login/page/sign/model/for_post.dart';
import 'package:ismart_login/page/sign/model/otplist.dart';
import 'package:ismart_login/page/sign/signup_screen.dart';
import 'package:ismart_login/utils/dialog_helper.dart';

class OtpScreen extends StatefulWidget {
  final Map map;
  OtpScreen({Key? key, required this.map}) : super(key: key);
  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // 6 controllers for 6 OTP fields
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  Map _items = {};
  String _refCode = '';

  String get _otpValue {
    return _otpControllers.map((c) => c.text).join();
  }

  _getData() {
    Map _map = {
      "OTP": _otpValue,
      "PHONE": _items['PHONE'],
    };
    return _map;
  }

  // Countdown timer
  late CountdownTimerController controller;
  int endTime = DateTime.now().millisecondsSinceEpoch + 1000 * 60; // 60 seconds

  void onEnd() {
    print('onEnd');
  }

  void onReset() {
    setState(() {
      endTime = DateTime.now().millisecondsSinceEpoch + 1000 * 60;
      controller = CountdownTimerController(endTime: endTime, onEnd: onEnd);
      controller.start();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // API - Post Data Member
  List<ItemsMemberResultList> _result = [];
  Future<bool> onLoadInsertMember(Map map) async {
    await new MemberFuture().apiInsertMember(map).then((onValue) {
      _result = onValue;
      print(onValue.length);
      print(_result[0].RESULT);
      if (_result[0].RESULT == "success") {
        // EasyLoading.dismiss(); // Handled by caller or not showed here?
        // This function seems to be called logic ONLY, but it mixed UI.
        // Wait, where is onLoadInsertMember called? It seems UNUSED in the provided code snippet!
        // Ah, it might be legacy code. But if I touch it, I should fix it.
        // Assuming it's unused or I should wrap it.

        if (_items['AVATAR'] != "") {
          onUploadAvatarProfile(_result[0].UPLOADKEY, _items['AVATAR']);
        }
        DialogHelper.showSuccess(context, 'ลงทะเบียนสำเร็จ');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrganizationScreen(),
          ),
        );
      } else {
        DialogHelper.showError(
            context, 'ลงทะเบียนไม่สำเร็จ', 'กรุณาลองใหม่อีกครั้ง');
      }
    });
    setState(() {});
    return true;
  }

  Future<dynamic> onUploadAvatarProfile(
      String uploadKey, String pathFile) async {
    await MemberFuture().uploadAvatarProfile(
      context: context,
      file: pathFile,
      uploadKey: uploadKey,
    );
    return true;
  }

  // Check OTP
  List<ItemsOTPList> _resultOtp = [];
  Future<bool> onLoadCheckOtp(Map map) async {
    AwesomeDialog loadingDialog =
        DialogHelper.showLoading(context, 'กำลังตรวจสอบ...');
    await new MemberFuture().apiGetCheckOtp(map).then((onValue) {
      _resultOtp = onValue;
      print(onValue.length);
      print(_resultOtp[0].RESULT);
      if (_resultOtp[0].RESULT == "success") {
        loadingDialog.dismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SignUpScreen(
              verifiedPhoneNumber: _items['PHONE'],
              socialAuthData: _items['socialAuthData'] as Map<String, dynamic>?,
            ),
          ),
        );
      } else {
        loadingDialog.dismiss();
        DialogHelper.showError(
            context, 'OTP ไม่ถูกต้อง', 'กรุณาตรวจสอบรหัสอีกครั้ง');
      }
    });
    setState(() {});
    return true;
  }

  @override
  void initState() {
    controller = CountdownTimerController(endTime: endTime, onEnd: onEnd);
    _items = widget.map;
    _refCode = _items['refCode']?.toString() ?? '';
    print("OTP Screen - Phone: " + (_items['PHONE'] ?? ''));
    print("OTP Screen - RefCode: $_refCode");
    super.initState();

    // Auto focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    });
  }

  // Format phone number for display (e.g., 080-7064050)
  String _formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return "";
    if (phone.length == 10) {
      return "${phone.substring(0, 3)}-${phone.substring(3)}";
    }
    return phone;
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? Color(0xFF0663F7)
              : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Center(
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          maxLength: 1,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.kanit(
            fontSize: 24,
            fontWeight: FontWeight.normal,
            color: Color(0xFF0663F7),
          ),
          decoration: InputDecoration(
            counterText: "",
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            if (value.isNotEmpty && index < 5) {
              // Move to next field
              FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
            } else if (value.isEmpty && index > 0) {
              // Move to previous field on backspace
              FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
            }
            setState(() {});
          },
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
        resizeToAvoidBottomInset: true,
        extendBodyBehindAppBar: true,
        extendBody: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/other/bg_login.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 60),

                    // Header text
                    Text(
                      "ระบุรหัส OTP ส่งไปที่ ${_formatPhoneNumber(_items['PHONE'])}",
                      style: GoogleFonts.kanit(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: 20),

                    // 6 OTP Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:
                          List.generate(6, (index) => _buildOtpBox(index)),
                    ),

                    SizedBox(height: 15),

                    // Reference Code and Resend Link Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "รหัสอ้างอิง: ${_refCode.isNotEmpty ? _refCode : '-'}",
                          style: GoogleFonts.kanit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        // Countdown / Resend
                        // Countdown / Resend
                        CountdownTimer(
                          controller: controller,
                          endTime: endTime,
                          widgetBuilder: (_, CurrentRemainingTime? time) {
                            if (time == null) {
                              return GestureDetector(
                                onTap: () async {
                                  // Resend OTP - call API and restart countdown
                                  AwesomeDialog loadingDialog =
                                      DialogHelper.showLoading(
                                          context, 'กำลังส่ง OTP...');
                                  try {
                                    Map<String, dynamic> otpMap = {
                                      "PHONE": _items['PHONE'],
                                      "NAME": "",
                                      "LASTNAME": "",
                                      "NICKNAME": "",
                                      "PASSWORD": "",
                                      "REPASSWORD": "",
                                      "AVATAR": "",
                                    };
                                    final result =
                                        await MemberFuture().apiPostOtp(otpMap);

                                    loadingDialog.dismiss();
                                    DialogHelper.showSuccess(
                                        context, 'ส่ง OTP ใหม่แล้ว');

                                    // Extract new reference code from response
                                    String newRefCode = '';
                                    if (result.isNotEmpty &&
                                        result[0].MSG is Map) {
                                      newRefCode = result[0]
                                              .MSG['token']
                                              ?.toString() ??
                                          result[0].MSG['ref']?.toString() ??
                                          result[0]
                                              .MSG['refCode']
                                              ?.toString() ??
                                          '';
                                    } else if (result.isNotEmpty &&
                                        result[0].MSG is String) {
                                      newRefCode = result[0].MSG;
                                    }

                                    // Reset countdown timer and update refCode
                                    // Dispose old controller first
                                    controller.dispose();

                                    // Create new controller and update state
                                    endTime =
                                        DateTime.now().millisecondsSinceEpoch +
                                            1000 * 60;
                                    controller = CountdownTimerController(
                                        endTime: endTime, onEnd: onEnd);
                                    controller.start();

                                    setState(() {
                                      _refCode = newRefCode;
                                    });

                                    // Clear OTP fields
                                    for (var c in _otpControllers) {
                                      c.clear();
                                    }
                                    FocusScope.of(context)
                                        .requestFocus(_focusNodes[0]);
                                  } catch (e) {
                                    loadingDialog.dismiss();
                                    DialogHelper.showError(
                                        context,
                                        'ไม่สามารถส่ง OTP ได้',
                                        'โปรดลองใหม่อีกครั้ง');
                                    print('Resend OTP error: $e');
                                  }
                                },
                                child: Text(
                                  "ขอรับรหัสใหม่",
                                  style: GoogleFonts.kanit(
                                    color: Colors.white,
                                    decoration: TextDecoration.none,
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              );
                            } else {
                              return Text(
                                "ขอรับรหัสใหม่ (${time.sec}s)",
                                style: GoogleFonts.kanit(
                                  color: Colors.white,
                                  decoration: TextDecoration.none,
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 40),

                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: _otpValue.length == 6
                              ? LinearGradient(
                                  colors: [
                                    Color(0xFF21CCD4),
                                    Color(0xFF0663F7)
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : null,
                          color:
                              _otpValue.length == 6 ? null : Color(0xFFAAAAAA),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_otpValue.length == 6) {
                              onLoadCheckOtp(_getData());
                            } else {
                              DialogHelper.showWarning(context,
                                  'ข้อมูลไม่ครบถ้วน', 'กรุณากรอก OTP 6 หลัก');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "ยืนยัน OTP",
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

                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
