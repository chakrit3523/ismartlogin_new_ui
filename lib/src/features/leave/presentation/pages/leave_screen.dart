// ignore_for_file: unnecessary_null_comparison

import 'dart:convert';

import 'dart:io';
import 'package:file_picker/file_picker.dart';

import 'package:flutter/cupertino.dart';
import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ismart_login/src/features/leave/presentation/pages/confirm_leave.dart';
import 'package:ismart_login/src/features/leave/presentation/pages/leave_statistics.dart';
import 'package:ismart_login/src/features/leave/domain/entities/leave_date_selection.dart';
import 'package:ismart_login/src/features/leave/presentation/helpers/thai_leave_date_formatter.dart';
import 'package:ismart_login/src/features/leave/presentation/widgets/leave_date_range_picker_field.dart';

import 'package:ismart_login/src/features/managements/presentation/pages/future/member_manage_future.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/future/time_manage_future.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/model/itemMemberResultManage.dart';
import 'package:ismart_login/src/features/managements/presentation/pages/model/itemTimeResultMange.dart';

import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/style/font_style.dart';

import 'package:ismart_login/system/shared_preferences.dart';
import 'package:ismart_login/system/widht_device.dart';
import 'package:http/http.dart' as http;

class LeaveScreen extends StatefulWidget {
  @override
  _LeaveScreenState createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  List<int> _daySelect = [];
  DateTime FirstDate = DateTime.now();
  DateTime LastDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  bool select1 = true;
  bool select2 = false;
  bool select3 = false;
  bool inputCause = false;
  bool inputTotalDays = false;
  bool inputTotalTimes = false;
  bool _inputPhone = false;
  var start;
  var end;
  List<String> items = <String>['0'];
  List<String> itemsTime = <String>[
    '0.5',
    '1',
    '1.5',
    '2',
    '2.5',
    '3',
    '3.5',
    '4',
    '4.5',
    '5',
    '5.5',
    '6',
    '6.5',
    '7',
    '7.5',
    '8'
  ];
  String selectItem = '1';
  String selectItemTime = '1';
  String? timeError;
  int _selectFullTime = 1;
  String sick_leave = '0';
  String personal_leave = '0';
  String other_leave = '0';

  TextEditingController _inputCause = TextEditingController();
  TextEditingController inputPhone = TextEditingController();
  TextEditingController _inputTotalDays = TextEditingController();
  TextEditingController _inputTotalTimes = TextEditingController();
  List<ItemsMemberResultManage> _itemMember = [];
  List<File> _files = [];
  LeaveDateSelection _leaveDateSelection = LeaveDateSelection.initial();
  // 'full' | 'morning' | 'afternoon'
  String _periodMode = 'full';

  List<bool> _groupDay = [
    true,
  ];

  TimeOfDay _timeOfDay = TimeOfDay.now();

  List<TextEditingController> _inputTimeIn = [
    TextEditingController(),
  ];

  List<TextEditingController> _inputTimeOut = [
    TextEditingController(),
  ];

  // final difference = LastDate.difference(FirstDate).inDays;
  TextStyle styleDetail = TextStyle(
      fontFamily: FontStyles().FontFamily,
      fontSize: 18,
      color: Colors.black,
      height: 1);

  TextStyle styleButton = TextStyle(
      fontFamily: FontStyles().FontFamily,
      fontSize: 20,
      color: Colors.blue,
      height: 1);

  TextStyle styleHeader = TextStyle(
      fontFamily: FontStyles().FontFamily,
      fontSize: 25,
      color: Colors.white,
      height: 2);
  TextStyle styleSubHeader = TextStyle(
      fontFamily: FontStyles().FontFamily,
      fontSize: 23,
      color: Color(0xFF8F8C8C),
      height: 1);

