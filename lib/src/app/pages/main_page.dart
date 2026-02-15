import 'dart:io';

// import 'package:ff_navigation_bar/ff_navigation_bar.dart';
import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ismart_login/src/features/front/presentation/pages/front_screen.dart';
import 'package:ismart_login/src/features/history/presentation/pages/history_screen.dart';
import 'package:ismart_login/src/features/leave/presentation/pages/leave_screen.dart';
import 'package:ismart_login/src/features/profile/presentation/pages/profile_screen.dart';
import 'package:ismart_login/src/features/menu/presentation/pages/menu_screen.dart';
import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/system/shared_preferences.dart';
import 'package:ismart_login/system/widht_device.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ismart_login/src/features/leave/presentation/pages/leave_free_screen.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/future/member_manage_future.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/model/itemMemberResultManage.dart';

class MainPage extends StatefulWidget {
  final int? initialIndex;

  const MainPage({Key? key, this.initialIndex}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  ///--
  int selectedIndex = 1;

  @override
  void initState() {
    if (widget.initialIndex != null) {
      selectedIndex = widget.initialIndex!;
    }
    onLoadMemberManage();
    super.initState();
  }

  List<ItemsMemberResultManage> _itemMember = [];
  Future<bool> onLoadMemberManage() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
    };
    print("MainPage : ${map}");
    await MemberManageFuture().apiGetMemberManageList(map).then((onValue) {
      blocSetState(() {
        if (onValue[0].STATUS) {
          _itemMember = onValue[0].RESULT;
          print("main leave : " + (_itemMember[0].LEAVE ?? ""));
        }
      });
    });
    blocSetState(() {});
    return true;
  }

  List<Widget> _getWidgetOptions() {
    return [
      LeaveScreen(),
      FrontScreen(),
      HistoryScreen(),
      Container(), // Index 3: Profile (Pushed)
      MenuScreen(
        itemMember: _itemMember,
        onBadgeUpdate: onLoadMemberManage,
      ), // Index 4: Menu
    ];
  }

  List<Widget> _getWidgetFreeOptions() {
    return [
      LeaveFreeScreen(),
      FrontScreen(),
      HistoryScreen(),
      Container(), // Index 3: Profile (Pushed)
      MenuScreen(
        itemMember: _itemMember,
        onBadgeUpdate: onLoadMemberManage,
      ), // Index 4: Menu
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await alert_back_system();
        if (shouldPop && context.mounted) {
          if (Platform.isAndroid) {
            SystemNavigator.pop();
          } else {
            exit(0);
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        extendBody: true,
        body: _itemMember.isNotEmpty && _itemMember[0].LEAVE == "1"
            ? _getWidgetOptions().elementAt(selectedIndex)
            : _getWidgetFreeOptions().elementAt(selectedIndex),
        floatingActionButton: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Color(0xFF21CCD4), // Light Blue
                Color(0xFF0663F7), // Deep Blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 2,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () {
              blocSetState(() {
                selectedIndex = 1;
              });
            },
            child: Image.asset(
              'assets/images/other/clock-plus.png',
              width: 32,
              height: 32,
              color: Colors.white,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
                offset: Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 65,
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Side
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMaterialNavItem(
                        icon: FontAwesomeIcons.envelope,
                        label: 'ลา',
                        index: 0,
                      ),
                      _buildMaterialNavItem(
                        icon: FontAwesomeIcons.user,
                        label: 'โปรไฟล์',
                        index: 3,
                      ),
                    ],
                  ),
                  // Center - space for FAB
                  SizedBox(width: 60),
                  // Right Side
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMaterialNavItem(
                        icon: FontAwesomeIcons.clockRotateLeft,
                        label: 'ประวัติ',
                        index: 2,
                      ),
                      _buildMaterialNavItem(
                        icon: FontAwesomeIcons.tableCellsLarge,
                        label: 'เมนู',
                        index: 4,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    bool isSelected = selectedIndex == index;
    return MaterialButton(
      minWidth: 40,
      onPressed: () async {
        if (index == 0) {
          // Keep yala redirect logic
          var org_id = await SharedCashe.getItemsWay(name: 'org_id');
          if (org_id == "1564") {
            var usr = await SharedCashe.getItemsWay(name: 'username');
            var pwd = await SharedCashe.getItemsWay(name: 'password');
            var url =
                "https://yalacity.go.th/hr/app_api_v1/authenticationIsmarLogin/$usr/$pwd";
            _launchInBrowser(url);
            return;
          }
        }

        // Profile button
        if (index == 3) {
          Navigator.push(
            context,
            _createSlideUpRoute(ProfileScreen()),
          );
          return;
        }

        // Menu button - Show full-screen menu sliding from bottom
        if (index == 4) {
          Navigator.push(
            context,
            _createSlideUpRoute(
              MenuScreen(
                itemMember: _itemMember,
                onBadgeUpdate: onLoadMemberManage,
              ),
            ),
          );
          return;
        }

        if (index < 3) {
          // Only update state for valid tab indices in _widgetOptions
          blocSetState(() {
            selectedIndex = index;
          });
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Color(0xFF4EA9FB) : Colors.grey,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.kanit(
              textStyle: TextStyle(
                color: isSelected ? Color(0xFF4EA9FB) : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Route _createSlideUpRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(0.0, 1.0);
        var end = Offset.zero;
        var curve = Curves.ease;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
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

  Future<void> _launchInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      exit(0);
    } else {
      throw 'Could not launch $url';
    }
  }
}
