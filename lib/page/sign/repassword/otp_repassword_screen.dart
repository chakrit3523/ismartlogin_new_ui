import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/index.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:ismart_login/utils/dialog_helper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ismart_login/page/sign/future/member_future.dart';
import 'package:ismart_login/page/sign/model/otplist.dart';
import 'package:ismart_login/page/sign/repassword/repassword_screen.dart';
import 'package:ismart_login/page/sign/repassword/search_account_screen.dart';
import 'package:ismart_login/style/page_style.dart';
import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/system/widht_device.dart';

class OtpRepasswordScreen extends StatefulWidget {
  final Map map;
  OtpRepasswordScreen({required Key key, required this.map}) : super(key: key);
  @override
  _OtpRepasswordScreenState createState() => _OtpRepasswordScreenState();
}

class _OtpRepasswordScreenState extends State<OtpRepasswordScreen>
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
  //-- check OTP
  List<ItemsOTPList> _resultOtp = [];
  bool _isSuccessResult(String? result) {
    final normalized = (result ?? '').trim().toLowerCase();
    return normalized == 'success' ||
        normalized == 'ok' ||
        normalized == 'true' ||
        normalized == '1';
  }

  Future<void> _requestOtpAgain() async {
    AwesomeDialog loadingDialog =
        DialogHelper.showLoading(context, 'กำลังส่ง OTP...');
    try {
      final result = await MemberFuture().apiPostOtp({"PHONE": _items['PHONE']});
      loadingDialog.dismiss();
      if (result.isEmpty) {
        DialogHelper.showError(context, 'เกิดข้อผิดพลาด', 'ไม่สามารถส่ง OTP ได้');
        return;
      }
      DialogHelper.showSuccess(context, 'ส่ง OTP ใหม่แล้ว');
      _inputOtp.clear();
      endTime = DateTime.now().millisecondsSinceEpoch + 1000 * 600;
      onReset();
    } catch (e) {
      loadingDialog.dismiss();
      DialogHelper.showError(context, 'เกิดข้อผิดพลาด', 'ไม่สามารถส่ง OTP ได้');
    }
  }

  Future<bool> onLoadCheckOtp(Map map) async {
    AwesomeDialog loadingDialog =
        DialogHelper.showLoading(context, 'กำลังตรวจสอบ...');
    try {
      await new MemberFuture().apiGetCheckOtp(map).then((onValue) {
        _resultOtp = onValue;
        print(onValue.length);
        if (_resultOtp.isEmpty) {
          loadingDialog.dismiss();
          DialogHelper.showError(context, 'เกิดข้อผิดพลาด', 'ไม่พบผลการตรวจสอบ OTP');
          return;
        }
        print(_resultOtp[0].RESULT);
        if (_isSuccessResult(_resultOtp[0].RESULT)) {
          loadingDialog.dismiss();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RePasswordChange(
                uid: _items["UID"],
              ),
            ),
          );
        } else {
          loadingDialog.dismiss();
          DialogHelper.showError(context, 'เกิดข้อผิดพลาด', 'OTP ไม่ถูกต้อง');
        }
      });
    } catch (e) {
      loadingDialog.dismiss();
      DialogHelper.showError(context, 'เกิดข้อผิดพลาด', e.toString());
    }
    setState(() {});
    return true;
  }

// API
  @override
  void initState() {
    controller = CountdownTimerController(endTime: endTime, onEnd: onEnd);
    _items = widget.map;
    super.initState();
  }

  Widget formlogin() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          SizedBox(
            child: TextFormField(
              controller: _inputOtp,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontFamily: FontStyles().FontFamily, fontSize: 30),
              decoration: InputDecoration(
                alignLabelWithHint: true,
                hintText: 'OTP',
                labelStyle: TextStyle(
                    fontFamily: FontStyles().FontThaiSans,
                    fontSize: 24,
                    height: 0),
              ),
            ),
          ),
          CountdownTimer(
            controller: controller,
            endTime: endTime,
            widgetBuilder: (context, time) {
              if (time == null) {
                return Text(
                  'รหัส OTP หมดอายุ',
                  style: TextStyle(
                      fontFamily: FontStyles().FontFamily,
                      fontSize: 20,
                      color: Colors.grey),
                );
              } else {
                return Text(
                  'รหัส OTP จะหมดอายุภายใน ${time.min} นาที ${time.sec} วินาที',
                  style: TextStyle(
                      fontFamily: FontStyles().FontFamily,
                      fontSize: 18,
                      color: Colors.grey),
                );
              }
            },
          ),
          Padding(
            padding: EdgeInsets.all(20),
          ),
          Row(
            children: [
              Expanded(
                child: CountdownTimer(
                  controller: controller,
                  endTime: endTime,
                  widgetBuilder:
                      (BuildContext context, CurrentRemainingTime? time) {
                    if (time == null) {
                      return GestureDetector(
                        onTap: () async {
                          await _requestOtpAgain();
                        },
                        child: Container(
                          alignment: Alignment.center,
                          margin: EdgeInsets.only(left: 10, right: 10),
                          padding: EdgeInsets.only(left: 25, right: 25),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'ขอ OTP อีกครั้ง',
                            style: TextStyle(
                                fontFamily: FontStyles().FontFamily,
                                color: Colors.white,
                                fontSize: 36),
                          ),
                        ),
                      );
                    } else {
                      return GestureDetector(
                        onTap: () {
                          if (_formKey.currentState!.validate()) {
                            onLoadCheckOtp(_getData());
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          margin: EdgeInsets.only(left: 10, right: 10),
                          padding: EdgeInsets.only(left: 25, right: 25),
                          decoration: BoxDecoration(
                            color: Color(0xFF079CFD),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'ถัดไป',
                            style: TextStyle(
                                fontFamily: FontStyles().FontFamily,
                                color: Colors.white,
                                fontSize: 36),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          )
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
                        'ยืนยันตัวตน',
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
                              builder: (context) => SearchAccountScreen(),
                            ),
                          );
                        },
                        child: FaIcon(
                          FontAwesomeIcons.xmark,
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
                          Container(
                            margin: EdgeInsets.only(top: 15),
                            alignment: Alignment.center,
                            width: 100,
                            height: 100,
                            decoration: new BoxDecoration(
                              color: Color(0xFF18C0FF),
                              shape: BoxShape.circle,
                            ),
                            child: FaIcon(
                              FontAwesomeIcons.shieldHalved,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding:
                                EdgeInsets.only(left: 15, right: 15, top: 20),
                            child: Text(
                              'กรุณากรอก One Time Password หรือ OTP ที่ส่งไปยัง ${_items['PHONE']} ของคุณ',
                              style: TextStyle(
                                  fontFamily: FontStyles().FontFamily,
                                  fontSize: 24,
                                  height: 1),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
