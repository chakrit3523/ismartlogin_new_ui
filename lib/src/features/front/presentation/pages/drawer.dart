import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ismart_login/src/features/contact_dev/presentation/pages/contactdev_screen.dart';
import 'package:ismart_login/src/features/faq/presentation/pages/faq_screen.dart';
import 'package:ismart_login/src/features/front/presentation/pages/future/relationship_future.dart';
import 'package:ismart_login/src/features/front/presentation/pages/model/itemMemberResultRelationship.dart';
import 'package:ismart_login/src/features/leave/presentation/pages/leave_list.dart';
import 'package:ismart_login/src/features/leave/presentation/pages/leave_settings.dart';
import 'package:ismart_login/src/features/leave/presentation/pages/leave_statistics.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/future/department_manage_future.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/future/time_manage_future.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/model/itemDepartmentResultManage.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/model/itemTimeResultMange.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/org_department_screen.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/org_lock_time.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/org_member_screen.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/org_screen.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/org_time_screen.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/org_timedatail_screen.dart';
import 'package:ismart_login/src/features/map/presentation/pages/osm_map_page.dart';
import 'package:ismart_login/src/features/profile/presentation/pages/profile_screen.dart';
import 'package:ismart_login/src/features/sign/presentation/pages/signout_popup.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/style/font_style.dart';

import 'package:ismart_login/system/shared_preferences.dart';
import 'package:location/location.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:package_info/package_info.dart';

class MenuDrawer extends StatefulWidget {
  final String images;
  final String fullname;
  final String org;
  final String org_sub;
  final String org_id;
  final String type_member;
  final String leave;
  final String leave_member;
  final String badge;
  final Function updateBadge;
  MenuDrawer({
    required this.images,
    required this.fullname,
    required this.org,
    required this.org_sub,
    required this.org_id,
    required this.type_member,
    required this.leave,
    required this.badge,
    required this.updateBadge,
    required this.leave_member,
    super.key,
  });
  @override
  _MenuDrawerState createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  Location _location = new Location();
  TextStyle _txt = GoogleFonts.kanit(
    fontSize: 16,
    color: Colors.black87,
  );
//----
  String _org_id = '';
  String badge = '0';

  ///----
  double latMain = 0.0;
  double logMain = 0.0;
  late StreamSubscription<LocationData> locationSubscription;
  _getLocation() {
    locationSubscription =
        _location.onLocationChanged.listen((LocationData currentLocation) {
      blocSetState(() {
        latMain = currentLocation.latitude != null
            ? currentLocation.latitude!.toDouble()
            : 0.0;
        logMain = currentLocation.longitude != null
            ? currentLocation.longitude!.toDouble()
            : 0.0;
      });
    });
  }

  //----------------------
  List<ItemsTimeResultManage> _resultCount = [];
  Future<bool> onLoadCountTime() async {
    Map _timeMap = {"org_id": await SharedCashe.getItemsWay(name: 'org_id')};
    await TimeManageFuture().apiGetTimeManageList(_timeMap).then((onValue) {
      blocSetState(() {
        _resultCount = onValue[0].RESULT;
      });
    });
    print(_resultCount.length);
    return true;
  }

  //----------------------
  //----------------------
  List<ItemsDepartmentResultManage> _resultDepartCount = [];
  Future<bool> onLoadCountDepartment() async {
    Map _timeMap = {"org_id": widget.org_id};
    await DepartManageFuture()
        .apiGetDepartmentManageList(_timeMap)
        .then((onValue) {
      blocSetState(() {
        _resultDepartCount = onValue[0].RESULT;
      });
    });
    print("Department : " + _resultDepartCount.length.toString());
    return true;
  }

  //----------------------
  List<ItemsMemberResultRelationship> _resultRelation = [];
  Future<bool> onLoadRelation() async {
    Map _timeMap = {"uid": await SharedCashe.getItemsWay(name: 'id')};
    await MemberRelationshipFuture()
        .apiGetMemberRelationshipList(_timeMap)
        .then((onValue) {
      blocSetState(() {
        _resultRelation = onValue[0].RESULT;
      });
    });
    return true;
  }

