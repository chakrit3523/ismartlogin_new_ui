import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ismart_login/page/managements/future/department_manage_future.dart';
import 'package:ismart_login/page/managements/future/time_manage_future.dart';
import 'package:ismart_login/page/managements/model/itemDepartmentResultManage.dart';
import 'package:ismart_login/page/managements/model/itemMemberResultManage.dart';
import 'package:ismart_login/page/managements/model/itemTimeResultMange.dart';
import 'package:ismart_login/page/managements/org_memberdetail.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/style/page_style.dart';
import 'package:ismart_login/style/text_style.dart';
import 'package:ismart_login/system/shared_preferences.dart';
import 'package:ismart_login/system/widht_device.dart';

import 'future/member_manage_future.dart';

class OrgMemberScreen extends StatefulWidget {
  @override
  _OrgMemberScreenState createState() => _OrgMemberScreenState();
}

class _OrgMemberScreenState extends State<OrgMemberScreen> {
  int status = 0;

  ///-----member
  List<ItemsMemberResultManage> _item = [];
  Future<bool> onLoadMemberManage(String _status) async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "status": _status != '0' ? _status : '',
    };
    await MemberManageFuture().apiGetMemberManageList(map).then((onValue) {
      setState(() {
        if (onValue[0].STATUS) {
          _item = onValue[0].RESULT;
        }
      });
    });
    EasyLoading.dismiss();
    setState(() {});
    return true;
  }

  ///------ department
  List<ItemsDepartmentResultManage> _itemDepartment = [];
  Future<bool> onLoadGetAllDepartment() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
    };
    await DepartManageFuture().apiGetDepartmentManageList(map).then((onValue) {
      if (onValue[0].STATUS == true) {
        setState(() {
          _itemDepartment = onValue[0].RESULT;
        });
      }
    });
    return true;
  }

  _getSubjectDepartment(int _num) {
    String subject = '';
    for (int i = 0; i < _itemDepartment.length; i++) {
      if (_itemDepartment[i].ID == _num.toString()) {
        subject = _itemDepartment[i].SUBJECT;
      }
    }
    return subject;
  }

  ///------ time
  List<ItemsTimeResultManage> _itemTime = [];
  Future<bool> onLoadGetAllTime() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
    };
    await TimeManageFuture().apiGetTimeManageList(map).then((onValue) {
      if (onValue[0].STATUS == true) {
        setState(() {
          _itemTime = onValue[0].RESULT;
          print(_itemTime[0].SUBJECT);
        });
      }
    });
    return true;
  }

  _getSubjectTime(int _num) {
    String subject = '';
    for (int i = 0; i < _itemTime.length; i++) {
      if (_itemTime[i].ID == _num.toString()) {
        subject = _itemTime[i].SUBJECT;
      }
    }
    return subject;
  }

  //----
  Widget _buildFilterChip(String text, int value) {
    bool isSelected = status == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          status = value;
          EasyLoading.show();
          onLoadMemberManage(value.toString());
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: Colors.white.withOpacity(0.4)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          text,
          style: GoogleFonts.kanit(
            fontSize: 14,
            color: isSelected ? Color(0xFF079CFD) : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    onLoadGetAllTime();
    onLoadGetAllDepartment();
    onLoadMemberManage('0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: StylePage().background,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      AppBar(
                        centerTitle: true,
                        leading: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 26,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        actions: [
                          // Removed redundant PopupMenuButton as we now have filter chips
                          Container(
                            margin: EdgeInsets.only(right: 16),
                            child: CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: IconButton(
                                icon: FaIcon(FontAwesomeIcons.magnifyingGlass,
                                    size: 18, color: Colors.white),
                                onPressed: () {
                                  // TODO: Implement search functionality
                                },
                              ),
                            ),
                          )
                        ],
                        title: Text(
                          'สมาชิก',
                          style: StylesText.titleAppBar,
                        ),
                        backgroundColor: Colors.white.withOpacity(0),
                        elevation: 0,
                      ),
                      Container(
                        width: WidhtDevice().widht(context),
                        padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip('ทั้งหมด', 0),
                                  SizedBox(width: 10),
                                  _buildFilterChip('เข้าใช้งานปกติ', 1),
                                  SizedBox(width: 10),
                                  _buildFilterChip('ระงับการใช้งาน', 2),
                                ],
                              ),
                            ),
                            SizedBox(height: 15),
                            Row(
                              children: [
                                Text(
                                  'จำนวนสมาชิก',
                                  style: GoogleFonts.kanit(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  _item.length.toString(),
                                  style: GoogleFonts.kanit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'คน',
                                  style: GoogleFonts.kanit(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _item.length > 0
                            ? Container(
                                width: WidhtDevice().widht(context),
                                padding: EdgeInsets.only(left: 20, right: 20),
                                child: ListView.builder(
                                  itemCount: _item.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return GestureDetector(
                                      onTap: () {
                                        EasyLoading.show();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                OrgMemberDetailScreen(
                                              title:
                                                  _item[index].FULLNAME ?? '',
                                              id_member:
                                                  _item[index].ID.toString(),
                                              status: _item[index].STATUS == '1'
                                                  ? true
                                                  : false,
                                            ),
                                          ),
                                        ).then((value) {
                                          value
                                              ? onLoadMemberManage('0')
                                              : null;
                                        });
                                      },
                                      child: Container(
                                        margin: EdgeInsets.only(bottom: 15),
                                        width: WidhtDevice().widht(context),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          border: Border(
                                            left: BorderSide(
                                              color: _item[index].STATUS == '1'
                                                  ? Color(0xFF4CAF50)
                                                  : Color(0xFFEF5350),
                                              width: 5,
                                            ),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.08),
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              // Avatar with gradient
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Color(0xFF18C0FF),
                                                      Color(0xFF079CFD)
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color(0xFF18C0FF)
                                                          .withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: _item[index].AVATAR ==
                                                            null ||
                                                        _item[index].AVATAR ==
                                                            ''
                                                    ? Icon(
                                                        Icons.person,
                                                        color: Colors.white,
                                                        size: 35,
                                                      )
                                                    : ClipOval(
                                                        child: Image.network(
                                                          Server.url +
                                                              (_item[index]
                                                                      .AVATAR ??
                                                                  ''),
                                                          fit: BoxFit.cover,
                                                          width: 60,
                                                          height: 60,
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) {
                                                            return Icon(
                                                              Icons.person,
                                                              color:
                                                                  Colors.white,
                                                              size: 35,
                                                            );
                                                          },
                                                        ),
                                                      ),
                                              ),
                                              SizedBox(width: 12),
                                              // Content
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Name with ADMIN badge
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            _subFullname(_item[
                                                                        index]
                                                                    .FULLNAME ??
                                                                ''),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: GoogleFonts
                                                                .kanit(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: Colors
                                                                  .grey[800],
                                                            ),
                                                          ),
                                                        ),
                                                        if (_item[index]
                                                                .MEMBER_TYPE ==
                                                            'admin')
                                                          Container(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical:
                                                                        2),
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.amber,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            child: Text(
                                                              'ADMIN',
                                                              style: GoogleFonts
                                                                  .kanit(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 6),
                                                    // Department
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .business_outlined,
                                                          size: 14,
                                                          color:
                                                              Colors.grey[500],
                                                        ),
                                                        SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            _item[index].ORG_SUB_ID ==
                                                                        null ||
                                                                    _item[index]
                                                                            .ORG_SUB_ID ==
                                                                        ''
                                                                ? '- ไม่มีข้อมูล -'
                                                                : _getSubjectDepartment(
                                                                    int.parse(
                                                                        _item[index].ORG_SUB_ID ??
                                                                            '0')),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: GoogleFonts
                                                                .kanit(
                                                              fontSize: 13,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 4),
                                                    // Time
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.access_time,
                                                          size: 14,
                                                          color:
                                                              Colors.grey[500],
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          _item[index].TIME_ID ==
                                                                      null ||
                                                                  _item[index]
                                                                          .TIME_ID ==
                                                                      ''
                                                              ? '- ไม่มีข้อมูล -'
                                                              : _getSubjectTime(
                                                                  int.parse(
                                                                      _item[index]
                                                                              .TIME_ID ??
                                                                          '0')),
                                                          style:
                                                              GoogleFonts.kanit(
                                                            fontSize: 13,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Center(
                                child: Text(
                                  ' -- ไม่มีข้อมูล -- ',
                                  style: TextStyle(
                                      fontFamily: FontStyles().FontFamily,
                                      fontSize: 22,
                                      color: Colors.grey),
                                ),
                              ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
