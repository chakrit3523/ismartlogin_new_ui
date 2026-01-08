import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ismart_login/utils/dialog_helper.dart';
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

    AwesomeDialog loadingDialog =
        DialogHelper.showLoading(context, 'กำลังตรวจสอบ...');

    Map<String, dynamic> checkMap = {
      "username": _inputPhone.text.trim(),
    };

    try {
      // 1. Check if member exists
      await MemberFuture().apiGetCheckMember(checkMap).then((onValue) async {
        _resultCheck = onValue;
        if (_resultCheck.isNotEmpty && _resultCheck[0].STATUS == "true") {
          // Status "true" means username is available (not taken)
          loadingDialog.dismiss();

          // 2. Show Confirmation Dialog
          bool confirm = await _showConfirmationDialog();
          if (confirm) {
            // 3. Request OTP
            await _requestOtp();
          }
        } else {
          loadingDialog.dismiss();
          DialogHelper.showError(
              context, 'เกิดข้อผิดพลาด', '${_inputPhone.text} ถูกใช้งานแล้ว');
        }
      });
    } catch (e) {
      loadingDialog.dismiss();
      print(e);
      DialogHelper.showError(
          context, 'เกิดข้อผิดพลาด', 'เกิดข้อผิดพลาดในการเชื่อมต่อ');
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Color(0xFFE5F6FD),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.phonelink_ring,
                        color: Color(0xFF079CFD),
                        size: 40,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "ยืนยันเบอร์โทรศัพท์",
                      style: GoogleFonts.kanit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "ต้องการรับ OTP เบอร์นี้ใช่หรือไม่?",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.kanit(
                        fontSize: 16,
                        color: Color(0xFF666666),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      _inputPhone.text,
                      style: GoogleFonts.kanit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF079CFD),
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                "ยกเลิก",
                                style: GoogleFonts.kanit(
                                  fontSize: 18,
                                  color: Color(0xFF888888),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF21CCD4), Color(0xFF0663F7)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Color(0xFF0663F7).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                "ยืนยัน",
                                style: GoogleFonts.kanit(
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
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  Future<void> _requestOtp() async {
    Map<String, dynamic> otpMap = {
      "PHONE": _inputPhone.text.trim(),
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

    AwesomeDialog loadingDialog =
        DialogHelper.showLoading(context, 'กำลังส่ง OTP...');

    try {
      await MemberFuture().apiPostOtp(otpMap).then((onValue) {
        print('=== OTP Response ===');
        print('Response: $onValue');
        print('Response length: ${onValue.length}');

        _resultOtp = onValue;
        if (_resultOtp.isNotEmpty) {
          loadingDialog.dismiss();
          print('OTP sent successfully!');
          print('OTP MSG: ${_resultOtp[0].MSG}');

          DialogHelper.showSuccess(context, 'ส่ง OTP แล้ว');

          // Extract reference code from API response if available
          String refCode = '';
          var msgData = _resultOtp[0].MSG;
          print('=== MSG Analysis ===');
          print('MSG Type: ${msgData.runtimeType}');
          print('MSG Value: $msgData');

          if (msgData is Map) {
            print('MSG Keys: ${msgData.keys.toList()}');
            // Try common SMS provider keys
            refCode = msgData['token']?.toString() ??
                msgData['ref']?.toString() ??
                msgData['refCode']?.toString() ??
                msgData['reference']?.toString() ??
                msgData['code']?.toString() ??
                msgData['otp_ref']?.toString() ??
                msgData['data']?['ref']?.toString() ??
                msgData['data']?['token']?.toString() ??
                '';
            print('Extracted refCode from Map: $refCode');
          } else if (msgData is String) {
            refCode = msgData;
            print('Using MSG string as refCode: $refCode');
          }
          print('Final Reference Code: $refCode');

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
          loadingDialog.dismiss();
          DialogHelper.showError(
              context, 'เกิดข้อผิดพลาด', 'ไม่สามารถส่ง OTP ได้');
        }
      });
    } catch (e, stackTrace) {
      loadingDialog.dismiss();
      print('=== OTP Error ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      DialogHelper.showError(
          context, 'ข้อผิดพลาด', 'เกิดข้อผิดพลาดในการส่ง OTP: $e');
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
