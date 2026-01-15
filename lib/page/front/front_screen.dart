// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'dart:convert';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

// import 'package:flutter_app_badger/flutter_app_badger.dart';

import 'package:image_picker/image_picker.dart'
    show XFile; // For XFile type only
import 'package:intl/intl.dart';
import 'package:ismart_login/page/front/drawer.dart';
import 'package:ismart_login/page/front/front_count_widget.dart';
import 'package:ismart_login/widgets/bottom_menu_grid.dart';

import 'package:ismart_login/page/front/future/attend_future.dart';
import 'package:ismart_login/page/front/future/org_future.dart';

import 'package:ismart_login/page/front/insite_popup.dart';
import 'package:ismart_login/page/front/model/attendToDay.dart';
import 'package:ismart_login/page/front/model/orglist.dart';
import 'package:ismart_login/page/front/offside_popup.dart';
import 'package:ismart_login/page/leave/leave_noti_list.dart';
import 'package:ismart_login/page/managements/future/department_manage_future.dart';
import 'package:ismart_login/page/managements/future/member_manage_future.dart';
import 'package:ismart_login/page/managements/future/time_manage_future.dart';
import 'package:ismart_login/page/managements/model/itemDepartmentResultManage.dart';
import 'package:ismart_login/page/managements/model/itemMemberResultManage.dart';
import 'package:ismart_login/page/managements/model/itemTimeResultDayManage.dart';
import 'package:ismart_login/page/managements/model/itemTimeResultMange.dart';

import 'package:ismart_login/widgets/orbit_clock_widget.dart';
import 'package:ismart_login/page/sign/model/memberlist.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/style/font_style.dart';

import 'package:ismart_login/system/shared_preferences.dart';

import 'package:ismart_login/widgets/simple_camera_screen.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'outtime_popup.dart';

class FrontScreen extends StatefulWidget {
  @override
  _FrontScreenState createState() => _FrontScreenState();
}

