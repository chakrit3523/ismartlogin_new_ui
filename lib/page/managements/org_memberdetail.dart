// ignore_for_file: unused_field

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ismart_login/page/managements/future/department_manage_future.dart';
import 'package:ismart_login/page/managements/future/member_manage_future.dart';
import 'package:ismart_login/page/managements/future/time_manage_future.dart';
import 'package:ismart_login/page/managements/model/itemDepartmentResultManage.dart';
import 'package:ismart_login/page/managements/model/itemMemberResultManage.dart';
import 'package:ismart_login/page/managements/model/itemMemberStatusManage.dart';
import 'package:ismart_login/page/managements/model/itemTimeResultMange.dart';
import 'package:ismart_login/page/profile/future/profile_future.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/style/page_style.dart';
import 'package:ismart_login/style/text_style.dart';
import 'package:ismart_login/system/shared_preferences.dart';
import 'package:ismart_login/system/widht_device.dart';

class OrgMemberDetailScreen extends StatefulWidget {
  final String title;
  final String id_member;
  final bool status;
  const OrgMemberDetailScreen({
    super.key,
    required this.title,
    required this.id_member,
    required this.status,
  });
  @override
  _OrgMemberDetailScreenState createState() => _OrgMemberDetailScreenState();
}

class _OrgMemberDetailScreenState extends State<OrgMemberDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  String get validDepartmentValue {
    if (_resultDepartment.any((d) => d.ID == dropdownValueDepartment)) {
      return dropdownValueDepartment;
    }
    return '0'; // ✅ fallback ถ้าไม่มีใน list
  }

  String get validTimeValue {
    if (_itemTime.any((t) => t.ID == dropdownValueTime)) {
      return dropdownValueTime;
    }
    return '0';
  }

  //Setup
  XFile? _imageFile;
  dynamic _pickImageError;

  ///
  bool _edit = false;
  String uid = '';
  String uid_my = '';
  String avatar = '';
  bool _switchStatus = false;
  bool _switchStat = false;
  bool _switchSuperAdmin = false;
  bool _switchAdminBranch = false;
  bool _switchAdmin = false;
  List _listTime = [];

  ///
  TextEditingController _inputName = TextEditingController();
  TextEditingController _inputLastname = TextEditingController();
  TextEditingController _inputNickname = TextEditingController();

  ///
  String dropdownValueTime = '0';
  String dropdownValueDepartment = '0';
  String dropdownValueAdminBranch = '0';