  //----------------------
  String _version = '0.0.0';
  _checkVer() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    blocSetState(() {
      _version = packageInfo.version;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getLocation();
    onLoadCountTime();
    onLoadCountDepartment();
    onLoadRelation();
    onLoadBadgeLeaveManage();
    _checkVer();
  }

  @override
  void dispose() {
    locationSubscription.cancel();
    widget.updateBadge();
    super.dispose();
  }

  onLoadBadgeLeaveManage() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
    };
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
    blocSetState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 10.0,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Custom Header with gradient
          Container(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                right: 20,
                bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF21CCD4), // Cyan
                  Color(0xFF0663F7), // Deep Blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                widget.images == ''
                    ? Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.grey[600],
                          size: 40,
                        ),
                      )
                    : Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          image: DecorationImage(
                            image: NetworkImage(Server.url + widget.images),
                            fit: BoxFit.cover,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                SizedBox(width: 12),
                // Name and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.fullname,
                        style: GoogleFonts.kanit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.org,
                        style: GoogleFonts.kanit(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Notification bell
                IconButton(
                  icon: Icon(Icons.notifications_none,
                      color: Colors.white, size: 28),
                  onPressed: () {
                    // TODO: Handle notification tap
                  },
                ),
              ],
            ),
          ),
          ListTile(
            minLeadingWidth: 0.5,
            leading: FaIcon(
              FontAwesomeIcons.user,
              size: 20,
            ),
            title: Text(
              'ข้อมูลส่วนตัว',
              style: _txt,
            ),
            onTap: () {
              // Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(),
                ),
              );
            },
          ),

          Visibility(
            // visible: widget.type_member == 'member' ? false : true,
            child: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(), //here is a divider
                  if (widget.type_member != 'member')
                    Padding(
                      padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
                      child: Text(
                        "Administrator",
                        style: GoogleFonts.kanit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  Container(
                    child: Column(
                      children: [
                        if (widget.type_member != 'member')
                          Column(
                            children: [
                              ListTile(
                                minLeadingWidth: 0.5,
                                leading: FaIcon(
                                  FontAwesomeIcons.building,
                                  size: 20,
                                ),
                                title: Text(
                                  'จัดการองค์กร',
                                  style: _txt,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrgManageScreen(),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                minLeadingWidth: 0.5,
                                leading: FaIcon(
                                  FontAwesomeIcons.userGroup,
                                  size: 20,
                                ),
                                title: Text(
                                  'สมาชิก',
                                  style: _txt,
                                ),
                                onTap: () {
                                  Navigator.pop(context);

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrgMemberScreen(),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                minLeadingWidth: 0.5,
                                leading: FaIcon(
                                  FontAwesomeIcons.streetView,
                                  size: 20,
                                ),
                                title: Text(
                                  'สาขา',
                                  style: _txt,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrgDepartmentManage(
                                          org_id: widget.org_id),
                                    ),
                                  );
                                  // print("_resultDepartCount  : ${_resultDepartCount.length}");
                                  // if (_resultDepartCount.length > 1) {
                                  //   Navigator.push(
                                  //     context,
                                  //     MaterialPageRoute(
                                  //       builder: (context) =>
                                  //           OrgDepartmentManage(
                                  //               org_id: widget.org_id),
                                  //     ),
                                  //   );
                                  // } else {
                                  //   EasyLoading.show();
                                  //   Navigator.push(
                                  //     context,
                                  //     MaterialPageRoute(
                                  //       builder: (context) =>
                                  //           OrgDepartmentDetailManage(
                                  //         id: _resultDepartCount.length == 1
                                  //             ? _resultDepartCount[0].ID
                                  //             : '0',
                                  //         org_id: widget.org_id,
                                  //         type: _resultDepartCount.length == 1
                                  //             ? 'update'
                                  //             : 'insert',
                                  //         lat: _resultDepartCount.length == 1
                                  //             ? double.parse(
                                  //                 _resultDepartCount[0]
                                  //                     .LATITUDE)
                                  //             : latMain,
                                  //         lng: _resultDepartCount.length == 1
                                  //             ? double.parse(
                                  //                 _resultDepartCount[0]
                                  //                     .LONGTITUDE)
                                  //             : logMain,
                                  //       ),
                                  //     ),
                                  //   );
                                  // }
                                },
                              ),
                              ListTile(
                                minLeadingWidth: 0.5,
                                leading: FaIcon(
                                  FontAwesomeIcons.businessTime,
                                  size: 20,
                                ),
                                title: Text(
                                  'เวลาทำงาน',
                                  style: _txt,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  if (_resultCount.length > 1) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrgTimeManage(
                                          org_id: widget.org_id,
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            OrgTimeDetailManage(
                                          id: _resultCount.length == 1
                                              ? _resultCount[0].ID
                                              : '0',
                                          org_id: widget.org_id,
                                          type: _resultCount.length == 1
                                              ? 'update'
                                              : 'insert',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              ListTile(
                                minLeadingWidth: 0.5,
                                leading: FaIcon(
                                  FontAwesomeIcons.lockOpen,
                                  size: 20,
                                ),
                                title: Text(
                                  'ตั้งเวลาปุ่มเข้า-ออกงาน',
                                  style: _txt,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            OrgLockTimeScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                        if ((widget.leave == "1" &&
                                widget.type_member != 'member') ||
                            (widget.leave_member == "1" &&
                                widget.type_member != 'admin'))
                          ListTile(
                            minLeadingWidth: 0.5,
                            leading: FaIcon(
                              FontAwesomeIcons.envelope,
                              size: 20,
                            ),
                            title: Container(
                              child: Stack(
                                children: [
                                  Text(
                                    'อนุมัติลางาน',
                                    style: _txt,
                                  ),
                                  if (badge != "0")
                                    Positioned(
                                      top: 0.5,
                                      right: 7,
                                      child: new Container(
                                        padding: EdgeInsets.all(1.0),
                                        decoration: new BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        ),
                                        constraints: BoxConstraints(
                                          minWidth: 20.0,
                                          minHeight: 20.0,
                                        ),
                                        child: new Text(
                                          badge.toString(),
                                          textScaler: TextScaler.linear(1.0),
                                          style: new TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.0,
                                              height: 1.5),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    )
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LeaveListScreen(
                                    updateBadge: widget.updateBadge,
                                  ),
                                ),
                              );
                            },
                          ),
                        if (widget.leave == "1")
                          ListTile(
                            minLeadingWidth: 0.5,
                            leading: FaIcon(
                              FontAwesomeIcons.chartLine,
                              size: 20,
                            ),
                            title: Text(
                              'สถิติการลา',
                              style: _txt,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LeaveStatisticsScreen(),
                                ),
                              );
                            },
                          ),
                        if (widget.leave == "1" &&
                            widget.type_member != 'member')
                          ListTile(
                            minLeadingWidth: 0.5,
                            leading: FaIcon(
                              FontAwesomeIcons.gears,
                              size: 20,
                            ),
                            title: Text(
                              'ตั้งค่าลางาน',
                              style: _txt,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LeaveSettingsScreen(),
                                ),
                              );
                            },
                          ),
                        // ListTile(
                        //   minLeadingWidth: 0.5,
                        //   leading: FaIcon(
                        //     FontAwesomeIcons.solidCalendarTimes,
                        //     size: 20,
                        //   ),
                        //   title: Text(
                        //     'วันหยุด',
                        //     style: _txt,
                        //   ),
                        //   onTap: () {
                        //     Navigator.pop(context);
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //         builder: (context) => OrgHolidayManage(),
                        //       ),
                        //     );
                        //   },
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Divider(), //here is a divider
          Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Text(
              "อื่น ๆ",
              style: GoogleFonts.kanit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  minLeadingWidth: 0.5,
                  leading: FaIcon(
                    FontAwesomeIcons.question,
                    size: 20,
                  ),
                  title: Text(
                    'คำถามที่พบบ่อย',
                    style: _txt,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Faq(),
                      ),
                    );
                  },
                ),
                ListTile(
                  minLeadingWidth: 0.5,
                  leading: FaIcon(
                    FontAwesomeIcons.code,
                    size: 20,
                  ),
                  title: Text(
                    'ติดต่อผู้พัฒนา',
                    style: _txt,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContactDeveloper(),
                      ),
                    );
                  },
                ),
                ListTile(
                  minLeadingWidth: 0.5,
                  leading: FaIcon(
                    FontAwesomeIcons.mapLocationDot,
                    size: 20,
                  ),
                  title: Text(
                    'แผนที่ OSM',
                    style: _txt,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OSMMapPage(
                          lat: latMain != 0.0 ? latMain : 13.7563,
                          lon: logMain != 0.0 ? logMain : 100.5018,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Divider(), //here is a divider
          Padding(padding: EdgeInsets.all(5)),
          ListTile(
            minLeadingWidth: 0.5,
            leading: FaIcon(
              FontAwesomeIcons.rightFromBracket,
              size: 20,
            ),
            title: Text(
              'ออกจากระบบ',
              style: _txt,
            ),
            onTap: () {
              Navigator.pop(context);
              alert_signout(context);
            },
          ),
          Divider(), //here is a divider
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: Column(
              children: [
                Text(
                  'iSmartLogin  V.' + _version,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FontStyles().FontFamily,
                    fontSize: 12,
                    color: Colors.grey[400],
                    height: 1,
                    // color: Colors.white,
                  ),
                ),
                Text(
                  "Copyright© Powered by CityVariety Corporation.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FontStyles().FontFamily,
                    fontSize: 12,
                    color: Colors.grey[400], height: 1,
                    // color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
          ),
        ],
      ),
    );
  }
}
