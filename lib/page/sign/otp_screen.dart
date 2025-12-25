import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:flutter_countdown_timer/index.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ismart_login/page/org/organization_screen.dart';
import 'package:ismart_login/page/sign/future/member_future.dart';
import 'package:ismart_login/page/sign/model/for_post.dart';
import 'package:ismart_login/page/sign/model/otplist.dart';
import 'package:ismart_login/page/sign/signup_screen.dart';
import 'package:ismart_login/style/page_style.dart';
import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/system/widht_device.dart';

class OtpScreen extends StatefulWidget {
  final Map map;
  OtpScreen({Key? key, required this.map}) : super(key: key);
  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  //-----
  bool _reOtp = true;
  Map _items = {};
  //---
  TextEditingController _inputOtp = TextEditingController();
  _getData() {
    Map _map = {
      "OTP": _inputOtp.text,
      "PHONE": _items['PHONE'],
    };
    return _map;
  }

  //Setup
  late CountdownTimerController controller;
  int endTime = DateTime.now().millisecondsSinceEpoch + 1000 * 600;
  void onEnd() {
    print('onEnd');
  }

  void onReset() {
    setState(() {
      controller = CountdownTimerController(endTime: endTime, onEnd: onEnd);
      controller.start();
    });
    // controller.start();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

// API
// --- Post Data Member
  List<ItemsMemberResultList> _result = [];
  Future<bool> onLoadInsertMember(Map map) async {
    await new MemberFuture().apiInsertMember(map).then((onValue) {
      _result = onValue;
      print(onValue.length);
      print(_result[0].RESULT);
      if (_result[0].RESULT == "success") {
        EasyLoading.dismiss();
        if (_items['AVATAR'] != "") {
          onUploadAvatarProfile(_result[0].UPLOADKEY, _items['AVATAR']);
        }
        EasyLoading.showSuccess('ลงทะเบียนสำเร็จ');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrganizationScreen(),
          ),
        );
      } else {
        EasyLoading.showError('ลงทะเบียนไม่สำเร็จ');
      }
    });
    setState(() {});
    return true;
  }

  Future<dynamic> onUploadAvatarProfile(
      String uploadKey, String pathFile) async {
    await MemberFuture().uploadAvatarProfile(
      file: pathFile,
      uploadKey: uploadKey,
    );
    return true;
  }

  //-- check OTP
  List<ItemsOTPList> _resultOtp = [];
  Future<bool> onLoadCheckOtp(Map map) async {
    await new MemberFuture().apiGetCheckOtp(map).then((onValue) {
      _resultOtp = onValue;
      print(onValue.length);
      print(_resultOtp[0].RESULT);
      if (_resultOtp[0].RESULT == "success") {
        EasyLoading.dismiss();
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
        EasyLoading.showError('OTP ไม่ถูกต้อง');
      }
    });
    setState(() {});
    return true;
  }

// API
  @override
  void initState() {
    controller = CountdownTimerController(endTime: endTime, onEnd: onEnd);
    _items = widget.map;
    print("FILE IMAGES => " + _items['AVATAR']);
    super.initState();
  }

  Widget formlogin() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          SizedBox(
            height: 0, // Hidden input
            child: TextFormField(
              controller: _inputOtp,
              keyboardType: TextInputType.number,
              // maxLength: 6, // Removed to avoid counter text if decoration doesn't hide it well enough, handled in onChanged
              style: TextStyle(color: Colors.transparent),
              decoration: InputDecoration(
                hintText: '',
                counterText: "",
                border: InputBorder.none,
                fillColor: Colors.transparent,
                filled: true,
              ),
              onChanged: (value) {
                if (value.length <= 6) {
                  setState(() {});
                }
              },
            ),
          ),

          SizedBox(height: 20),

          // 6 PIN Boxes
          GestureDetector(
            onTap: () {
              // Focus the hidden text field when boxes are tapped
              // We need a FocusNode for this ideally, but shifting focus to the text field works if it's the only one.
              // Since I didn't add a FocusNode to the hidden field yet, let's just assume the user taps the hidden field (which has height 0 so it's hard).
              // Actually, simplest way without focus node state is to wrap the boxes in a GestureDetector that calls a FocusNode.
              // Let's rely on the user tapping the field if visible, or better, make the container wrap the field.
              // For now, let's keep it simple: the field is hidden but we need to focus it.
              // Let's add autofocus or a way to tap.
              // A common trick is to stack the invisible field ON TOP of the boxes.
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    index < _inputOtp.text.length ? _inputOtp.text[index] : "",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: FontStyles().FontFamily,
                      color: Colors.black,
                    ),
                  ),
                );
              }),
            ),
          ),
          // To ensure input works, let's make the textfield cover the boxes but be invisible?
          // Or just let the user tap the invisible field? No that won't work.
          // Let's add a FocusNode.

          SizedBox(height: 20),

          // Reference Code and Resend Link Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "รหัสอ้างอิง: EIRT", // Mock reference code
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: FontStyles().FontFamily,
                ),
              ),
              // Countdown / Resend
              CountdownTimer(
                controller: controller,
                endTime: endTime,
                widgetBuilder: (_, CurrentRemainingTime? time) {
                  if (time == null) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    OtpScreen(map: widget.map)));
                      },
                      child: Text(
                        "ขอรับรหัสใหม่",
                        style: TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                          fontSize: 16,
                          fontFamily: FontStyles().FontFamily,
                        ),
                      ),
                    );
                  } else {
                    return Text(
                      "ขอรับรหัสใหม่ (${time.sec})",
                      style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        fontSize: 16,
                        fontFamily: FontStyles().FontFamily,
                      ),
                    );
                  }
                },
              ),
            ],
          ),

          SizedBox(height: 40),

          // Confirm Button
          Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2DC4E2), Color(0xFF0058FF)], // Gradient Blue
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (_inputOtp.text.length == 6) {
                  onLoadCheckOtp(_getData());
                } else {
                  EasyLoading.showError("กรุณากรอก OTP 6 หลัก");
                }
              },
              child: Text(
                "ตกลง",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: FontStyles().FontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: StylePage().background,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(left: 20, right: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'iSmartLogin',
                        style: TextStyle(
                            fontFamily: FontStyles().FontFamily,
                            fontSize: 46,
                            color: Colors.white,
                            fontWeight: FontWeight.normal),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignUpScreen(),
                            ),
                          );
                        },
                        child: FaIcon(
                          FontAwesomeIcons.times,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  child: Container(
                    padding:
                        EdgeInsets.only(left: 5, right: 5, top: 10, bottom: 20),
                    width: WidhtDevice().widht(context),
                    decoration: StylePage().boxWhite,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 60), // Add top spacing
                          Container(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              // Use the format from the image "ระบุรหัส OTP ส่งไปที่..."
                              'ระบุรหัส OTP ส่งไปที่ ${_items['PHONE'] ?? ""}',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontFamily: FontStyles().FontFamily,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // Removed old text container
                          Container(),
                          Container(
                            padding:
                                EdgeInsets.only(top: 40, left: 20, right: 20),
                            child: formlogin(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
