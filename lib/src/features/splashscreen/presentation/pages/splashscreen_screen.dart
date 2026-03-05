import 'dart:convert';

import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:ismart_login/src/app/pages/main_page.dart';
import 'package:ismart_login/src/features/org/presentation/pages/organization_screen.dart';
import 'package:ismart_login/src/features/protect/presentation/pages/future/protect_future.dart';
import 'package:ismart_login/src/features/protect/presentation/pages/model/protectSwitch.dart';
import 'package:ismart_login/src/features/sign/presentation/pages/future/singin_future.dart';
import 'package:ismart_login/src/features/sign/presentation/pages/model/memberlist.dart';

import 'package:ismart_login/src/features/sign/presentation/pages/signin_screen.dart';

import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/system/gps.dart';
import 'package:ismart_login/src/features/protect/presentation/pages/protected.dart';
import 'package:ismart_login/system/shared_preferences.dart';
import 'package:ismart_login/system/widht_device.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:splashscreen/splashscreen.dart';

class SplashscreenScreen extends StatefulWidget {
  @override
  _SplashscreenScreenState createState() => _SplashscreenScreenState();
}

class _SplashscreenScreenState extends State<SplashscreenScreen>
    with TickerProviderStateMixin {
  bool sent = false;
  bool protect = false;
  bool new_user = false;
  bool protect_switch = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // FToast fToast;

  @override
  void initState() {
    super.initState();

    // Setup Animation
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _animationController.forward();

    // Logic Initialization
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeApp();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
      if (_items.isEmpty) {
        await prefs.remove('item');
        blocSetState(() {
          sent = false;
        });
        return;
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
      await new SigninFuture().apiSelectMember(_map).then((onValue) async {
        print(onValue[0]['msg']);
        if (onValue[0]['msg'] == 'success') {
          SharedCashe.saveItemsMemberList(item: onValue[0]['result']);
          _showToast();
          if (onValue[0]['result'][0]['org_id'] == '0') {
            blocSetState(() {
              new_user = true;
            });
          } else {
            blocSetState(() {
              new_user = false;
            });
          }
          blocSetState(() {
            sent = true;
          });
        } else if (onValue[0]['msg'] == 'fail') {
          blocSetState(() {
            sent = false;
          });
          // Silent fallback to sign in when cached auto-login is invalid.
          await prefs.remove('item');
        } else {
          blocSetState(() {
            sent = false;
          });
          // Silent fallback to sign in when cached password is no longer valid.
          await prefs.remove('item');
        }
      }, onError: (e) {
        print(e);
        blocSetState(() {
          sent = false;
        });
      });
    } else {
      blocSetState(() {
        sent = false;
      });
    }
    print("sent : ${sent}");
  }

  check_protect() async {
    bool _bool = false;
    _bool = await SharedCashe.getItemsBoolWay(key: 'setProtect');
    print('vv ' + _bool.toString());
    blocSetState(() {
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
        blocSetState(() {
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
        blocSetState(() {
          protect_switch = false;
        });
        _controllerLoginAuto();
      }
    } catch (e) {
      print("onLoadGetProtectSwith error: $e");
      blocSetState(() {
        protect_switch = false;
      });
      _controllerLoginAuto();
    }

    return true;
  }

//////////----

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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF21CCD4), // Cyan
              Color(0xFF0663F7), // Blue
            ],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration:
                            BoxDecoration(shape: BoxShape.circle, boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          )
                        ]),
                        child: Image.asset(
                          'assets/images/other/logo_app.png',
                          height: 150,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'iSmartLogin',
                        style: TextStyle(
                          fontFamily: FontStyles().FontFamily,
                          fontWeight: FontWeight.bold,
                          fontSize: 32.0,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    "Copyright© Powered by CityVariety Corporation.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: FontStyles().FontFamily,
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
          Flexible(
            child: Text(
              'สวัสดี คุณ' + _subFullname(name),
              style: TextStyle(
                  fontFamily: FontStyles().FontFamily,
                  fontSize: 18,
                  color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