class _FrontScreenState extends State<FrontScreen>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Animation Controller
  late AnimationController _controller;

  //---
  Location location = new Location();
  late StreamSubscription<LocationData> locationSubscription;
  double _myLat = 0.0;
  double _myLng = 0.0;
  //--
  late String _time_id;
  String? OT_note;
  //---
  List<ItemsMemberList> _items = [];
  String badge = '0';
  //----
  String org_id = '';
  bool dayWorking = false;
  bool affiliate = false;
  String timeIn = '';
  String timeOut = '';
  String ot_status = '0';
  String end_time = '';
  //Setup
  XFile? _imageFile;
  dynamic _pickImageError;
  //-----
  bool _login = false;
  bool _logout = false;
  //-----
  TextStyle styleTime = TextStyle(
      fontFamily: FontStyles().FontFamily, fontSize: 22, color: Colors.white);
  TextStyle styleLabelCamera = TextStyle(
      fontFamily: FontStyles().FontFamily,
      fontSize: 26,
      fontWeight: FontWeight.bold,
      height: 1);
  TextStyle styleDetailCamera = TextStyle(
      fontFamily: FontStyles().FontFamily,
      fontSize: 18,
      color: Color(0xFF8D8B8B),
      height: 1);
  //-----
  var map;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4), // Spin duration
      vsync: this,
    )..repeat(); // Loop forever

    onLoadMemberManage();
    onLoadBadgeLeaveManage();
    _getMyLocation();
    _getShaerd();
  }

  @override
  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
    locationSubscription.cancel();
  }

  onLoadBadgeLeaveManage() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
    };
    print("onLoadBadgeLeaveManage : ${map}");
    var body = json.encode(map);
    final response = await http.Client().post(
      Uri.parse(Server().getBadgeLeave),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    var data = json.decode(response.body);

    if (data[0]['status'] == true) {
      badge = data[0]['badge'].toString();
    }
    updateBadge(badge);
    print("onLoadBadgeLeaveManage badge : $badge");
    setState(() {});
  }

  // updateBadge(badge) async {
  //   setState(() {
  //     var badgeCount = int.parse(badge);
  //     FlutterAppBadger.updateBadgeCount(badgeCount);
  //   });
  // }

  Future<void> updateBadge(String badge) async {
    final count = int.tryParse(badge) ?? 0; // กัน input เพี้ยน
    // เช็คว่าเครื่องรองรับไหม (บางรุ่น/launcher ไม่รองรับ)
    final supported = await AppBadgePlus.isSupported();
    if (!supported) return;

    await AppBadgePlus.updateBadge(count); // 0 = ลบ badge
  }

  _getMyLocation() {
    locationSubscription =
        location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        _myLat = currentLocation.latitude != null
            ? currentLocation.latitude!.toDouble()
            : 0.0;
        _myLng = currentLocation.longitude != null
            ? currentLocation.longitude!.toDouble()
            : 0.0;
      });
      // dispose();
    });
  }

  // --- Post Data Member
  List<ItemsOrgList> _resultOrg = [];
  Future<bool> onLoadSelectOrganization(Map map) async {
    await OrgFuture().apiGetOrganization(map).then((onValue) {
      print(onValue[0].MSG);
      if (onValue[0].MSG == 'success') {
        _resultOrg = onValue[0].RESULT;
        if (_itemMember.isNotEmpty) {
          onLoadAttend();
        } else {
          print("⛔ ยังไม่มีข้อมูลสมาชิก (_itemMember ว่าง)");
        }
      }
    });
    setState(() {});
    return true;
  }

  // --- Post Data Member
  List<ItemsAttandToDay> _resultAttand = [];
  Future<bool> onLoadAttend() async {
    if (_itemMember.isEmpty) {
      print("⛔ _itemMember ยังว่าง ไม่สามารถเรียก onLoadAttend ได้");
      return false;
    }

    print("apiGetAttandCheck time_id ${_itemMember[0].TIME_ID}");
    Map map = {
      "uid": _items.isNotEmpty ? _items[0].ID : '',
      "time_id": _itemMember[0].TIME_ID != ''
          ? _itemMember[0].TIME_ID
          : (_items.isNotEmpty ? _items[0].TIME_ID : ''),
    };
    print("apiGetAttandCheck map : $map");

    await AttandFuture().apiGetAttandCheck(map).then((onValue) {
      print("apiGetAttandCheck ${onValue[0].STATUS}");
      if (onValue[0].STATUS != 'success') {
        print('ยังไม่ login');
        _resultAttand = onValue;
        setState(() {
          _login = true;
          _logout = false;
          if (_resultAttand.isNotEmpty && _resultAttand[0].END_TIME != '') {
            end_time = _resultAttand[0].END_TIME;
          }
        });
        print("_login : $_login");
      } else {
        print('login แล้ว');
        setState(() {
          _resultAttand = onValue;
          print(_resultAttand[0].END_TIME);
          if (_resultAttand.isNotEmpty &&
              _resultAttand[0].END_TIME == '' &&
              !_login) {
            _logout = true;
          } else {
            _logout = false;
          }
          end_time = _resultAttand.isNotEmpty ? _resultAttand[0].END_TIME : '';
        });
        print("_logout : $_logout");
      }
    });
    setState(() {});
    return true;
  }

  List<ItemsMemberResultManage> _itemMember = [];
  Future<bool> onLoadMemberManage() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
    };
    var uid = await SharedCashe.getItemsWay(name: 'id');

    print("onLoadMemberManage map ${map}");
    await MemberManageFuture().apiGetMemberManageList(map).then((onValue) {
      setState(() {
        if (onValue[0].STATUS) {
          _itemMember = onValue[0].RESULT;
          _time_id = _itemMember[0].TIME_ID ?? '';
          print("onLoadMemberManage ORG_SUB_ID ${_itemMember[0].ORG_SUB_ID}");
          print("onLoadMemberManage ${_itemMember[0].TIME_ID}");
          print(
              "onLoadMemberManage LEAVE MEMBER ${_itemMember[0].LEAVE_MEMBER}");
          // SharedCashe.savaItemsString(
          //     key: 'time_id', valString: _itemMember[0].TIME_ID);
          // var time_id =  SharedCashe.getItemsWay(name: 'time_id');
          print(
              "onLoadMemberManage time_id : ${SharedCashe.getItemsWay(name: 'time_id')}");
          if (_itemMember[0].ORG_SUB_ID != '') {
            SharedCashe.savaItemsString(
                key: 'org_sub_id',
                valString: _itemMember[0].ORG_SUB_ID.toString());
            FirebaseMessaging.instance.subscribeToTopic(
                "org_" + _itemMember[0].ORG_SUB_ID.toString());
            print(
                "FirebaseMessaging ORG_SUB_ID v2 ${_itemMember[0].ORG_SUB_ID}");
          }

          FirebaseMessaging.instance.subscribeToTopic("users_" + uid);

          print("onLoadMemberManage UID : $uid");

          if (_itemMember[0].ORG_SUB_ID != '' && _itemMember[0].TIME_ID != '') {
            onLoadGetDepartment(_itemMember[0].ORG_SUB_ID ?? '');
            onLoadGetTime(_itemMember[0].TIME_ID ?? '');
            affiliate = true;
          } else {
            affiliate = false;
          }
          print("onLoadMemberManage $affiliate");
          _getShaerd();
        }
      });
    });
    print(
        "getItemsWay ORG_SUB_ID ${await SharedCashe.getItemsWay(name: 'id')}");
    setState(() {});
    return true;
  }

  ///----  / GET -----
  List<ItemsTimeResultManage> _resultItem = [];
  List<ItemsTimeResultDayManage> _resultItemDay = [];
  Future<bool> onLoadGetTime(String time_id) async {
    var today = DateTime.now();
    _resultItemDay.clear();

    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "id": time_id,
    };

    print("apiGetTimeManageList : $map");

    try {
      final onValue = await TimeManageFuture().apiGetTimeManageList(map);

      if (onValue.isNotEmpty && onValue[0].STATUS == true) {
        _resultItem = onValue[0].RESULT;
        ot_status = onValue[0].OT_STATUS;

        print("จำนวนข้อมูล time: ${_resultItem.length}");

        // ✅ ตรวจว่ามี _resultItem ก่อนเข้าถึง [0]
        if (_resultItem.isNotEmpty &&
            _resultItem[0].DESCRIPTION != null &&
            _resultItem[0].DESCRIPTION.toString().isNotEmpty) {
          final List decoded =
              json.decode(_resultItem[0].DESCRIPTION) as List<dynamic>;
          _resultItemDay =
              decoded.map((m) => ItemsTimeResultDayManage.fromJson(m)).toList();
        } else {
          print("⚠️ ไม่มีข้อมูล DESCRIPTION ใน _resultItem");
        }

        print('count day: ${_resultItemDay.length}');
        print('today weekday: ${today.weekday}');

        for (int i = 0; i < _resultItemDay.length; i++) {
          if ((today.weekday - 1).toString() ==
              _resultItemDay[i].DAY.toString()) {
            setState(() {
              dayWorking = true;
              timeIn = _resultItemDay[i].TIME_START;
              timeOut = _resultItemDay[i].TIME_END;
            });
          }
        }

        print("apiGetTimeManageList : $dayWorking");
        print("apiGetTimeManageList ot_status : $ot_status");
      } else {
        print("⚠️ ไม่มีข้อมูลสถานะ true จาก API");
      }
    } catch (e) {
      print("❌ onLoadGetTime error: $e");
    }

    return true;
  }

  List<ItemsDepartmentResultManage> _resultItemDepartment = [];
  Future<bool> onLoadGetDepartment(String org_sub_id) async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "id": org_sub_id
    };
    // print(map);
    await DepartManageFuture().apiGetDepartmentManageList(map).then((onValue) {
      if (onValue[0].STATUS == true) {
        setState(() {
          _resultItemDepartment = onValue[0].RESULT;
        });
      }
    });
    return true;
  }

  ///------

  _getShaerd() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? item = prefs.getString('item');
    if (item != null) {
      _items =
          List.from(json.decode(item).map((m) => ItemsMemberList.fromJson(m)));
      if (_items.length > 0) {
        setState(() {
          org_id = _items[0].ORG_ID;
        });
        Map _map = {"ID": _items[0].ORG_ID != '' ? _items[0].ORG_ID : ''};
        print("_getShaerd ${_map}");
        onLoadSelectOrganization(_map);
      }
    } else {
      _items = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: MenuDrawer(
          images: _itemMember.length > 0 ? (_itemMember[0].AVATAR ?? '') : '',
          leave: _itemMember.length > 0 ? (_itemMember[0].LEAVE ?? '0') : '0',
          leave_member: _itemMember.length > 0
              ? (_itemMember[0].LEAVE_MEMBER ?? '0')
              : '0',
          updateBadge: onLoadBadgeLeaveManage,
          badge: badge,
          fullname: _itemMember.length > 0
              ? _itemMember[0].NICKNAME == '' || _itemMember[0].NICKNAME == null
                  ? _subFullname(_itemMember[0].FULLNAME ?? '')
                  : _itemMember[0].NICKNAME
              : '',
          org: _itemMember.length > 0 ? (_itemMember[0].ORG_NAME ?? '') : '',
          org_sub: _itemMember.length > 0
              ? _itemMember[0].ORG_SUB_NAME == '' ||
                      _itemMember[0].ORG_SUB_NAME == null
                  ? ''
                  : (_itemMember[0].ORG_SUB_NAME ?? '')
              : '',
          org_id: org_id,
          type_member: _itemMember.length > 0
              ? (_itemMember[0].MEMBER_TYPE ?? 'member')
              : 'member'),
      body: Stack(
        children: [
          // 1. Blue Gradient Background (Full Screen)
          Container(
            height: screenHeight,
            width: screenWidth,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.3, -1.0),
                end: Alignment(0.3, 1.0),
                colors: [
                  Color(0xFF21CCD4), // 0%
                  Color(0xFF0663F7), // 100%
                ],
              ),
            ),
          ),

          // 2. Main Scrollable Content
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 10),
                      // Header
                      _buildHeader(),
                      SizedBox(height: 10),
                      // Stats Widget for Admin
                      if (_itemMember != null)
                        if (_itemMember.length > 0)
                          if (_itemMember[0].MEMBER_TYPE == 'admin')
                            FrontCountWidget(),
                      SizedBox(height: 10),
                      // Clock
                      _buildCircularClock(),
                      SizedBox(height: 8),
                      // Org Name
                      _buildOrgName(),
                      SizedBox(height: 12),
                      // Check In/Out Buttons
                      _buildActionButtons(),
                      SizedBox(height: 8),
                      // Status Text
                      _buildStatusText(),
                      SizedBox(
                          height: 0), // Removed spacing to move panel higher
                    ],
                  ),

                  // 3. White Panel with Rounded Top Corners
                  Container(
                    width: screenWidth,
                    padding: EdgeInsets.only(
                        top: 20, bottom: 100, left: 20, right: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMenuGrid(),
                        SizedBox(height: 75),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Color(0xFFFF80AB), // Pink accent
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  backgroundImage: (_itemMember.length > 0 &&
                          _itemMember[0].AVATAR != null &&
                          _itemMember[0].AVATAR != '')
                      ? NetworkImage(Server.url + (_itemMember[0].AVATAR ?? ''))
                      : null,
                  child: (_itemMember.length == 0 ||
                          _itemMember[0].AVATAR == null ||
                          _itemMember[0].AVATAR == '')
                      ? Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'สวัสดี ${_itemMember.length > 0 ? (_itemMember[0].NICKNAME ?? '') : ''}',
                style: TextStyle(
                  fontFamily: FontStyles().FontFamily,
                  color: Colors.white,
                  fontSize: 14,
                ),
              )
            ],
          ),

          // Logo (Center)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('iSmart',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: FontStyles().FontFamily)),
              Row(
                children: [
                  Text('L',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: FontStyles().FontFamily)),
                  Icon(Icons.lock_outline, color: Colors.white, size: 24),
                  Text('g',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: FontStyles().FontFamily)),
                  Text('in',
                      style: TextStyle(
                          color: Color(0xFFC6FF00),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: FontStyles().FontFamily)),
                ],
              )
            ],
          ),

          // Notification (Right)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeaveNotiListScreen(),
                ),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_none, color: Colors.white, size: 35),
                if (badge != "0")
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: Text(badge,
                          style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCircularClock() {
    // Orbit clock with rotating time indicators
    return OrbitClockWidget(
      size: 200,
    );
  }

  Widget _buildOrgName() {
    return Text(
      _itemMember.length > 0
          ? (_itemMember[0].ORG_NAME ?? 'บริษัท เดอะสแตนดาร์ด จำกัด')
          : 'ชื่อบริษัท',
      style: TextStyle(
          fontFamily: FontStyles().FontFamily,
          color: Colors.white,
          fontSize: 17,
          height: 27 / 17, // Line height 27px
          letterSpacing: 0,
          shadows: [
            Shadow(
              color: Color(0x29000000),
              offset: Offset(0, 3),
              blurRadius: 6,
            )
          ]),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      // Reduced padding to accommodate 187px buttons
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildButtonCard(context, true),
          // Vertical Dashed Line
          Container(
            height: 50,
            margin: EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                  8,
                  (index) => Container(
                        width: 2,
                        height: 3,
                        color: Colors.white.withValues(alpha: 0.5),
                      )),
            ),
          ),
          _buildButtonCard(context, false),
        ],
      ),
    );
  }

  Widget _buildButtonCard(BuildContext context, bool isCheckIn) {
    bool isEnabled = isCheckIn ? _login : _logout;
    String imageAsset;
    if (isCheckIn) {
      imageAsset = isEnabled
          ? 'assets/images/other/chekin_btn.png'
          : 'assets/images/other/chekin_btn_disable.png';
    } else {
      imageAsset = isEnabled
          ? 'assets/images/other/checkout_btn.png'
          : 'assets/images/other/checkout_btn_disable.png';
    }

    String timeLabel = isCheckIn ? 'เข้า' : 'ออก';
    String timeValue = isCheckIn ? '8:30' : '17.30'; // Should be dynamic
    String mainText = isCheckIn ? 'เข้างาน' : 'ออกงาน';
    Color textColor = isCheckIn
        ? Color(0xFF0099CC)
        : Color(0xFFFF6B8A); // Cyan for checkin, Coral pink for checkout

    // Adjust text color for disabled state if needed, or keep same
    if (!isEnabled) {
      textColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        if (!isEnabled) return;

        // Logic copy-pasted
        if (isCheckIn) {
          if (_login) {
            if (dayWorking) {
              if (ot_status == '1' && end_time != '') {
                popupOT_in(context);
              } else {
                _imgFromCamera_in(context, false);
              }
            } else {
              popupOT_in(context);
            }
          } else {
            if (dayWorking) {
              _imgFromCamera_in(context, false);
            } else {
              popupOT_in(context);
            }
          }
        } else {
          if (_logout) {
            _handleCheckoutAttempt(context);
          }
        }
      },
      child: Container(
        width: 175, // Adjusted width
        height: 90, // Adjusted height
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(45), // Pill shape
            image: DecorationImage(
                image: AssetImage(imageAsset),
                fit: BoxFit.fill // Fill to match button size
                )),
        child: Padding(
          padding: EdgeInsets.only(
              left: 80, right: 8), // Better centering in text area
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time row: "เข้า 8:30" or "ออก 17.30"
              Row(
                children: [
                  Text(timeLabel,
                      style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                          fontFamily: FontStyles().FontFamily)),
                  SizedBox(width: 3),
                  Text(timeValue,
                      style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: FontStyles().FontFamily)),
                ],
              ),
              SizedBox(height: 0),
              // Main text: "เข้างาน" or "ออกงาน"
              Text(mainText,
                  style: TextStyle(
                      fontSize: 24,
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      fontFamily: FontStyles().FontFamily)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.access_time_filled, color: Colors.yellowAccent, size: 20),
        SizedBox(width: 5),
        Text('สถานะ : ',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: FontStyles().FontFamily)),
        Text(_logout ? 'เข้างานแล้ว' : 'ยังไม่เข้างาน',
            style: TextStyle(
                color: Colors.yellowAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: FontStyles().FontFamily)),
      ],
    );
  }

  Widget _buildMenuGrid() {
    return BottomMenuGrid(
      uid: _itemMember.length > 0 ? (_itemMember[0].ID ?? '') : '',
      lat: _myLat,
      long: _myLng,
      timeId: _time_id,
    );
  }

  _imgFromCamera_in(BuildContext context, bool holiday) async {
    try {
      // Navigate to Simple Camera using Modal Bottom Sheet
      final imagePath = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.85, // 85% Height
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SimpleCameraScreen(
            title: 'เข้างาน',
          ),
        ),
      );

      if (imagePath != null) {
        setState(() {
          _imageFile = XFile(imagePath);
        });
        _getMyLocation();
        Map _map = {
          "uid": _items[0].ID,
          "pathImage": imagePath, // Use imagePath
          "lat": _resultItemDepartment[0].LATITUDE,
          "long": _resultItemDepartment[0].LONGTITUDE,
          "time": timeIn,
          "myLat": _myLat,
          "myLng": _myLng,
        };
        print("map" + _map.toString());

        showDialog(
            context: context,
            builder: (_) {
              return InsiteDialog(
                  uid: _items[0].ID,
                  pathImage: imagePath, // Use imagePath
                  lat: _resultItemDepartment[0].LATITUDE,
                  long: _resultItemDepartment[0].LONGTITUDE,
                  time: timeIn,
                  myLat: _myLat,
                  myLng: _myLng,
                  timeId: _time_id,
                  radius: double.parse(_resultItemDepartment[0].RADIUS),
                  holiday: holiday,
                  ot_note: OT_note ?? '',
                  time_server: DateFormat('HH:mm').format(DateTime.now()));
            });
      }
    } catch (e) {
      print('Error in face detection camera: $e');
    }
  }

  popupOT_in(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) {
          return OTDialog(
            onConfirmTap: (String otNote) {
              // Navigator.pop(context);
              // print("otnote $otNote");
              OT_note = otNote;
              _imgFromCamera_in(context, true);
            },
          );
        });
  }

  _imgFromCamera_out(BuildContext context, bool holiday) async {
    try {
      // Navigate to Simple Camera using Modal Bottom Sheet
      final imagePath = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.85, // 85% Height
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SimpleCameraScreen(
            title: 'ออกงาน',
          ),
        ),
      );

      if (imagePath != null) {
        setState(() {
          _imageFile = XFile(imagePath);
        });

        showDialog(
            context: context,
            builder: (_) {
              return OffsideDialog(
                uid: _items[0].ID,
                pathImage: imagePath, // Use imagePath
                lat: _resultItemDepartment[0].LATITUDE,
                long: _resultItemDepartment[0].LONGTITUDE,
                time: timeOut,
                myLat: _myLat,
                myLng: _myLng,
                timeId: _time_id,
                radius: double.parse(_resultItemDepartment[0].RADIUS),
                holiday: holiday,
                time_server: DateFormat('HH:mm').format(DateTime.now()),
              );
            });
      }
    } catch (e) {
      print('Error in face detection camera: $e');
    }
  }

  void _handleCheckoutAttempt(BuildContext context) {
    // 1. Check if we have a valid scheduled checkout time
    if (timeOut == '' || timeOut == null) {
      _proceedWithCheckout(context);
      return;
    }

    try {
      // 2. Parse times (Assuming HH:mm format)
      // Current Time
      DateTime now = DateTime.now();
      int currentHour = now.hour;
      int currentMinute = now.minute;
      int currentTotalMinutes = (currentHour * 60) + currentMinute;

      // Scheduled Time
      List<String> scheduledParts = timeOut.split(':');
      int scheduledHour = int.parse(scheduledParts[0]);
      int scheduledMinute = int.parse(scheduledParts[1]);
      int scheduledTotalMinutes = (scheduledHour * 60) + scheduledMinute;

      // 3. Compare
      if (currentTotalMinutes < scheduledTotalMinutes) {
        // Early Checkout - Show Warning
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 30),
                  SizedBox(width: 10),
                  Text('แจ้งเตือน',
                      style: TextStyle(
                          fontFamily: FontStyles().FontFamily,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                'ขณะนี้ยังไม่ถึงเวลาเลิกงาน ($timeOut)\nคุณยืนยันที่จะออกงานก่อนเวลาหรือไม่?',
                style: TextStyle(
                    fontFamily: FontStyles().FontFamily, fontSize: 18),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('ยกเลิก',
                      style: TextStyle(
                          fontFamily: FontStyles().FontFamily,
                          color: Colors.grey,
                          fontSize: 18)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    _proceedWithCheckout(context); // Proceed
                  },
                  child: Text('ยืนยัน',
                      style: TextStyle(
                          fontFamily: FontStyles().FontFamily,
                          color: Color(0xFF00B4D8),
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ),
              ],
            );
          },
        );
      } else {
        // On time or late - Proceed
        _proceedWithCheckout(context);
      }
    } catch (e) {
      print("Time parsing error: $e");
      _proceedWithCheckout(context); // Fallback
    }
  }

  void _proceedWithCheckout(BuildContext context) {
    if (dayWorking) {
      if (ot_status == '1' && end_time != '') {
        _imgFromCamera_out(context, true);
      } else {
        _imgFromCamera_out(context, false);
      }
    } else {
      _imgFromCamera_out(context, true);
    }
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
