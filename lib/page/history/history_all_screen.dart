import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ismart_login/page/front/front_count_absence_screen.dart';
import 'package:ismart_login/page/front/front_count_late_screen.dart';
import 'package:ismart_login/page/front/front_count_ontime_screen.dart';
import 'package:ismart_login/page/front/front_count_outside_screen.dart';
import 'package:ismart_login/page/front/future/summary_future.dart';
import 'package:ismart_login/page/front/model/sumaryToDay.dart';
import 'package:ismart_login/page/front/model/sumaryToDay_absence.dart';
import 'package:ismart_login/page/front/model/sumaryToDay_late.dart';
import 'package:ismart_login/page/front/model/sumaryToDay_ontime.dart';
import 'package:ismart_login/page/front/model/sumaryToDay_outside.dart';
import 'package:ismart_login/page/history/future/history_future.dart';
import 'package:ismart_login/page/history/model/itemAllHistory.dart';
import 'package:ismart_login/page/managements/future/department_manage_future.dart';
import 'package:ismart_login/page/managements/model/itemDepartmentResultManage.dart';
import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/system/shared_preferences.dart';

class HistoryAllScreen extends StatefulWidget {
  final String status_super;
  final String admin_branch;
  final String name_branch;
  const HistoryAllScreen({
    super.key,
    required this.status_super,
    required this.admin_branch,
    required this.name_branch,
  });
  @override
  _HistoryAllScreenState createState() => _HistoryAllScreenState();
}

