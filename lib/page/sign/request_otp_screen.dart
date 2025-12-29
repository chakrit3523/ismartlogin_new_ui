import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ismart_login/page/sign/future/member_future.dart';
import 'package:ismart_login/page/sign/model/checkmemberlist.dart';
import 'package:ismart_login/page/sign/model/otplist.dart';
import 'package:ismart_login/page/sign/otp_screen.dart';

class RequestOtpScreen extends StatefulWidget {
  final Map<String, dynamic>? socialAuthData;

  const RequestOtpScreen({Key? key, this.socialAuthData}) : super(key: key);

  @override
  State<RequestOtpScreen> createState() => _RequestOtpScreenState();
}

class _RequestOtpScreenState extends State<RequestOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _inputPhone = TextEditingController();

  // API Results
  List<ItemsCheckMemberResult> _resultCheck = [];
  List<ItemsOTPList> _resultOtp = [];
  bool _isPhoneValid = false; // State to track phone validity

  // Social auth data
  Map<String, dynamic>? get socialAuthData => widget.socialAuthData;

  @override
  void initState() {
    super.initState();
    _inputPhone.addListener(() {
      setState(() {
        _isPhoneValid = _inputPhone.text.length == 10;
      });
    });
  }

  @override
  void dispose() {
    _inputPhone.dispose();
    super.dispose();
  }

  // Check if phone number is available
  Future<void> _checkMemberAndRequestOtp() async {
    if (!_formKey.currentState!.validate()) return;

    EasyLoading.show(status: 'กำลังตรวจสอบ...');

    Map<String, dynamic> checkMap = {
      "username": _inputPhone.text.trim(),
    };

    try {
      // 1. Check if member exists
      await MemberFuture().apiGetCheckMember(checkMap).then((onValue) async {
        _resultCheck = onValue;
        if (_resultCheck.isNotEmpty && _resultCheck[0].STATUS == "true") {
          // Status "true" means username is available (not taken)

          // 2. Request OTP
          await _requestOtp();
        } else {
          EasyLoading.dismiss();
          EasyLoading.showError('${_inputPhone.text} ถูกใช้งานแล้ว');
        }
      });
    } catch (e) {
      EasyLoading.dismiss();
      print(e);
      EasyLoading.showError('เกิดข้อผิดพลาดในการเชื่อมต่อ');
    }
  }

  Future<void> _requestOtp() async {
    Map<String, dynamic> otpMap = {
      "PHONE": _inputPhone.text.trim(),
      // Add other fields if required by apiPostOtp, usually just PHONE for request?
      // Checking signup_screen.dart usage:
      // _postDataInput() sends NAME, LASTNAME etc. + PHONE
      // But apiPostOtp usually only needs PHONE.
      // Based on legacy code, it sends the whole map.
      // We might need to send dummy data or just PHONE if the backend allows.
      // Let's try sending just PHONE first, if it fails we might need to adjust.
      "NAME": "",
      "LASTNAME": "",
      "NICKNAME": "",
      "PASSWORD": "",
      "REPASSWORD": "",
      "AVATAR": "",
    };

    print('=== Requesting OTP ===');
    print('Phone: ${_inputPhone.text.trim()}');
    print('OTP Map: $otpMap');

    try {
      await MemberFuture().apiPostOtp(otpMap).then((onValue) {
        print('=== OTP Response ===');
        print('Response: $onValue');
        print('Response length: ${onValue.length}');

        _resultOtp = onValue;
        if (_resultOtp.isNotEmpty) {
          // Assuming if we get a result, it sent successfully.
          // Legacy code prints MSG and length.
          print('OTP sent successfully!');
          print('OTP MSG: ${_resultOtp[0].MSG}');

          EasyLoading.dismiss();
          EasyLoading.showSuccess('ส่ง OTP แล้ว');

          // Extract reference code from API response if available
          String refCode = '';
          if (_resultOtp[0].MSG is Map) {
            refCode = _resultOtp[0].MSG['token']?.toString() ??
                _resultOtp[0].MSG['ref']?.toString() ??
                _resultOtp[0].MSG['refCode']?.toString() ??
                '';
          } else if (_resultOtp[0].MSG is String) {
            refCode = _resultOtp[0].MSG;
          }
          print('Reference Code: $refCode');

          // Navigate to OTP Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(
                map: {
                  ...otpMap,
                  'socialAuthData': socialAuthData, // Pass social auth data
                  'refCode': refCode, // Pass reference code
                },
              ),
            ),
          );
        } else {
          print('OTP response is empty');
          EasyLoading.dismiss();
          EasyLoading.showError('ไม่สามารถส่ง OTP ได้');
        }
      });
    } catch (e, stackTrace) {
      EasyLoading.dismiss();
      print('=== OTP Error ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      EasyLoading.showError('เกิดข้อผิดพลาดในการส่ง OTP: $e');
    }
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
        resizeToAvoidBottomInset: false,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 60), // Adjusted top spacing

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "เบอร์โทรศัพท์",
                          style: GoogleFonts.kanit(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.normal,
                            height: 1.5, // 24px line height / 16px font size
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          width: 367,
                          height: 49,
                          alignment: Alignment
                              .center, // Center the text field within the container
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextFormField(
                            controller: _inputPhone,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            textAlignVertical: TextAlignVertical
                                .center, // Center text vertically
                            style: GoogleFonts.kanit(
                              fontSize: 24,
                              color: Colors.black,
                              fontWeight: FontWeight.w300, // Thinner font
                            ),
                            decoration: InputDecoration(
                              counterText: "",
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal:
                                      15), // Remove vertical padding to let center alignment work
                              isCollapsed:
                                  true, // Helps with strict height constraints
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'โปรดระบุเบอร์โทรศัพท์';
                              } else if (value.length != 10) {
                                return 'โปรดระบุเบอร์โทรศัพท์ 10 หลัก';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 40),

                  // Button
                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _isPhoneValid ? null : Color(0xFFAAAAAA),
                        gradient: _isPhoneValid
                            ? LinearGradient(
                                colors: [Color(0xFF21CCD4), Color(0xFF0663F7)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                      ),
                      child: ElevatedButton(
                        onPressed: _checkMemberAndRequestOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "รับ OTP",
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
    );
  }
}