  Future<bool> insertInfoLeave() async {
    String inputCause = _inputCause.text;

    print(inputCause);
    Map map = {
      "uid": await SharedCashe.getItemsWay(name: 'id'),
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      'cause': inputCause,
    };
    var body = json.encode(map);
    print(body);

    final http.Response response = await http.post(
      Uri.parse(Server().insertInfoLeave),
      headers: <String, String>{
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*", // Required for CORS support to work
        "Access-Control-Allow-Credentials": "true",
        "Access-Control-Allow-Headers":
            "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale",
        "Access-Control-Allow-Methods": "*"
      },
      body: body,
    );
    if (response.statusCode != 200) {
      return false;
    }
    if (response.statusCode == 200) {
      print('yehhhhh');
    }
    print(response);
    final data = json.decode(response.body);
    print(data);
    return data['status'] == 'success';
  }

  void initState() {
    // _inputTotalDays.text = " ";
    onLoadGetAllTypes();
    onLoadMemberManage();
    onLoadLeaveSummary();
    _calculateTotalDays();
    _applyLeaveSelection(_leaveDateSelection, notify: false);
    super.initState();
  }

  Future<void> onLoadLeaveSummary() async {
    final map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
      "status_leave": "",
      "cid": "",
      "month_start": "",
      "year_start": "",
      "month_end": "",
      "year_end": "",
    };
    final body = json.encode(map);
    final response = await http.Client().post(
      Uri.parse(Server().getListLeave),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    final leaveData = json.decode(response.body);

    if (leaveData is List && leaveData.isNotEmpty) {
      sick_leave = leaveData[0]['sick']?.toString() ?? '0';
      personal_leave = leaveData[0]['leave']?.toString() ?? '0';
      other_leave = leaveData[0]['other']?.toString() ?? '0';
      if (mounted) {
        blocSetState(() {});
      }
    }
  }