class _HistoryAllScreenState extends State<HistoryAllScreen> {
//---
  TextStyle styleLabel =
      TextStyle(fontFamily: FontStyles().FontFamily, fontSize: 14, height: 1);
  bool isLoading = false; //LoadMore
  // --- Post Data Member

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    onLoadHistoryAll(0);
    onLoadGetAllDepartment();
  }

  String dropdownValueDepartment = '0';
  int start = 0;
  List<ItemsAllHistory> _result = [];
  Future<bool> onLoadHistoryAll(int _start) async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "start": _start,
      "branch_id": (widget.admin_branch != '0' && widget.status_super != '1')
          ? widget.admin_branch
          : "0",
      "department_id": dropdownValueDepartment,
    };
    print("onLoadHistoryAll : ${map}");
    await HistoryFuture().apiGetSummaryAllDay(map).then((onValue) {
      if (start == 0) {
        setState(() {
          _result = onValue;
          print("count : " + _result.length.toString());
        });
      } else {
        setState(() {
          _result.addAll(onValue);
          print("count : " + _result.length.toString());
          isLoading = false;
        });
      }
    });
    setState(() {});
    return true;
  }

  _activeDataShow(
    int _type,
    String _date,
  ) async {
    Map _map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "create_date": _date,
      "department_id":
          dropdownValueDepartment != "0" ? dropdownValueDepartment : '0',
    };
    onLoadGetSummaryToDay(_map, _type);
  }

  List<ItemsDepartmentResultManage> _resultDepartment = [];
  Future<bool> onLoadGetAllDepartment() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
    };
    await DepartManageFuture().apiGetDepartmentManageList2(map).then((onValue) {
      if (onValue[0].STATUS == true) {
        setState(() {
          _resultDepartment = onValue[0].RESULT;
          dropdownValueDepartment = _resultDepartment[0].ID;
        });
      }
    });
    EasyLoading.dismiss();
    return true;
  }

  List<ItemsSummaryToDay> _result_on = [];
  List<ItemsSummaryToDay_Ontime> _result_ontime = [];
  List<ItemsSummaryToDay_Late> _result_late = [];
  List<ItemsSummaryToDay_Absence> _result_absence = [];
  List<ItemsSummaryToDay_Outside> _result_outside = [];
  Future<bool> onLoadGetSummaryToDay(Map map, int _type) async {
    print("onLoadGetSummaryToDay");
    print(map);
    await SummaryFuture().apiGetSummaryToDay(map).then((onValue) {
      _result_on = onValue;
      print(_result.length);
      setState(() {
        switch (_type) {
          case 1:
            _result_absence = _result_on[0].ABSENCE;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FrontCountAbsenceScreen(
                  items: _result_absence,
                ),
              ),
            );
            break;
          case 2:
            _result_ontime = _result_on[0].ONTIME;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FrontCountOntimeScreen(
                  items: _result_ontime,
                ),
              ),
            );
            break;
          case 3:
            _result_late = _result_on[0].LATE;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FrontCountLateScreen(
                  items: _result_late,
                ),
              ),
            );
            break;
          case 4:
            _result_outside = _result_on[0].OUTSIDE;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FrontCountOutsideScreen(
                  items: _result_outside,
                ),
              ),
            );
            break;

          default:
        }
      });
    });
    setState(() {});
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return _result.length > 0
        ? _display()
        : Column(
            children: [
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.grey[200]),
                margin: EdgeInsets.only(top: 10, bottom: 2),
              ),
              if (widget.admin_branch != '0' && widget.status_super == '0')
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(top: 5, bottom: 5),
                  child: Text(
                    "เฉพาะสาขา " + widget.name_branch.toString(),
                    style: TextStyle(
                        fontFamily: FontStyles().FontFamily,
                        fontSize: 24,
                        color: Colors.black),
                  ),
                ),
              if (widget.status_super == '1')
                Row(
                  children: [
                    Expanded(
                        flex: 1,
                        child: Container(
                            child: Text(
                          'สาขา',
                          style: TextStyle(
                              fontFamily: FontStyles().FontFamily,
                              fontSize: 22),
                        ))),
                    Expanded(
                      flex: 2,
                      child: Container(
                        child: DropdownButton<String>(
                          value: dropdownValueDepartment,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey,
                          ),
                          iconSize: 24,
                          elevation: 16,
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontFamily: FontStyles().FontFamily),
                          underline: Container(
                            height: 2,
                            color: Colors.blue,
                          ),
                          onChanged: (String? newValue) {
                            setState(() {
                              dropdownValueDepartment = newValue ?? '0';
                              onLoadHistoryAll(0);
                            });
                          },
                          items: _resultDepartment.length == 0
                              ? <String>[
                                  '0'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem(
                                    child: Text('- เลือก -'),
                                    value: value,
                                  );
                                }).toList()
                              : _resultDepartment.map((map) {
                                  return DropdownMenuItem(
                                    child: Text(map.SUBJECT),
                                    value: map.ID,
                                  );
                                }).toList(),
                        ),
                      ),
                    )
                  ],
                ),
              Center(
                child: Text(
                  '-- ไม่มีข้อมูล --',
                  style: TextStyle(
                    fontFamily: FontStyles().FontFamily,
                    fontSize: 24,
                    color: Colors.grey[400] ?? Colors.grey,
                  ),
                ),
              ),
            ],
          );
  }

  Widget _display() {
    return Container(
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.grey[200]),
            margin: EdgeInsets.only(top: 10, bottom: 2),
          ),
          if (widget.admin_branch != '0' && widget.status_super == '0')
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.only(top: 5, bottom: 5),
              child: Text(
                "เฉพาะสาขา " + widget.name_branch.toString(),
                style: TextStyle(
                    fontFamily: FontStyles().FontFamily,
                    fontSize: 24,
                    color: Colors.black),
              ),
            ),
          if (widget.status_super == '1')
            Row(
              children: [
                Expanded(
                    flex: 1,
                    child: Container(
                        child: Text(
                      'สาขา',
                      style: TextStyle(
                          fontFamily: FontStyles().FontFamily, fontSize: 22),
                    ))),
                Expanded(
                  flex: 2,
                  child: Container(
                    child: DropdownButton<String>(
                      value: dropdownValueDepartment,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey,
                      ),
                      iconSize: 24,
                      elevation: 16,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontFamily: FontStyles().FontFamily),
                      underline: Container(
                        height: 2,
                        color: Colors.blue,
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownValueDepartment = newValue ?? '0';
                          onLoadHistoryAll(0);
                        });
                      },
                      items: _resultDepartment.length == 0
                          ? <String>['0']
                              .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem(
                                child: Text('- เลือก -'),
                                value: value,
                              );
                            }).toList()
                          : _resultDepartment.map((map) {
                              return DropdownMenuItem(
                                child: Text(map.SUBJECT),
                                value: map.ID,
                              );
                            }).toList(),
                    ),
                  ),
                )
              ],
            ),
          Expanded(
            child: Container(
              child: Column(
                children: [
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (!isLoading &&
                            scrollInfo.metrics.pixels ==
                                scrollInfo.metrics.maxScrollExtent) {
                          // start loading data

                          setState(() {
                            start = start + 1;
                            onLoadHistoryAll(start);
                            isLoading = true;
                          });
                        }
                        return false;
                      },
                      child: _list(),
                    ),
                  ),
                  Container(
                    height: isLoading ? 50.0 : 0,
                    color: Colors.white70,
                    child: Center(
                      child: new CircularProgressIndicator(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list() {
    return Scrollbar(
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        separatorBuilder: (context, index) => SizedBox(height: 16),
        itemCount: _result.length,
        itemBuilder: (BuildContext context, int index) {
          var item = _result[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Header
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    item.CREATE_DATE_TH,
                    style: GoogleFonts.kanit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF21CCD4),
                    ),
                  ),
                ),
                // Stats Grid/Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      "ยังไม่ลงเวลา",
                      item.ABSENCE,
                      Color(0xFFFF802C),
                      () {
                        EasyLoading.show();
                        _activeDataShow(1, item.CREATE_DATE);
                      },
                    ),
                    _buildStatItem(
                      "ทันเวลา",
                      item.ONTIME,
                      Color(0xFFA7D645),
                      () {
                        EasyLoading.show();
                        _activeDataShow(2, item.CREATE_DATE);
                      },
                    ),
                    _buildStatItem(
                      "นอกสถานที่",
                      item.OUTSIDE,
                      Color(0xFFB907BD),
                      () {
                        EasyLoading.show();
                        _activeDataShow(4, item.CREATE_DATE);
                      },
                    ),
                    _buildStatItem(
                      "สาย",
                      item.LATE,
                      Color(0xFFD40000),
                      () {
                        EasyLoading.show();
                        _activeDataShow(3, item.CREATE_DATE);
                      },
                    ),
                    _buildStatItem(
                      "ลา",
                      0, // Hardcoded as per original
                      Colors.blue, // Pick a color for Leave
                      () {}, // No action yet
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
      String label, int count, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.transparent, // Hit test
          child: Column(
            children: [
              Container(
                height: 4,
                width: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 4),
              Text(
                count > 0 ? count.toString() : '0',
                style: GoogleFonts.kanit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.kanit(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
