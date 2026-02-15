import 'dart:convert';
import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:ismart_login/utils/dialog_helper.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/style/page_style.dart';
import 'package:ismart_login/style/text_style.dart';
import 'package:ismart_login/system/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LeaveTypesFormScreen extends StatefulWidget {
  final String id;
  final String title;
  final Function onLoadLeaveTypes;
  const LeaveTypesFormScreen({
    super.key,
    required this.id,
    required this.title,
    required this.onLoadLeaveTypes,
  });
  @override
  _LeaveTypesFormScreenState createState() => _LeaveTypesFormScreenState();
}

class _LeaveTypesFormScreenState extends State<LeaveTypesFormScreen> {
  List data = [];
  bool _switchStatus = true;
  TextEditingController _inputSubject = TextEditingController();
  TextEditingController _inputTotal = TextEditingController();
  TextEditingController _inputSeq = TextEditingController();

  @override
  void initState() {
    onLoadCateLeaveDetailManage();
    super.initState();
  }

  onLoadCateLeaveDetailManage() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
      "id": widget.id,
    };
    var body = json.encode(map);
    final response = await http.Client().post(
      Uri.parse(Server().getCateLeaveDetail),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    data = json.decode(response.body);
    if (data[0]['status'] == true) {
      data = data[0]['result'];
      print(data);
      _inputSubject.text = data[0]['subject'];
      _inputTotal.text = data[0]['total'];
      _inputSeq.text = data[0]['seq'];
      if (data[0]['status_cate'] == "1") {
        _switchStatus = true;
      } else {
        _switchStatus = false;
      }
    }
    blocSetState(() {});
  }

  // ignore: unused_element
  _insertCate() async {
    Map _map = {};
    _map.addAll({
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
      "seq": _inputSeq.text,
      "subject": _inputSubject.text,
      "total": _inputTotal.text,
      "status": _switchStatus ? "1" : "0",
    });
    print("_map : $_map");
    var body = json.encode(_map);
    final response = await http.Client().post(
      Uri.parse(Server().insertCateLeave),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    var data = json.decode(response.body);
    print('_insertCate : $data');
    if (data != null) {
      if (data['msg'].toString() == "success") {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
        widget.onLoadLeaveTypes();
        Navigator.pop(context, true);
      }
    }
  }

  // ignore: unused_element
  _updateCate() async {
    Map _map = {};
    _map.addAll({
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
      "id": widget.id.toString(),
      "seq": _inputSeq.text,
      "subject": _inputSubject.text,
      "total": _inputTotal.text,
      "status": _switchStatus ? "1" : "0",
    });
    print("_map : $_map");
    var body = json.encode(_map);
    final response = await http.Client().post(
      Uri.parse(Server().updateCateLeave),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    var data = json.decode(response.body);
    print('_updateCate : $data');
    if (data != null) {
      if (data['msg'].toString() == "success") {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
        widget.onLoadLeaveTypes();
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: StylePage().background,
        child: SafeArea(
          child: GestureDetector(
            onTap: () {
              FocusScopeNode currentFocus = FocusScope.of(context);
              if (!currentFocus.hasPrimaryFocus) {
                currentFocus.unfocus();
              }
            },
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
                          actions: [],
                          title: Text(
                            widget.title,
                            style: StylesText.titleAppBar,
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0),
                          elevation: 0,
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: 20, right: 20, bottom: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15.0)),
                              ),
                              padding:
                                  EdgeInsets.only(left: 20, right: 20, top: 20),
                              width: MediaQuery.of(context).size.width,
                              child: ListView(
                                children: [
                                  TextFormField(
                                    controller: _inputSubject,
                                    keyboardType: TextInputType.text,
                                    decoration: InputDecoration(
                                      hintText: 'ชื่อประเภท',
                                    ),
                                  ),
                                  TextFormField(
                                    controller: _inputTotal,
                                    decoration: InputDecoration(
                                      hintText: 'จำนวน',
                                    ),
                                  ),
                                  TextFormField(
                                    controller: _inputSeq,
                                    decoration: InputDecoration(
                                      hintText: 'เรียงตาม',
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Container(
                                    child: Row(
                                      children: [
                                        Expanded(
                                            child: Container(
                                          child: Text(
                                            'สถานะ',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        )),
                                        FlutterSwitch(
                                          value: _switchStatus ? true : false,
                                          width: 90.0,
                                          height: 40.0,
                                          valueFontSize: 12.0,
                                          toggleSize: 35.0,
                                          borderRadius: 20.0,
                                          padding: 5.0,
                                          showOnOff: true,
                                          activeText: 'แสดง',
                                          activeColor: Colors.green,
                                          inactiveText: 'ไม่แสดง',
                                          inactiveColor: Colors.grey,
                                          onToggle: (state) {
                                            blocSetState(() {
                                              _switchStatus = state;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: 20, right: 20),
                                    child: InkWell(
                                      onTap: () {
                                        if (_inputSubject.text == "") {
                                          DialogHelper.showError(
                                              context,
                                              'เกิดข้อผิดพลาด',
                                              'กรอกชื่อประเภทการลา');
                                          return;
                                        }
                                        // ถ้า id ว่าง = เพิ่มใหม่, ถ้ามีค่า = แก้ไข
                                        if (widget.id.isEmpty) {
                                          _insertCate();
                                        } else {
                                          _updateCate();
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Color(0xFF00B9FF),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(20.0)),
                                        ),
                                        height: 50,
                                        alignment: Alignment.center,
                                        child: Text(
                                          'บันทึก',
                                          style: TextStyle(
                                              fontSize: 22,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
}
