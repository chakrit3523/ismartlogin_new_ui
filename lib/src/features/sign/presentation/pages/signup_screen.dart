// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:flutter/services.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ismart_login/utils/dialog_helper.dart';
import 'package:ismart_login/src/features/org/presentation/pages/organization_screen.dart';
import 'package:ismart_login/src/features/sign/presentation/pages/future/member_future.dart';
import 'package:ismart_login/src/features/sign/presentation/pages/model/checkmemberlist.dart';
import 'package:ismart_login/src/features/sign/presentation/pages/model/for_post.dart';
import 'package:ismart_login/src/features/sign/presentation/pages/model/otplist.dart';
import 'package:ismart_login/src/features/sign/presentation/pages/otp_screen.dart';
import 'package:ismart_login/system/shared_preferences.dart';

class SignUpScreen extends StatefulWidget {
  final String? verifiedPhoneNumber;
  final Map<String, dynamic>? socialAuthData;
  SignUpScreen({Key? key, this.verifiedPhoneNumber, this.socialAuthData})
      : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // Image picker
  XFile? _imageFile;
  dynamic _pickImageError;

  // Controllers
  TextEditingController _inputName = TextEditingController();
  TextEditingController _inputLastname = TextEditingController();
  TextEditingController _inputNickname = TextEditingController();
  TextEditingController _inputPhone = TextEditingController();
  TextEditingController _inputPassword = TextEditingController();
  TextEditingController _inputRePassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.verifiedPhoneNumber != null) {
      _inputPhone.text = widget.verifiedPhoneNumber!;
    }
    // Pre-fill name fields from social auth data
    if (widget.socialAuthData != null) {
      if (widget.socialAuthData!['firstName'] != null) {
        _inputName.text = widget.socialAuthData!['firstName'];
      }
      if (widget.socialAuthData!['lastName'] != null) {
        _inputLastname.text = widget.socialAuthData!['lastName'];
      }
    }
  }

  @override
  void dispose() {
    _inputName.dispose();
    _inputLastname.dispose();
    _inputNickname.dispose();
    _inputPhone.dispose();
    _inputPassword.dispose();
    _inputRePassword.dispose();
    super.dispose();
  }

  // Get form data
  Map _getFormData() {
    return {
      "NAME": _inputName.text,
      "LASTNAME": _inputLastname.text,
      "NICKNAME": _inputNickname.text,
      "PHONE": _inputPhone.text,
      "PASSWORD": _inputPassword.text,
      "REPASSWORD": _inputRePassword.text,
      "AVATAR": _imageFile?.path ?? "",
    };
  }

  // API - Register member
  List<ItemsMemberResultList> _resultRegister = [];
  Future<bool> _registerMember(Map map) async {
    AwesomeDialog loadingDialog =
        DialogHelper.showLoading(context, 'กำลังลงทะเบียน...');
    await MemberFuture().apiInsertMember(map).then((onValue) async {
      _resultRegister = onValue;
      if (_resultRegister.isNotEmpty &&
          _resultRegister[0].RESULT == "success") {
        // Save ID to SharedCashe
        print("Saving ID from Registration: ${_resultRegister[0].ID}");
        await SharedCashe.savaItemsString(
            key: 'id', valString: _resultRegister[0].ID);

        loadingDialog.dismiss();
        if (map['AVATAR'] != "") {
          await _onUploadAvatarProfile(
              _resultRegister[0].UPLOADKEY, map['AVATAR']);
        }
        DialogHelper.showSuccess(context, 'ลงทะเบียนสำเร็จ');
        Navigator.popUntil(context, (route) => route.isFirst);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrganizationScreen(),
          ),
        );
      } else {
        loadingDialog.dismiss();
        DialogHelper.showError(
            context, 'ลงทะเบียนไม่สำเร็จ', 'กรุณาลองใหม่อีกครั้ง');
      }
    });
    return true;
  }

  Future<dynamic> _onUploadAvatarProfile(
      String uploadKey, String pathFile) async {
    await MemberFuture().uploadAvatarProfile(
      context: context,
      file: pathFile,
      uploadKey: uploadKey,
    );
    return true;
  }

  // Check if member exists
  List<ItemsCheckMemberResult> _resultCheck = [];
  Future<bool> _checkMember() async {
    AwesomeDialog loadingDialog =
        DialogHelper.showLoading(context, 'กำลังตรวจสอบ...');
    Map map = {"username": _inputPhone.text};
    await MemberFuture().apiGetCheckMember(map).then((onValue) {
      _resultCheck = onValue;
      if (_resultCheck[0].STATUS == "true") {
        // Phone is available, proceed to OTP
        loadingDialog.dismiss();
        _sendOtpAndNavigate();
      } else {
        loadingDialog.dismiss();
        _showAlert("${_inputPhone.text} ถูกใช้งานแล้ว");
      }
    });
    return true;
  }

  // Send OTP
  List<ItemsOTPList> _resultOtp = [];
  Future<void> _sendOtpAndNavigate() async {
    // Show loading before sending OTP, because checkMember already dismissed its loading
    AwesomeDialog loadingDialog =
        DialogHelper.showLoading(context, 'กำลังส่ง OTP...');
    Map formData = _getFormData();
    await MemberFuture().apiPostOtp(formData).then((onValue) {
      _resultOtp = onValue;
      loadingDialog.dismiss();

      if (_resultOtp.isNotEmpty) {
        // Extract reference code
        String refCode = '';
        if (_resultOtp[0].MSG is Map) {
          refCode = _resultOtp[0].MSG['token']?.toString() ??
              _resultOtp[0].MSG['ref']?.toString() ??
              _resultOtp[0].MSG['refCode']?.toString() ??
              '';
        } else if (_resultOtp[0].MSG is String) {
          refCode = _resultOtp[0].MSG;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              map: {
                ...formData,
                'refCode': refCode,
              },
            ),
          ),
        );
      } else {
        DialogHelper.showError(
            context, 'ไม่สามารถส่ง OTP ได้', 'โปรดลองใหม่อีกครั้ง');
      }
    });
  }

  void _onRegisterPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      if (widget.verifiedPhoneNumber != null) {
        // Phone already verified, register directly
        _registerMember(_getFormData());
      } else {
        // Need to verify phone first
        _checkMember();
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool readOnly = false,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.kanit(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.normal,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            readOnly: readOnly,
            maxLength: maxLength,
            style: GoogleFonts.kanit(
              fontSize: 18,
              color: readOnly ? Colors.grey : Colors.black,
            ),
            decoration: InputDecoration(
              counterText: "",
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isCollapsed: true,
            ),
            validator: validator,
          ),
        ),
      ],
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20),

                      // Avatar with camera button
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: _handleClickFiles,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF9E9E9E),
                              ),
                              child: ClipOval(
                                child: _imageFile == null
                                    ? Icon(
                                        Icons.person,
                                        size: 80,
                                        color: Colors.white,
                                      )
                                    : Image.file(
                                        File(_imageFile!.path),
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                      ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _handleClickFiles,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 30),

                      // Row 1: ชื่อ / นามสกุล
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _inputName,
                              label: "ชื่อ",
                              keyboardType: TextInputType.name,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณากรอกชื่อ';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: _buildTextField(
                              controller: _inputLastname,
                              label: "นามสกุล",
                              keyboardType: TextInputType.name,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณากรอกนามสกุล';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      // Row 2: ชื่อเรียกในกลุ่ม/องค์กร / เบอร์โทรศัพท์
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _inputNickname,
                              label: "ชื่อเรียกในกลุ่ม/องค์กร",
                              keyboardType: TextInputType.name,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณากรอกชื่อเรียก';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: _buildTextField(
                              controller: _inputPhone,
                              label: "เบอร์โทรศัพท์",
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              readOnly: widget.verifiedPhoneNumber != null,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณากรอกเบอร์';
                                } else if (value.length != 10) {
                                  return 'กรุณากรอก 10 หลัก';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      // Row 3: รหัสผ่าน / ยืนยันรหัสผ่าน
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _inputPassword,
                              label: "รหัสผ่าน",
                              keyboardType: TextInputType.visiblePassword,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณาตั้งรหัสผ่าน';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: _buildTextField(
                              controller: _inputRePassword,
                              label: "ยืนยันรหัสผ่าน",
                              keyboardType: TextInputType.visiblePassword,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณายืนยันรหัส';
                                } else if (value != _inputPassword.text) {
                                  return 'รหัสไม่ตรงกัน';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 40),

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              colors: [Color(0xFF21CCD4), Color(0xFF0663F7)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: _onRegisterPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "ลงทะเบียน",
                              style: GoogleFonts.kanit(
                                fontSize: 21,
                                color: Colors.white,
                                fontWeight: FontWeight.normal,
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
      ),
    );
  }

  Future<void> _handleClickFiles() async {
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text(
            'อัพโหลดรูป',
            style: GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actions: <Widget>[
            CupertinoActionSheetAction(
              child: Text('รูปภาพ', style: GoogleFonts.kanit(fontSize: 16)),
              onPressed: () {
                _imgFromGallery();
                Navigator.pop(context);
              },
            ),
            CupertinoActionSheetAction(
              child: Text('กล้อง', style: GoogleFonts.kanit(fontSize: 16)),
              onPressed: () {
                _imgFromCamera();
                Navigator.pop(context);
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.kanit(fontSize: 16, color: Colors.red),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  _imgFromCamera() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );
      blocSetState(() {
        _imageFile = pickedFile;
      });
    } catch (e) {
      blocSetState(() {
        _pickImageError = e;
        print(_pickImageError.toString());
      });
    }
  }

  _imgFromGallery() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );
      blocSetState(() {
        _imageFile = pickedFile;
      });
    } catch (e) {
      blocSetState(() {
        _pickImageError = e;
        print(_pickImageError.toString());
      });
    }
  }

  void _showAlert(String text) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.kanit(fontSize: 18),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'ปิด',
                    style:
                        GoogleFonts.kanit(fontSize: 16, color: Colors.red[900]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