  Future<bool> onLoadMemberManage() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
    };
    print("--- Load Member Manage ---");
    print("map : ${map}");
    await MemberManageFuture().apiGetMemberManageList(map).then((onValue) {
      print("check tab ${onValue[0].STATUS}");
      print("check tab ${onValue[0].SICK_LEAVE}");
      blocSetState(() {
        if (onValue[0].STATUS) {
          _itemMember = onValue[0].RESULT;
        }
      });
    });
    blocSetState(() {});
    return true;
  }

  String dropdownValueTime = '0';
  List<ItemsTimeResultManage> _itemTypes = [];
  Future<bool> onLoadGetAllTypes() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
    };
    await TimeManageFuture().apiGetTypesManageList(map).then((onValue) {
      if (onValue[0].STATUS == true) {
        blocSetState(() {
          _itemTypes = onValue[0].RESULT;
          dropdownValueTime = _itemTypes[0].ID;
        });
      }
    });
    return true;
  }

  popup_comfirm(BuildContext context) {
    var newFormat = DateFormat("yyyy-MM-dd");
    showDialog(
        context: context,
        builder: (_) {
          return ConfirmDialog(
            key: UniqueKey(),
            onConfirmTap: (String value) {},
            select1: select1,
            select2: select2,
            select3: select3,
            cidSub: select3 ? dropdownValueTime : '',
            FirstDate: newFormat.format(FirstDate),
            LastDate: newFormat.format(LastDate),
            numDate: _selectFullTime == 2
                ? _inputTotalTimes.text
                : _inputTotalDays.text,
            phoneNum: inputPhone.text,
            selectFulltime: _selectFullTime.toString(),
            firstTime: _inputTimeIn[0].text,
            lastTime: _inputTimeOut[0].text,
            cause: _inputCause.text,
            fullName: _itemMember[0].FULLNAME ?? '',
            filesAll: _files,
            halfDayPeriod: _periodMode == 'full' ? '' : _periodMode,
          );
        });
  }

  void _applyPeriodMode(String mode) {
    _periodMode = mode;
    final isHalfDay = mode != 'full';
    final period = mode == 'morning'
        ? HalfDayPeriod.morning
        : mode == 'afternoon'
            ? HalfDayPeriod.afternoon
            : null;

    if (isHalfDay) {
      // Force single-day for half-day leave
      LastDate = FirstDate;
      _leaveDateSelection = _leaveDateSelection.copyWith(
        endDate: FirstDate,
        isHalfDay: true,
        totalDays: 0.5,
        halfDayPeriod: period,
        clearStartTime: true,
        clearEndTime: true,
      );
      _inputTotalDays.text = '0.5';
      _selectFullTime = 1;
      _inputTotalTimes.clear();
    } else {
      final days = LastDate.difference(FirstDate).inDays + 1;
      _leaveDateSelection = _leaveDateSelection.copyWith(
        isHalfDay: false,
        totalDays: days.toDouble(),
        clearHalfDayPeriod: true,
      );
      _inputTotalDays.text = days.toString();
    }
    blocSetState(() {});
  }

  void _applyLeaveSelection(
    LeaveDateSelection selection, {
    bool notify = true,
  }) {
    _leaveDateSelection = selection;
    FirstDate = selection.startDate;
    LastDate = selection.endDate;

    if (selection.isTimeRange) {
      _selectFullTime = 2;
      _inputTotalTimes.text = _formatLeaveAmount(selection.totalDays);
      _inputTotalDays.text = '1';
    } else {
      _selectFullTime = 1;
      _inputTotalDays.text = _formatLeaveAmount(selection.totalDays);
      _inputTotalTimes.clear();
    }

    if (_inputTimeIn.isEmpty) {
      _inputTimeIn = [TextEditingController()];
    }
    if (_inputTimeOut.isEmpty) {
      _inputTimeOut = [TextEditingController()];
    }
    _inputTimeIn[0].text = selection.startTime == null
        ? ''
        : ThaiLeaveDateFormatter.toTimeLabel(selection.startTime!);
    _inputTimeOut[0].text = selection.endTime == null
        ? ''
        : ThaiLeaveDateFormatter.toTimeLabel(selection.endTime!);

    if (notify && mounted) {
      blocSetState(() {});
    }
  }

  String _formatLeaveAmount(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    int daysBetween(DateTime from, DateTime to) {
      from = DateTime(from.year, from.month, from.day);
      to = DateTime(to.year, to.month, to.day);
      return (to.difference(from).inHours / 24).round() + 1;
    }

    final difference = daysBetween(FirstDate, LastDate);
    //log('difference: $difference');

    for (var i = 0; i <= difference; i++) {
      if (items.every((item) => item != '${i}')) {
        items.add('${i - 0.5}');
        items.add('${i}');
      }
    }
    //log('data: $items');
    return Scaffold(
        body: Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF21CCD4), // Cyan
            Color(0xFF0663F7), // Deep Blue
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus) {
              currentFocus.unfocus();
            }
          },
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  AppBar(
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: Text(
                      'ลา',
                      style: GoogleFonts.kanit(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Form(
                    key: _formKey,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 1. Leave Type Tabs
                          Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Sick Leave Tab
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      blocSetState(() {
                                        select1 = true;
                                        select2 = false;
                                        select3 = false;
                                      });
                                    },
                                    child: Container(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: select1
                                            ? Color(0xFF21CCD4)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(11),
                                          bottomLeft: Radius.circular(11),
                                          topRight: select2
                                              ? Radius.zero
                                              : Radius.circular(0),
                                          bottomRight: select2
                                              ? Radius.zero
                                              : Radius.circular(0),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        "ลาป่วย",
                                        style: GoogleFonts.kanit(
                                          fontSize: 16,
                                          fontWeight: select1
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: select1
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Personal Leave Tab
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      blocSetState(() {
                                        select1 = false;
                                        select2 = true;
                                        select3 = false;
                                      });
                                    },
                                    child: Container(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: select2
                                            ? Color(0xFF21CCD4)
                                            : Colors.transparent,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        "ลากิจ",
                                        style: GoogleFonts.kanit(
                                          fontSize: 16,
                                          fontWeight: select2
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: select2
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Other Leave Tab
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      blocSetState(() {
                                        select1 = false;
                                        select2 = false;
                                        select3 = true;
                                      });
                                    },
                                    child: Container(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: select3
                                            ? Color(0xFF21CCD4)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(11),
                                          bottomRight: Radius.circular(11),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        "อื่นๆ",
                                        style: GoogleFonts.kanit(
                                          fontSize: 16,
                                          fontWeight: select3
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: select3
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Dropdown for Other Types
                          if (select3) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ประเภทการลา',
                                    style: GoogleFonts.kanit(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Container(),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 20),
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50], // Light blue bg
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: dropdownValueTime,
                                  isExpanded: true,
                                  icon: Icon(Icons.keyboard_arrow_down,
                                      color: Color(0xFF21CCD4)),
                                  items: _itemTypes
                                      .map((ItemsTimeResultManage item) {
                                    return DropdownMenuItem<String>(
                                      value: item.ID,
                                      child: Text(
                                        item.SUBJECT!,
                                        style: GoogleFonts.kanit(fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    blocSetState(() {
                                      dropdownValueTime = newValue!;
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                          ],

                          // 2. Reason Input Header
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'เนื่องจาก',
                                style: GoogleFonts.kanit(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              color: Colors.white,
                            ),
                            child: Column(
                              children: [
                                // 3. Reason Input Field
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 0),
                                  child: TextFormField(
                                    controller: _inputCause,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      hintText: 'ระบุเหตุผลการลา...',
                                      hintStyle: GoogleFonts.kanit(
                                          color: Colors.grey[400]),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding: EdgeInsets.all(16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.grey[200]!),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.grey[200]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Color(0xFF21CCD4),
                                            width: 1.5),
                                      ),
                                      errorText:
                                          inputCause ? "กรุณาระบุเหตุผล" : null,
                                    ),
                                    style: GoogleFonts.kanit(fontSize: 14),
                                  ),
                                ),
                                SizedBox(height: 20),

                                // 4. Date Selection Header
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'วันที่ลา',
                                      style: GoogleFonts.kanit(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: LeaveDateRangePickerField(
                                    initialStart: FirstDate,
                                    initialEnd: LastDate,
                                    enableHalfDay: false,
                                    enableTimeRange: select3,
                                    onChanged: (selection) {
                                      _applyLeaveSelection(selection);
                                      // Re-apply period logic after date change
                                      _applyPeriodMode(_periodMode);
                                    },
                                  ),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _leaveDateSelection.isTimeRange
                                              ? "รวมจำนวนชั่วโมง"
                                              : "รวมจำนวนวัน",
                                          style: GoogleFonts.kanit(
                                            fontSize: 14,
                                            color: Color(0xFF0663F7),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              _formatLeaveAmount(
                                                  _leaveDateSelection
                                                      .totalDays),
                                              style: GoogleFonts.kanit(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0663F7),
                                              ),
                                            ),
                                            Text(
                                              _leaveDateSelection.isTimeRange
                                                  ? " ชม."
                                                  : " วัน",
                                              style: GoogleFonts.kanit(
                                                fontSize: 14,
                                                color: Color(0xFF0663F7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Period selector (Full / Morning / Afternoon)
                                if (!_leaveDateSelection.isTimeRange) ...[  
                                  SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ช่วงเวลาลา',
                                          style: GoogleFonts.kanit(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            _PeriodChip(
                                              label: 'ทั้งวัน',
                                              icon: Icons.sunny,
                                              selected:
                                                  _periodMode == 'full',
                                              onTap: () =>
                                                  _applyPeriodMode('full'),
                                            ),
                                            SizedBox(width: 8),
                                            _PeriodChip(
                                              label: 'ครึ่งวันเช้า',
                                              icon:
                                                  Icons.wb_sunny_outlined,
                                              selected:
                                                  _periodMode == 'morning',
                                              onTap: () =>
                                                  _applyPeriodMode(
                                                      'morning'),
                                            ),
                                            SizedBox(width: 8),
                                            _PeriodChip(
                                              label: 'ครึ่งวันบ่าย',
                                              icon:
                                                  Icons.wb_twilight_outlined,
                                              selected:
                                                  _periodMode == 'afternoon',
                                              onTap: () =>
                                                  _applyPeriodMode(
                                                      'afternoon'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                SizedBox(height: 20),

                                // 8. Contact Info
                                SizedBox(height: 20),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: Text(
                                    'เบอร์โทรศัพท์ติดต่อ',
                                    style: GoogleFonts.kanit(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: TextFormField(
                                    controller: inputPhone,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    decoration: InputDecoration(
                                      hintText: 'เบอร์ที่ติดต่อได้...',
                                      hintStyle: GoogleFonts.kanit(
                                          color: Colors.grey[400]),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding: EdgeInsets.all(16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.grey[200]!),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.grey[200]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Color(0xFF21CCD4),
                                            width: 1.5),
                                      ),
                                      prefixIcon: Icon(Icons.phone_outlined,
                                          color: Colors.grey[500]),
                                      counterText: "",
                                      errorText: _inputPhone
                                          ? "กรุณาระบุเบอร์โทร"
                                          : null,
                                    ),
                                    style: GoogleFonts.kanit(fontSize: 14),
                                  ),
                                ),

                                // 9. Attachment
                                SizedBox(height: 20),
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: 20),
                                  child: InkWell(
                                    onTap: () {
                                      _filesExplorer();
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Color(0xFF21CCD4),
                                            style: BorderStyle.solid),
                                        borderRadius: BorderRadius.circular(12),
                                        color: Color(0xFF21CCD4)
                                            .withValues(alpha: 0.05),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.attach_file,
                                              color: Color(0xFF21CCD4)),
                                          SizedBox(width: 8),
                                          Text(
                                            "แนบเอกสาร (ถ้ามี)",
                                            style: GoogleFonts.kanit(
                                              color: Color(0xFF21CCD4),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // File List
                                if (_files != null && _files.length > 0)
                                  Container(
                                    height: 100.0,
                                    margin: EdgeInsets.only(
                                        top: 12, left: 20, right: 20),
                                    child: _fileView(),
                                  ),

                                SizedBox(height: 30),

                                // 10. Submit Button
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  width: double.infinity,
                                  child: GestureDetector(
                                    onTap: () {
                                      // Validation Logic
                                      if (!(_formKey.currentState?.validate() ??
                                          false)) return;

                                      if (_inputCause.text.isEmpty) {
                                        blocSetState(() => inputCause = true);
                                        return;
                                      } else {
                                        blocSetState(() => inputCause = false);
                                      }

                                      if (inputPhone.text.isEmpty) {
                                        blocSetState(() => _inputPhone = true);
                                        return;
                                      } else {
                                        blocSetState(() => _inputPhone = false);
                                      }

                                      if (_inputTotalDays.text.isEmpty) {
                                        blocSetState(
                                            () => inputTotalDays = true);
                                        return;
                                      } else {
                                        blocSetState(
                                            () => inputTotalDays = false);
                                      }

                                      // Popup Confirm
                                      popup_comfirm(context);
                                    },
                                    child: Container(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF21CCD4),
                                            Color(0xFF0663F7)
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF0663F7)
                                                .withValues(alpha: 0.4),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'ส่งใบลา',
                                        style: GoogleFonts.kanit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 40),
                                Divider(thickness: 1, color: Colors.grey[200]),
                                SizedBox(height: 20),

                                // 11. Relocated Leave Statistics
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'ข้อมูลการลาของคุณ',
                                        style: GoogleFonts.kanit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    LeaveStatisticsScreen()),
                                          );
                                        },
                                        child: Text(
                                          'ดูทั้งหมด >',
                                          style: GoogleFonts.kanit(
                                            fontSize: 14,
                                            color: Color(0xFF0663F7),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  height: 110,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 20),
                                    children: [
                                      _buildStatCard(
                                          "ลาป่วย", sick_leave, Colors.blue),
                                      SizedBox(width: 12),
                                      _buildStatCard("ลากิจ", personal_leave,
                                          Colors.green),
                                      SizedBox(width: 12),
                                      _buildStatCard(
                                          "อื่นๆ", other_leave, Colors.orange),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 50),
                              ],
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
        ),
      ),
    ));
  }

  Widget _fileView() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _files.length,
      padding: const EdgeInsets.all(2.0),
      itemBuilder: (context, index) {
        var fileName = _files[index].path.split('/').last;
        var extensions = fileName.split('.').last.toString();
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: Stack(
            children: <Widget>[
              Container(
                width: 104.0,
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Color(0xFFCCCCCC),
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Image(
                            image: AssetImage(
                                "assets/images/extension/$extensions.png"),
                            width: 80.0,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      fileName,
                      maxLines: 1,
                      textScaler: TextScaler.linear(1.0),
                      style: TextStyle(fontSize: 11.0),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -10,
                right: -10,
                child: IconButton(
                  onPressed: () {
                    blocSetState(() {
                      _files.removeWhere((element) => element == _files[index]);
                    });
                  },
                  icon: Icon(
                    Icons.cancel,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _filesExplorer() async {
    print("_filesExplorer");
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null) {
      List<File> files =
          result.paths.whereType<String>().map((path) => File(path)).toList();
      //print("wit files : ${files}");
      if (!mounted) return;
      if (files.length > 0) {
        blocSetState(() {
          if (_files != null && _files.length > 0) {
            _files.addAll(files);
          } else {
            _files = files.toList();
          }
        });
      }
    } else {
      // User canceled the picker
    }
  }

  alert_time(BuildContext context, int _status, int _day) async {
    String _time = '00:00';
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
                  height: MediaQuery.of(context).size.height / 3,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime:
                        DateTime(_timeOfDay.hour, _timeOfDay.minute),
                    onDateTimeChanged: (DateTime newDateTime) {
                      var newTod = TimeOfDay.fromDateTime(newDateTime);

                      final now = new DateTime.now();
                      // print(DateFormat.Hm().format(DateTime(now.year, now.month,
                      //     now.day, newTod.hour, newTod.minute)));
                      _time = DateFormat.Hm()
                          .format(DateTime(now.year, now.month, now.day,
                              newTod.hour, newTod.minute))
                          .toString();
                    },
                    use24hFormat: true,
                    minuteInterval: 30,
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
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context, _time);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green[100],
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
    ).then((value) {
      if (value != null) {
        var format = DateFormat("HH:mm");
        blocSetState(() {
          if (_status == 1) {
            _inputTimeIn[_day].text = value.toString().substring(0, 5);
            start = format.parse(value);
          } else {
            _inputTimeOut[_day].text = value.toString().substring(0, 5);
            end = format.parse(value);
          }
          print(start);
          print(end);
          if (start != null && end != null) {
            Duration duration = end.difference(start).abs();
            print(duration);
            final hours = duration.inHours;
            var times = duration.inMinutes - (60 * hours);
            print(times);
            if (times == 30) {
              times = 50;
            }
            _inputTotalTimes.text = "${hours.toString()}.${times.toString()}";
          }
        });
      }
    });
  }

  _calculateTotalDays() {
    print("FirstDate: $FirstDate");
    print("LastDate: $LastDate");

    // Normalize dates to ignore time components
    final start = DateTime(FirstDate.year, FirstDate.month, FirstDate.day);
    final end = DateTime(LastDate.year, LastDate.month, LastDate.day);

    // Calculate difference in days (inclusive)
    final diff = end.difference(start).inDays + 1;
    final days = diff > 0 ? diff : 1; // Minimum 1 day

    print("Diff Days: $days");

    blocSetState(() {
      _inputTotalDays.text = days.toString();

      // Re-initialize lists for partial time selection based on number of days
      _groupDay = List.generate(days, (index) => true);

      // Preserve existing controllers if possible, or create new ones
      // Here we just create new ones for simplicity to avoid index errors
      _inputTimeIn = List.generate(days, (index) => TextEditingController());
      _inputTimeOut = List.generate(days, (index) => TextEditingController());

      _daySelect.clear();
    });
  }

  _selectDay(int _numday, bool _status) {
    blocSetState(() {
      if (_status) {
        _daySelect.add(_numday);
        _inputTimeIn[_numday].text = _inputTimeIn[_daySelect[0]].text;
        _inputTimeOut[_numday].text = _inputTimeOut[_daySelect[0]].text;
      } else {
        _daySelect.remove(_numday);
      }
    });
    print(_daySelect);
  }

  void expect(int daysBetween, int i) {}

  Widget _buildStatCard(String title, String days, Color color) {
    return Container(
      width: 100,
      margin: EdgeInsets.only(right: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.kanit(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                days,
                style: GoogleFonts.kanit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "วัน",
                  style: GoogleFonts.kanit(
                    fontSize: 10,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Period Chip Widget ────────────────────────────────────────────────────────
class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF21CCD4), Color(0xFF0663F7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? null
                : Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : Colors.grey[500],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.kanit(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