//---
  _getMyUid() async {
    uid_my = await SharedCashe.getItemsWay(name: 'id');
  }

  ///------ Time
  ///----  / GET -----
  List<ItemsTimeResultManage> _itemTime = [];
  Future<bool> onLoadGetAllTime() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
    };
    await TimeManageFuture().apiGetTimeManageList(map).then((onValue) {
      if (onValue[0].STATUS == true) {
        for (var time in onValue[0].RESULT) {
          // ✅ กันไม่ให้เพิ่มซ้ำ “0”
          if (time.ID != '0' &&
              _itemTime.indexWhere((t) => t.ID == time.ID) == -1) {
            _itemTime.add(time);
          }
        }
        setState(() {});
      }
    });
    return true;
  }

  List<ItemsDepartmentResultManage> _resultDepartment = [];
  Future<bool> onLoadGetAllDepartment() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
    };
    await DepartManageFuture().apiGetDepartmentManageList(map).then((onValue) {
      if (onValue[0].STATUS == true) {
        for (var dep in onValue[0].RESULT) {
          // ✅ กันไม่ให้เพิ่มซ้ำ “0”
          if (dep.ID != '0' &&
              _resultDepartment.indexWhere((d) => d.ID == dep.ID) == -1) {
            _resultDepartment.add(dep);
          }
        }
        setState(() {});
      }
    });
    EasyLoading.dismiss();
    return true;
  }

  ///-----
  ///
  ///  ///-----member
  List<ItemsMemberResultManage> _item = [];
  Future<bool> onLoadMemberManage() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": widget.id_member,
    };
    await MemberManageFuture().apiGetMemberManageList(map).then((onValue) {
      setState(() {
        if (onValue[0].STATUS) {
          _item = onValue[0].RESULT;
          print("status : " + _item[0].STATUS.toString());
          if (_item.length > 0) {
            if (_item[0].ORG_SUB_ID.toString() != '') {
              setState(() {
                dropdownValueDepartment = _item[0].ORG_SUB_ID ?? '0';
              });
            }
            if (_item[0].TIME_ID.toString() != '') {
              setState(() {
                dropdownValueTime = _item[0].TIME_ID ?? '0';
              });
            }
          }
          _getData();
        }
      });
    });
    EasyLoading.dismiss();
    setState(() {});

    return true;
  }

  List<ItemsMemberStatusManage> _itemStatus = [];
  Future<bool> onLoadMemberStatusManage(Map map) async {
    await MemberManageFuture()
        .apiGetMemberStatusManageList(map)
        .then((onValue) {
      setState(() {
        if (onValue[0].STATUS == false) {
          EasyLoading.showError('Error Save');
        }
      });
    });
    setState(() {});
    return true;
  }

  _updateStatusSuperAdmin(Map map) async {
    var body = json.encode(map);
    print('body : ' + body);
    final response = await http.Client().post(
      Uri.parse(Server().updateStatusSuperAdmin),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    var data = json.decode(response.body);
    print('insertSeq : $data');
  }

  _updateStatusBranchID(Map map) async {
    var body = json.encode(map);
    print('body : ' + body);
    final response = await http.Client().post(
      Uri.parse(Server().updateStatusBranchID),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    var data = json.decode(response.body);
    print('insertSeq : $data');
  }

  _getData() async {
    String? fullname = _item[0].FULLNAME;
    String _uid = widget.id_member;
    String? _nickname = _item[0].NICKNAME;
    String _avatar = _item[0].AVATAR ?? '';
    setState(() {
      List name = fullname != null ? fullname.split(",") : [];
      _inputName.text = name.isNotEmpty ? name[0] : '';
      if (name.length > 1) {
        _inputLastname.text = name[1];
      }
      _inputNickname.text = _nickname ?? '';
      uid = _uid;
      avatar = _avatar;
      _switchStatus = _item[0].STATUS == '1' ? true : false;
      _switchStat = _item[0].STAT == '1' ? true : false;
      _switchAdmin = _item[0].MEMBER_TYPE == 'admin' ? true : false;
      _switchSuperAdmin = _item[0].SUPER_STATUS == '1' ? true : false;
      _switchAdminBranch = _item[0].ADMIN_BRANCH_ID != '0' ? true : false;
    });
  }

  Future<dynamic> onUpdateProfile() async {
    await ProfileFuture().updateProfile(
      file: _imageFile?.path ?? '',
      uid: widget.id_member,
      name: _inputName.text,
      lastname: _inputLastname.text,
      nickname: _inputNickname.text,
      department: dropdownValueDepartment,
      time: dropdownValueTime,
      org_id: await SharedCashe.getItemsWay(name: 'org_id'),
    );
    return true;
  }

  @override
  void initState() {
    super.initState();
    _getMyUid();
    _resultDepartment.add(ItemsDepartmentResultManage(
      ID: '0',
      SUBJECT: '- เลือก -',
      PARENT_ID: '',
      INVITE_CODE: '',
      LATITUDE: '',
      LONGTITUDE: '',
      RADIUS: '',
      CREATE_DATE: '',
      UPDATE_DATE: '',
      NOTI: '',
      STATUS: '',
      SEQ: '',
      TIME_ID: '',
    ));

    _itemTime.add(ItemsTimeResultManage(
      ID: '0',
      SUBJECT: '- เลือก -',
      ORG_ID: '',
      DESCRIPTION: '',
      CREATE_DATE: '',
      STATUS: '',
    ));

    onLoadGetAllTime();
    onLoadGetAllDepartment();
    onLoadMemberManage();
    // _switch = widget.status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: StylePage().background,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                AppBar(
                  centerTitle: true,
                  leading: UnconstrainedBox(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ),
                  ),
                  title: Text(
                    widget.title,
                    style: StylesText.titleAppBar,
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 30),
                          width: WidhtDevice().widht(context),
                          decoration: StylePage().boxWhite,
                          child: Column(
                            children: [
                              Visibility(
                                visible: !_edit ? true : false,
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  width: WidhtDevice().widht(context),
                                  child: TextButton.icon(
                                    onPressed: () {
                                      if (!_edit) {
                                        setState(() {
                                          _edit = true;
                                        });
                                      }
                                    },
                                    icon: FaIcon(
                                      FontAwesomeIcons.userEdit,
                                      size: 16,
                                      color: Color(0xFF079CFD),
                                    ),
                                    label: Text(
                                      'แก้ไข',
                                      style: GoogleFonts.kanit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF079CFD),
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      backgroundColor:
                                          Color(0xFF079CFD).withOpacity(0.1),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (_edit) {
                                          _handleClickFiles();
                                        }
                                      },
                                      child: Container(
                                        margin: EdgeInsets.only(
                                            top: 20, bottom: 10),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF18C0FF),
                                              Color(0xFF079CFD)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xFF079CFD)
                                                  .withOpacity(0.3),
                                              blurRadius: 15,
                                              offset: Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        padding:
                                            EdgeInsets.all(4), // Border width
                                        child: ClipOval(
                                          child: Container(
                                            width: 150,
                                            height: 150,
                                            color: Colors.white,
                                            child: avatar != ''
                                                ? Image.network(
                                                    Server.url + avatar,
                                                    fit: BoxFit.cover,
                                                    width: 150.0,
                                                    height: 150.0,
                                                  )
                                                : _imageFile != null
                                                    ? Image.file(
                                                        File(_imageFile?.path ??
                                                            ''),
                                                        fit: BoxFit.cover,
                                                        width: 150.0,
                                                        height: 150.0,
                                                      )
                                                    : Container(
                                                        color: Colors.grey[100],
                                                        child: Icon(
                                                          Icons.person,
                                                          size: 80,
                                                          color:
                                                              Colors.grey[400],
                                                        ),
                                                      ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(padding: EdgeInsets.all(10)),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            enabled: _edit,
                                            controller: _inputName,
                                            keyboardType: TextInputType.name,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'กรุณากรอกข้อมูล';
                                              }
                                              return null;
                                            },
                                            style: GoogleFonts.kanit(
                                              fontSize: 16,
                                              color: Colors.grey[800],
                                            ),
                                            decoration: InputDecoration(
                                              labelText: 'ชื่อ',
                                              labelStyle: GoogleFonts.kanit(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                              filled: true,
                                              fillColor: _edit
                                                  ? Colors.grey[50]
                                                  : Colors.grey[100],
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                    color: Colors.grey[300]!),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                    color: Colors.grey[300]!),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                    color: Color(0xFF079CFD),
                                                    width: 2),
                                              ),
                                              disabledBorder:
                                                  OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                    color: Colors.grey[200]!),
                                              ),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 14),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            enabled: _edit,
                                            keyboardType: TextInputType.name,
                                            controller: _inputLastname,
                                            style: GoogleFonts.kanit(
                                              fontSize: 16,
                                              color: Colors.grey[800],
                                            ),
                                            decoration: InputDecoration(
                                              labelText: 'นามสกุล',
                                              labelStyle: GoogleFonts.kanit(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                              filled: true,
                                              fillColor: _edit
                                                  ? Colors.grey[50]
                                                  : Colors.grey[100],
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                    color: Colors.grey[300]!),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                    color: Colors.grey[300]!),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                    color: Color(0xFF079CFD),
                                                    width: 2),
                                              ),
                                              disabledBorder:
                                                  OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                    color: Colors.grey[200]!),
                                              ),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    TextFormField(
                                      enabled: _edit,
                                      keyboardType: TextInputType.name,
                                      controller: _inputNickname,
                                      style: GoogleFonts.kanit(
                                        fontSize: 16,
                                        color: Colors.grey[800],
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'ชื่อเล่น',
                                        labelStyle: GoogleFonts.kanit(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                        filled: true,
                                        fillColor: _edit
                                            ? Colors.grey[50]
                                            : Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.grey[300]!),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Color(0xFF079CFD),
                                              width: 2),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.grey[200]!),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 14),
                                      ),
                                    ),
                                    Padding(padding: EdgeInsets.all(2)),
                                    Row(
                                      children: [
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                                child: Text(
                                              'สาขา',
                                              style: TextStyle(
                                                  fontFamily:
                                                      FontStyles().FontFamily,
                                                  fontSize: 22),
                                            ))),
                                        Expanded(
                                          flex: 2,
                                          child: _edit
                                              ? Container(
                                                  child: DropdownButton<String>(
                                                    value: validDepartmentValue,
                                                    icon: Icon(
                                                      Icons.arrow_drop_down,
                                                      color: Colors.grey,
                                                    ),
                                                    iconSize: 24,
                                                    elevation: 16,
                                                    style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 20,
                                                        fontFamily: FontStyles()
                                                            .FontFamily),
                                                    underline: Container(
                                                      height: 2,
                                                      color: Colors.blue,
                                                    ),
                                                    onChanged:
                                                        (String? newValue) {
                                                      setState(() {
                                                        dropdownValueDepartment =
                                                            newValue ?? '0';
                                                      });
                                                    },
                                                    items: _resultDepartment
                                                                .length ==
                                                            0
                                                        ? <String>['0'].map<
                                                            DropdownMenuItem<
                                                                String>>((String
                                                            value) {
                                                            return DropdownMenuItem(
                                                              child: Text(
                                                                  '- เลือก -'),
                                                              value: value,
                                                            );
                                                          }).toList()
                                                        : _resultDepartment
                                                            .map((map) {
                                                            return DropdownMenuItem(
                                                              child: Text(
                                                                  map.SUBJECT),
                                                              value: map.ID,
                                                            );
                                                          }).toList(),
                                                  ),
                                                )
                                              : IgnorePointer(
                                                  child: Container(
                                                  child: DropdownButton<String>(
                                                    value: validDepartmentValue,
                                                    icon: Icon(
                                                      Icons.arrow_drop_down,
                                                      color: Colors.grey,
                                                    ),
                                                    iconSize: 24,
                                                    elevation: 16,
                                                    style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 20,
                                                        fontFamily: FontStyles()
                                                            .FontFamily),
                                                    underline: Container(
                                                      height: 1,
                                                      color: Colors.grey[400],
                                                    ),
                                                    onChanged:
                                                        (String? newValue) {
                                                      setState(() {
                                                        dropdownValueDepartment =
                                                            newValue ?? '0';
                                                      });
                                                    },
                                                    items: _resultDepartment
                                                                .length ==
                                                            0
                                                        ? <String>['0'].map<
                                                            DropdownMenuItem<
                                                                String>>((String
                                                            value) {
                                                            return DropdownMenuItem(
                                                              child: Text(
                                                                  '- เลือก -'),
                                                              value: value,
                                                            );
                                                          }).toList()
                                                        : _resultDepartment
                                                            .map((map) {
                                                            return DropdownMenuItem(
                                                              child: Text(
                                                                  map.SUBJECT),
                                                              value: map.ID,
                                                            );
                                                          }).toList(),
                                                  ),
                                                )),
                                        )
                                      ],
                                    ),
                                    Padding(padding: EdgeInsets.all(1)),
                                    Row(
                                      children: [
                                        Expanded(
                                            flex: 1,
                                            child: Container(
                                                child: Text(
                                              'เวลาทำงาน',
                                              style: TextStyle(
                                                  fontFamily:
                                                      FontStyles().FontFamily,
                                                  fontSize: 22),
                                            ))),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            child: _edit
                                                ? DropdownButton(
                                                    value: validTimeValue,
                                                    icon: Icon(
                                                      Icons.arrow_drop_down,
                                                      color: Colors.grey,
                                                    ),
                                                    iconSize: 24,
                                                    elevation: 16,
                                                    style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 20,
                                                        fontFamily: FontStyles()
                                                            .FontFamily),
                                                    underline: Container(
                                                      height: 2,
                                                      color: Colors.blue,
                                                    ),
                                                    onChanged: (newValue) {
                                                      setState(() {
                                                        dropdownValueTime =
                                                            newValue as String;
                                                      });
                                                    },
                                                    items: _itemTime.length == 0
                                                        ? <String>['0'].map<
                                                            DropdownMenuItem<
                                                                String>>((String
                                                            value) {
                                                            return DropdownMenuItem(
                                                              child: Text(
                                                                  '- เลือก -'),
                                                              value: value,
                                                            );
                                                          }).toList()
                                                        : _itemTime.map((map) {
                                                            return DropdownMenuItem(
                                                              child: Text(
                                                                  map.SUBJECT),
                                                              value: map.ID,
                                                            );
                                                          }).toList(),
                                                  )
                                                : IgnorePointer(
                                                    child: DropdownButton(
                                                      value: validTimeValue,
                                                      icon: Icon(
                                                        Icons.arrow_drop_down,
                                                        color: Colors.grey,
                                                      ),
                                                      iconSize: 24,
                                                      elevation: 16,
                                                      style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 20,
                                                          fontFamily:
                                                              FontStyles()
                                                                  .FontFamily),
                                                      underline: Container(
                                                        height: 1,
                                                        color: Colors.grey[400],
                                                      ),
                                                      onChanged: (newValue) {
                                                        setState(() {
                                                          dropdownValueTime =
                                                              newValue
                                                                  as String;
                                                        });
                                                      },
                                                      items: _itemTime.length ==
                                                              0
                                                          ? <String>['0'].map<
                                                              DropdownMenuItem<
                                                                  String>>((String
                                                              value) {
                                                              return DropdownMenuItem(
                                                                child: Text(
                                                                    '- เลือก -'),
                                                                value: value,
                                                              );
                                                            }).toList()
                                                          : _itemTime
                                                              .map((map) {
                                                              return DropdownMenuItem(
                                                                child: Text(map
                                                                    .SUBJECT),
                                                                value: map.ID,
                                                              );
                                                            }).toList(),
                                                    ),
                                                  ),
                                          ),
                                        )
                                      ],
                                    ),
                                    Padding(padding: EdgeInsets.all(10)),
                                    Visibility(
                                      visible: _edit,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Cancel Button
                                          Expanded(
                                            child: Container(
                                              height: 48,
                                              margin: EdgeInsets.only(right: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  onTap: () {
                                                    if (_edit) {
                                                      setState(() {
                                                        _edit = false;
                                                      });
                                                    }
                                                  },
                                                  child: Center(
                                                    child: Text(
                                                      'ยกเลิก',
                                                      style: GoogleFonts.kanit(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Confirm Button
                                          Expanded(
                                            child: Container(
                                              height: 48,
                                              margin: EdgeInsets.only(left: 6),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Color(0xFF18C0FF),
                                                    Color(0xFF079CFD)
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Color(0xFF079CFD)
                                                        .withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  onTap: () {
                                                    if (_formKey.currentState
                                                            ?.validate() ??
                                                        false) {
                                                      EasyLoading.show();
                                                      onUpdateProfile();
                                                      if (_edit) {
                                                        setState(() {
                                                          _edit = false;
                                                        });
                                                      }
                                                    }
                                                  },
                                                  child: Center(
                                                    child: Text(
                                                      'ตกลง',
                                                      style: GoogleFonts.kanit(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
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
                              Padding(padding: EdgeInsets.all(10)),
                            ],
                          ),
                        ),
                        Padding(padding: EdgeInsets.all(5)),
                        Container(
                          padding: EdgeInsets.only(
                              left: 10, right: 10, top: 10, bottom: 10),
                          width: WidhtDevice().widht(context),
                          decoration: StylePage().boxWhite,
                          child: Column(
                            children: [
                              Padding(padding: EdgeInsets.all(2)),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: Container(
                                      child: Text(
                                        'SUPER ADMIN',
                                        style: GoogleFonts.kanit(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[800]),
                                      ),
                                    )),
                                    FlutterSwitch(
                                      value: _switchSuperAdmin ? true : false,
                                      width: 50.0,
                                      height: 30.0,
                                      toggleSize: 26.0,
                                      borderRadius: 20.0,
                                      padding: 2.0,
                                      showOnOff: false,
                                      activeColor: Color(0xFF4CAF50),
                                      inactiveColor: Colors.grey[300]!,
                                      onToggle: (state) {
                                        setState(() {
                                          _switchSuperAdmin = state;
                                          var status = 0;
                                          if (state) {
                                            status = 1;
                                          } else {
                                            status = 0;
                                          }
                                          Map _map = {
                                            "id": widget.id_member,
                                            "status": status.toString(),
                                          };
                                          print(_map);
                                          _updateStatusSuperAdmin(_map);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Padding(padding: EdgeInsets.all(2)),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: Container(
                                      child: Text(
                                        'แอดมินสาขา',
                                        style: GoogleFonts.kanit(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[800]),
                                      ),
                                    )),
                                    FlutterSwitch(
                                      value: _switchAdminBranch ? true : false,
                                      width: 50.0,
                                      height: 30.0,
                                      toggleSize: 26.0,
                                      borderRadius: 20.0,
                                      padding: 2.0,
                                      showOnOff: false,
                                      activeColor: Color(0xFF4CAF50),
                                      inactiveColor: Colors.grey[300]!,
                                      onToggle: (state) {
                                        setState(() {
                                          _switchAdminBranch = state;
                                          if (state) {
                                            Map _map = {
                                              "id": widget.id_member,
                                              "admin_branch_id":
                                                  dropdownValueDepartment,
                                            };
                                            print(_map);
                                            _updateStatusBranchID(_map);
                                          } else {
                                            Map _map = {
                                              "id": widget.id_member,
                                              "admin_branch_id": "0",
                                            };
                                            print(_map);
                                            _updateStatusBranchID(_map);
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Padding(padding: EdgeInsets.all(2)),
                              Visibility(
                                visible:
                                    widget.id_member == uid_my ? false : true,
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                          child: Container(
                                        child: Text(
                                          'บทบาทในองค์กร',
                                          style: GoogleFonts.kanit(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[800]),
                                        ),
                                      )),
                                      FlutterSwitch(
                                        value: _switchAdmin ? true : false,
                                        width: 50.0,
                                        height: 30.0,
                                        toggleSize: 26.0,
                                        borderRadius: 20.0,
                                        padding: 2.0,
                                        showOnOff: false,
                                        activeColor: Color(0xFF4CAF50),
                                        inactiveColor: Colors.grey[300]!,
                                        onToggle: (state) {
                                          setState(() {
                                            _switchAdmin = state;
                                            Map _map = {
                                              "uid": widget.id_member,
                                              "key": "type",
                                              "value": _switchAdmin.toString(),
                                            };
                                            print(_map);
                                            onLoadMemberStatusManage(_map);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(padding: EdgeInsets.all(2)),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: Container(
                                      child: Text(
                                        'รายงานประจำวันในประวัติ',
                                        style: GoogleFonts.kanit(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[800]),
                                      ),
                                    )),
                                    FlutterSwitch(
                                      value: _switchStat ? true : false,
                                      width: 50.0,
                                      height: 30.0,
                                      toggleSize: 26.0,
                                      borderRadius: 20.0,
                                      padding: 2.0,
                                      showOnOff: false,
                                      activeColor: Color(0xFF4CAF50),
                                      inactiveColor: Colors.grey[300]!,
                                      onToggle: (state) {
                                        setState(() {
                                          _switchStat = state;
                                          Map _map = {
                                            "uid": widget.id_member,
                                            "key": "stat",
                                            "value": state.toString(),
                                          };
                                          print(_map);
                                          onLoadMemberStatusManage(_map);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Padding(padding: EdgeInsets.all(2)),
                              Visibility(
                                visible:
                                    widget.id_member == uid_my ? false : true,
                                child: Container(
                                  child: Row(
                                    children: [
                                      Expanded(
                                          child: Container(
                                        child: Text(
                                          'สถานะสมาชิก',
                                          style: TextStyle(
                                              fontFamily:
                                                  FontStyles().FontFamily,
                                              fontSize: 22),
                                        ),
                                      )),
                                      FlutterSwitch(
                                        value: _switchStatus ? true : false,
                                        width: 50.0,
                                        height: 30.0,
                                        toggleSize: 26.0,
                                        borderRadius: 20.0,
                                        padding: 2.0,
                                        showOnOff: false,
                                        activeColor: Color(0xFF4CAF50),
                                        inactiveColor: Colors.grey[300]!,
                                        onToggle: (state) {
                                          setState(() {
                                            _switchStatus = state;
                                            Map _map = {
                                              "uid": widget.id_member,
                                              "key": "status",
                                              "value": _switchStatus.toString(),
                                            };
                                            print(_map);
                                            onLoadMemberStatusManage(_map);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
          title: Text('อัพโหลดรูป',
              textScaleFactor: 1.0,
              style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold)),
          actions: <Widget>[
            CupertinoActionSheetAction(
              child: Text(
                'รูปภาพ',
                textScaleFactor: 1.0,
              ),
              onPressed: () {
                // _openFileImagesExplorer();
                _imgFromGallery();
                Navigator.pop(context);
              },
            ),
            CupertinoActionSheetAction(
              child: Text(
                'กล้อง',
                textScaleFactor: 1.0,
              ),
              onPressed: () {
                // _openCameraExplorer(ImageSource.camera, context: context);
                _imgFromCamera();
                Navigator.pop(context);
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            child: Text('ยกเลิก',
                textScaleFactor: 1.0, style: TextStyle(color: Colors.red)),
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
      setState(() {
        _imageFile = pickedFile;
      });
    } catch (e) {
      setState(() {
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
      setState(() {
        _imageFile = pickedFile;
      });
    } catch (e) {
      setState(() {
        _pickImageError = e;
        print(_pickImageError.toString());
      });
    }
  }
}
