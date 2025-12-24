import 'dart:convert';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:ismart_login/page/main.dart';
import 'package:ismart_login/page/org/organization_screen.dart';
import 'package:ismart_login/page/protect/future/protect_future.dart';
import 'package:ismart_login/page/protect/model/protectSwitch.dart';
import 'package:ismart_login/page/sign/future/singin_future.dart';
import 'package:ismart_login/page/sign/model/memberlist.dart';
import 'package:ismart_login/page/sign/model/memberresult.dart';
import 'package:ismart_login/page/sign/signin_screen.dart';
import 'package:ismart_login/page/sign/signin_screen2.dart';
import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/system/gps.dart';
import 'package:ismart_login/page/protect/protected.dart';
import 'package:ismart_login/system/shared_preferences.dart';
import 'package:ismart_login/system/widht_device.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:splashscreen/splashscreen.dart';

class SplashscreenScreen extends StatefulWidget {
  @override
  _SplashscreenScreenState createState() => _SplashscreenScreenState();
}

class _SplashscreenScreenState extends State<SplashscreenScreen> {
  bool sent = false;
  bool protect = false;
  bool new_user = false;
  bool protect_switch = false;

  // FToast fToast;

  _controllerLoginAuto() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("this : _controllerLoginAuto");
    // Navigator.pop(context);
    if (prefs.containsKey('item')) {
      List<ItemsMemberList> _items = [];
      String? item = prefs.getString('item');
      if (item != null) {
        _items = List.from(
            json.decode(item).map((m) => ItemsMemberList.fromJson(m)));
      }
      //----
      print("_controllerLoginAuto : ${_items[0].ORG_ID}");
      Map _map = {
        "USERNAME": _items[0].USERNAME,
        "PASSWORD": _items[0].PASSWORD,
        "STATUS": "auto",
      };

      print("_controllerLoginAuto RR : ${_map}");
      //-----
      await new SigninFuture().apiSelectMember(_map).then((onValue) {
        print(onValue[0]['msg']);
        if (onValue[0]['msg'] == 'success') {
          SharedCashe.saveItemsMemberList(item: onValue[0]['result']);
          _showToast();
          if (onValue[0]['result'][0]['org_id'] == '0') {
            setState(() {
              new_user = true;
            });
          } else {
            setState(() {
              new_user = false;
            });
          }
          setState(() {
            sent = true;
          });
        } else if (onValue[0]['msg'] == 'fail') {
          setState(() {
            sent = false;
          });
          alert_non_signin(context, 'ไม่พบ Username');
        } else {
          setState(() {
            sent = false;
          });
          alert_non_signin(context, 'กรุณาป้อน Password ใหม่');
        }
      }, onError: (e) {
        print(e);
        setState(() {
          sent = false;
        });
      });
    } else {
      setState(() {
        sent = false;
      });
    }
    print("sent : ${sent}");
  }

  check_protect() async {
    bool _bool = false;
    _bool = await SharedCashe.getItemsBoolWay(key: 'setProtect');
    if (_bool == null) {
      _bool = false;
    }
    print('vv ' + _bool.toString());
    setState(() {
      protect = _bool;
    });

    if (protect) {
      _controllerLoginAuto();
    }
  }

//////////----
  List<ItemsProtectSwitch> _result = [];

  Future<bool> onLoadGetProtectSwith() async {
    Map<String, dynamic> map = {};
    try {
      final onValue = await ProtectFuture().apiGetProtectSwitch(map);

      if (onValue.isNotEmpty) {
        setState(() {
          _result = onValue;
          print("status : ${_result[0].status}");

          if (_result[0].status) {
            protect_switch = true;
            check_protect();
          } else {
            protect_switch = false;
            _controllerLoginAuto();
          }
        });
      } else {
        // ถ้า API ส่ง array ว่าง
        print("Protect switch result empty");
        setState(() {
          protect_switch = false;
        });
        _controllerLoginAuto();
      }
    } catch (e) {
      print("onLoadGetProtectSwith error: $e");
      setState(() {
        protect_switch = false;
      });
      _controllerLoginAuto();
    }

    return true;
  }

//////////----
  @override
  void initState() {
    // _controllerLoginAuto();
    // LocationService.checkService();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    await SharedPreferences.getInstance();
    await LocationService.checkService();
    await onLoadGetProtectSwith();

    // ✅ รอเล็กน้อยก่อนเปลี่ยนหน้า (เอฟเฟกต์ splash)
    await Future.delayed(const Duration(seconds: 2));

    Widget nextScreen;

    if (protect) {
      nextScreen = sent
          ? (new_user ? OrganizationScreen() : MainPage())
          : SignInScreen();
    } else if (protect_switch) {
      nextScreen = ProtectApp();
    } else {
      nextScreen = sent
          ? (new_user ? OrganizationScreen() : MainPage())
          : SignInScreen();
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/other/logo_app.png',
                  height: 150,
                ),
                Text(
                  'iSmartLogin',
                  style: TextStyle(
                    fontFamily: FontStyles().FontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                  ),
                ),
              ],
            ),
          ),
          // Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                "Copyright© Powered by CityVariety Corporation.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontStyles().FontFamily,
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // Widget build(BuildContext context) {
  //   Widget nextScreen;

  //   if (protect) {
  //     nextScreen = sent
  //         ? (new_user ? OrganizationScreen() : MainPage())
  //         : SignInScreen();
  //   } else if (protect_switch) {
  //     nextScreen = ProtectApp();
  //   } else {
  //     nextScreen = sent
  //         ? (new_user ? OrganizationScreen() : MainPage())
  //         : SignInScreen();
  //   }

  //   return Scaffold(
  //     body: Stack(
  //       children: [
  //         AnimatedSplashScreen(
  //           splash: Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Image.asset(
  //                 'assets/images/other/logo_app.png',
  //                 height: 150,
  //               ),
  //               Text(
  //                 'iSmartLogin',
  //                 style: TextStyle(
  //                   fontFamily: FontStyles().FontFamily,
  //                   fontWeight: FontWeight.bold,
  //                   fontSize: 24.0,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           nextScreen: nextScreen,
  //           splashIconSize: 200,
  //           duration: 3000, // 3 seconds
  //           backgroundColor: Colors.white,
  //           splashTransition: SplashTransition.fadeTransition,
  //         ),

  //         // Footer Copyright
  //         Positioned(
  //           bottom: 0,
  //           left: 0,
  //           right: 0,
  //           child: Padding(
  //             padding: const EdgeInsets.only(bottom: 20),
  //             child: Text(
  //               "Copyright© Powered by CityVariety Corporation.",
  //               textAlign: TextAlign.center,
  //               style: TextStyle(
  //                 fontFamily: FontStyles().FontFamily,
  //                 fontSize: 16,
  //                 color: Colors.grey[600],
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  _showToast() async {
    String name = await SharedCashe.getItemsWay(name: 'fullname');
    Widget toastWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50.0),
        color: Colors.greenAccent.shade100,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check),
          SizedBox(
            width: 12.0,
          ),
          Text(
            'สวัสดี คุณ' + _subFullname(name),
            style: TextStyle(
                fontFamily: FontStyles().FontFamily,
                fontSize: 25,
                color: Colors.black87),
          ),
        ],
      ),
    );

    // Show the toast widget as a SnackBar to avoid the unused-variable warning
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: toastWidget,
        backgroundColor: Colors.transparent,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
    );
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

  _subFullname(String fullname) {
    String name = '';
    List list = fullname.split(",");
    name = list[0];
    if (list.length > 1) {
      name += ' ' + list[1];
    }
    return name;
  }
}
