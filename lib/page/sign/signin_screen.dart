import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ismart_login/page/front/front_screen.dart';
import 'package:ismart_login/page/main.dart';
import 'package:ismart_login/page/org/organization_screen.dart';
import 'package:ismart_login/page/sign/future/singin_future.dart';
import 'package:ismart_login/page/sign/model/memberlist.dart';
import 'package:ismart_login/page/sign/model/memberresult.dart';
import 'package:ismart_login/page/sign/repassword/search_account_screen.dart';
import 'package:ismart_login/page/sign/request_otp_screen.dart';
import 'package:ismart_login/style/page_style.dart';
import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/system/shared_preferences.dart';
import 'package:ismart_login/system/widht_device.dart';
import 'package:ismart_login/services/social_auth_service.dart';
import 'package:ismart_login/page/sign/future/member_future.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _showPageLogin = false;
  TextEditingController _inputPass = TextEditingController();

  bool checkProtect = false;
  final _formKey = GlobalKey<FormState>();

  // FToast fToast;

  TextEditingController _inputUsername = TextEditingController();
  TextEditingController _inputPassword = TextEditingController();
  FocusNode _focusUsername = FocusNode();
  FocusNode _focusPassword = FocusNode();
  //--- Map get Value
  _postDataInput() {
    Map _map = {
      "USERNAME": _inputUsername.text,
      "PASSWORD": _inputPassword.text,
      "STATUS": "manual",
    };
    return _map;
  }

  // Handle auto-login for social users
  Future<void> _handleSocialAutoLogin(String emailOrPhone) async {
    EasyLoading.show(status: 'กำลังเข้าสู่ระบบ...');

    // Use the existing login API with a special social password
    Map loginMap = {
      "USERNAME": emailOrPhone,
      "PASSWORD": "cv94#pteam", // Master password for social login
      "STATUS": "manual",
    };

    try {
      await SigninFuture().apiSelectMember(loginMap).then((onValue) async {
        if (onValue[0]['msg'] == 'success') {
          EasyLoading.dismiss();
          var result = onValue[0]['result'][0];

          // Save user data to SharedPreferences using SharedCashe
          await SharedCashe.savaItemsString(
              key: 'checkLoginStatus', valString: 'true');
          await SharedCashe.savaItemsString(
              key: 'id', valString: result['id'] ?? '');
          await SharedCashe.savaItemsString(
              key: 'password', valString: result['password'] ?? '');
          await SharedCashe.savaItemsString(
              key: 'org_id', valString: result['org_id'] ?? '');
          await SharedCashe.savaItemsString(
              key: 'fullname', valString: result['fullname'] ?? '');
          await SharedCashe.savaItemsString(
              key: 'phone', valString: result['phone'] ?? '');
          await SharedCashe.savaItemsString(
              key: 'avatar', valString: result['avatar'] ?? '');
          await SharedCashe.savaItemsString(
              key: 'username', valString: emailOrPhone);

          EasyLoading.showSuccess('เข้าสู่ระบบสำเร็จ');

          // Navigate to organization screen or front screen
          if (result['org_id'] != null &&
              result['org_id'] != '' &&
              result['org_id'] != '0') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => FrontScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => OrganizationScreen()),
            );
          }
        } else {
          EasyLoading.dismiss();
          EasyLoading.showError('ไม่สามารถเข้าสู่ระบบได้');
        }
      });
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('เกิดข้อผิดพลาด');
      print('Social auto-login error: $e');
    }
  }

  //--API
  List<ItemsMemberResult> _result = [];
  Future<bool> onLoadGetMember(Map map) async {
    EasyLoading.show();
    await new SigninFuture().apiSelectMember(map).then((onValue) async {
      print(onValue[0]['msg']);
      print("wittawat rs");
      print(onValue[0]['result']);
      if (onValue[0]['msg'] == 'success') {
        EasyLoading.dismiss();
        await SharedCashe.saveItemsMemberList(item: onValue[0]['result']);
        if (onValue[0]['result'][0]['org_id'] == '0') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrganizationScreen(),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MainPage(),
            ),
          );
          _showToast();
        }
      } else if (onValue[0]['msg'] == 'fail') {
        EasyLoading.dismiss();
        alert_non_signin(context, 'ไม่พบ Username');
      } else {
        EasyLoading.dismiss();
        alert_non_signin(context, 'Password ของคุณไม่ถูกต้อง');
      }
    });
    setState(() {});
    return true;
  }

  Widget formlogin() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _inputUsername,
            focusNode: _focusUsername,
            keyboardType: TextInputType.number,
            style: TextStyle(fontFamily: FontStyles().FontFamily, fontSize: 24),
            decoration: InputDecoration(
              hintText: 'เบอร์โทรศัพท์',
              hintStyle:
                  TextStyle(fontFamily: FontStyles().FontFamily, fontSize: 24),
              prefixIcon: Padding(
                padding: EdgeInsets.all(0), // add padding to adjust icon
                child: Icon(
                  Icons.phone_iphone,
                  size: 26,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณาป้อน เบอร์โทรศัพท์';
              }
            },
          ),
          TextFormField(
            controller: _inputPassword,
            focusNode: _focusPassword,
            obscureText: true,
            keyboardType: TextInputType.visiblePassword,
            style: TextStyle(fontFamily: FontStyles().FontFamily, fontSize: 24),
            decoration: InputDecoration(
              hintText: 'รหัสผ่าน',
              hintStyle:
                  TextStyle(fontFamily: FontStyles().FontFamily, fontSize: 24),
              prefixIcon: Padding(
                padding: EdgeInsets.all(0), // add padding to adjust icon
                child: Icon(
                  Icons.lock,
                  size: 26,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณาป้อน รหัสผ่าน';
              }
            },
          ),
          Padding(
            padding: EdgeInsets.all(20),
          ),
          GestureDetector(
            onTap: () {
              if (_formKey.currentState?.validate() ?? false) {
                onLoadGetMember(_postDataInput());
                SpinKitWave(
                  color: Colors.white,
                  size: 50.0,
                );
                print('เข้าสู่ระบบ');
              }
            },
            child: Container(
              padding: EdgeInsets.only(left: 25, right: 25),
              decoration: BoxDecoration(
                color: Color(0xFF079CFD),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                'เข้าสู่ระบบ',
                style: TextStyle(
                    fontFamily: FontStyles().FontFamily,
                    color: Colors.white,
                    fontSize: 36),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // fToast = FToast();
    // fToast.init(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: WillPopScope(
        onWillPop: () async {
          if (_showPageLogin) {
            setState(() {
              _showPageLogin = false;
            });
            return false;
          }
          return await alert_back_system();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          extendBodyBehindAppBar: true,
          extendBody: true,
          body: Stack(
            children: [
              // Background Image - positioned to fill entire screen
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Image.asset(
                  'assets/images/other/bg_login.png',
                  fit: BoxFit.cover,
                ),
              ),
              // Content with SafeArea
              SafeArea(
                top: true,
                bottom: true,
                child: _showPageLogin ? _buildLoginPage() : _buildLandingPage(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandingPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          // Logo
          Image.asset(
            'assets/images/other/logo_.png',
            height: 100,
          ),
          SizedBox(height: 20),
          // Tagline
          Text(
            "ลงชื่อเข้าออกงานง่ายๆ\nด้วยมือถือของคุณ",
            textAlign: TextAlign.center,
            style: GoogleFonts.kanit(
              fontSize: 25,
              color: Colors.white,
              fontWeight: FontWeight.w300,
              height: 1.5,
            ),
          ),
          Spacer(flex: 2),
          // Register Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF079CFD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RequestOtpScreen()),
                );
              },
              child: Text("ลงทะเบียน",
                  style: TextStyle(
                      fontSize: 19,
                      height: 23 / 19,
                      color: Colors.white,
                      fontFamily: 'Tahoma',
                      fontWeight: FontWeight.normal)),
            ),
          ),
          SizedBox(height: 15),

          // Google Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: Image.asset(
                'assets/images/other/google_icon.png',
                width: 25,
                height: 25,
                errorBuilder: (context, error, stackTrace) {
                  return FaIcon(FontAwesomeIcons.google,
                      color: Colors.red, size: 20);
                },
              ),
              label: Text("ดำเนินการต่อด้วย Google",
                  style: TextStyle(
                      fontSize: 19,
                      height: 23 / 19,
                      fontFamily: 'Tahoma',
                      fontWeight: FontWeight.normal)),
              onPressed: () async {
                EasyLoading.show(status: 'กำลังเชื่อมต่อ...');
                final result = await SocialAuthService().signInWithGoogle();

                if (result != null && result.email != null) {
                  // Check if email already exists in system
                  EasyLoading.show(status: 'กำลังตรวจสอบ...');
                  try {
                    final existingMember = await MemberFuture()
                        .apiCheckMemberByEmail(result.email!);
                    EasyLoading.dismiss();

                    if (existingMember.isNotEmpty &&
                        existingMember[0].STATUS == "true") {
                      // User exists - Auto login
                      // Use the email as username to login
                      _handleSocialAutoLogin(result.email!);
                    } else {
                      // New user - Go to OTP flow
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequestOtpScreen(
                            socialAuthData: {
                              'email': result.email,
                              'firstName': result.firstName,
                              'lastName': result.lastName,
                              'provider': result.provider,
                            },
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    EasyLoading.dismiss();
                    // On error, go to OTP flow as fallback
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestOtpScreen(
                          socialAuthData: {
                            'email': result.email,
                            'firstName': result.firstName,
                            'lastName': result.lastName,
                            'provider': result.provider,
                          },
                        ),
                      ),
                    );
                  }
                } else {
                  EasyLoading.dismiss();
                  EasyLoading.showError('ไม่สามารถเชื่อมต่อ Google ได้');
                }
              },
            ),
          ),
          SizedBox(height: 15),

          // Apple Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: FaIcon(FontAwesomeIcons.apple,
                  color: Colors.white, size: 24.97),
              label: Text("ดำเนินการต่อด้วย Apple",
                  style: TextStyle(
                      fontSize: 19,
                      height: 23 / 19,
                      fontFamily: 'Tahoma',
                      fontWeight: FontWeight.normal)),
              onPressed: () async {
                EasyLoading.show(status: 'กำลังเชื่อมต่อ...');
                final result = await SocialAuthService().signInWithApple();

                if (result != null && result.email != null) {
                  // Check if email already exists in system
                  EasyLoading.show(status: 'กำลังตรวจสอบ...');
                  try {
                    final existingMember = await MemberFuture()
                        .apiCheckMemberByEmail(result.email!);
                    EasyLoading.dismiss();

                    if (existingMember.isNotEmpty &&
                        existingMember[0].STATUS == "true") {
                      // User exists - Auto login
                      _handleSocialAutoLogin(result.email!);
                    } else {
                      // New user - Go to OTP flow
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequestOtpScreen(
                            socialAuthData: {
                              'email': result.email,
                              'firstName': result.firstName,
                              'lastName': result.lastName,
                              'provider': result.provider,
                            },
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    EasyLoading.dismiss();
                    // On error, go to OTP flow as fallback
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestOtpScreen(
                          socialAuthData: {
                            'email': result.email,
                            'firstName': result.firstName,
                            'lastName': result.lastName,
                            'provider': result.provider,
                          },
                        ),
                      ),
                    );
                  }
                } else {
                  EasyLoading.dismiss();
                  EasyLoading.showError('ไม่สามารถเชื่อมต่อ Apple ได้');
                }
              },
            ),
          ),
          SizedBox(height: 20),

          // Login Link
          TextButton(
            onPressed: () {
              setState(() {
                _showPageLogin = true;
              });
            },
            child: Text(
              "เข้าสู่ระบบ",
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                height: 23 / 19,
                fontFamily: 'Tahoma',
                fontWeight: FontWeight.normal,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLoginPage() {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(left: 20, right: 20),
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showPageLogin = false;
                  });
                },
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                'iSmartLogin',
                style: TextStyle(
                    fontFamily: FontStyles().FontFamily,
                    fontSize: 46,
                    color: Colors.white,
                    fontWeight: FontWeight.normal),
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 5, right: 5, top: 10, bottom: 20),
              width: WidhtDevice().widht(context),
              decoration: StylePage().boxWhite,
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
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 75,
                    ),
                  ),
                  Text(
                    'เข้าใช้งาน',
                    style: TextStyle(
                        fontFamily: FontStyles().FontFamily, fontSize: 46),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 40, left: 20, right: 20),
                    child: formlogin(),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SearchAccountScreen()),
                            );
                          },
                          child: Text('ลืมรหัสผ่าน',
                              style: TextStyle(
                                  fontFamily: FontStyles().FontFamily,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24)),
                        ),
                        // Removed Logic for Register since it is on the main page now, but keeping forget password
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> alert_back_system() async {
    final result = await showDialog<bool>(
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
                    'คุณต้องการออกจากแอปพลิเคชัน',
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
                            Navigator.pop(context, false);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20.0),
                              ),
                            ),
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(
                              'ไม่',
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
                            Navigator.pop(context, true);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(20.0),
                              ),
                            ),
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(
                              'ตกลง',
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
    return result ?? false;
  }

  alert_non_signin(BuildContext context, String text) async {
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

  _showToast() async {
    // this will be our toast UI
    String name = await SharedCashe.getItemsWay(name: 'fullname');
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.greenAccent,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check),
          SizedBox(
            width: 12.0,
          ),
          Text(
            'สวัสดีคุณ ' + name,
            style: TextStyle(fontFamily: FontStyles().FontFamily, fontSize: 22),
          ),
        ],
      ),
    );

    // fToast.showToast(
    //   child: toast,
    //   gravity: ToastGravity.BOTTOM,
    //   toastDuration: Duration(seconds: 3),
    // );
  }
}
