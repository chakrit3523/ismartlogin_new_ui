// ignore_for_file: unused_field, must_call_super

import 'dart:convert';
import 'dart:io';

import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:ismart_login/utils/dialog_helper.dart';
import 'package:http_parser/http_parser.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/system/shared_preferences.dart';
import 'package:ismart_login/system/widht_device.dart';
import 'package:http/http.dart' as http;
import 'package:ismart_login/src/app/pages/main_page.dart';

class ConfirmDialog extends StatefulWidget {
  final String cause;
  final String cidSub;
  final String fullName;
  final String FirstDate;
  final String LastDate;
  final String numDate;
  final String phoneNum;
  final String firstTime;
  final String lastTime;
  final String selectFulltime;
  final bool select1;
  final bool select2;
  final bool select3;
  final List<File> filesAll;

  const ConfirmDialog({
    required Key key,
    required this.onConfirmTap,
    required this.cause,
    required this.fullName,
    required this.select1,
    required this.select2,
    required this.select3,
    required this.FirstDate,
    required this.LastDate,
    required this.numDate,
    required this.phoneNum,
    required this.selectFulltime,
    required this.firstTime,
    required this.lastTime,
    required this.cidSub,
    required this.filesAll,
  }) : super(key: key);

  @override
  State<ConfirmDialog> createState() => _ConfirmDialogState();
  final Function(String) onConfirmTap;
}

class _ConfirmDialogState extends State<ConfirmDialog> {
  TextEditingController _inputNote = TextEditingController();
  late String typeLeave;
  late String cidLeave;
  final _formKey = GlobalKey<FormState>();
  void initState() {
    if (widget.select1) {
      blocSetState(() {
        typeLeave = "ลาป่วย";
        cidLeave = "2";
      });
    }
    if (widget.select2) {
      blocSetState(() {
        typeLeave = "ลากิจ";
        cidLeave = "3";
      });
    }
    if (widget.select3) {
      blocSetState(() {
        typeLeave = "ลาอื่น ๆ";
        cidLeave = "4";
      });
    }
  }

  String get _effectiveNumDate {
    final fallback =
        widget.numDate.trim().isEmpty ? '1' : widget.numDate.trim();
    if (widget.selectFulltime != "1") {
      return fallback;
    }

    final from = _parseFlexibleDate(widget.FirstDate);
    final to = _parseFlexibleDate(widget.LastDate);
    if (from == null || to == null) {
      return fallback;
    }

    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    final days = end.difference(start).inDays.abs() + 1;
    return days.toString();
  }

  DateTime? _parseFlexibleDate(String raw) {
    final value = raw.trim();

    final ymd = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(value);
    if (ymd != null) {
      return DateTime(
        int.parse(ymd.group(1)!),
        int.parse(ymd.group(2)!),
        int.parse(ymd.group(3)!),
      );
    }

    final dmy = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4})$').firstMatch(value);
    if (dmy != null) {
      int year = int.parse(dmy.group(3)!);
      if (year < 100) {
        // Treat 2-digit input as BE short year (e.g. 69 -> 2569 -> 2026 AD).
        year = (2500 + year) - 543;
      } else if (year > 2400) {
        year -= 543;
      }
      return DateTime(
        year,
        int.parse(dmy.group(2)!),
        int.parse(dmy.group(1)!),
      );
    }

    return null;
  }

  // ignore: missing_return
  Future<bool> insertInfoLeave() async {
    Map map = {
      "uid": await SharedCashe.getItemsWay(name: 'id'),
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      'cause': widget.cause,
      'firstdate': widget.FirstDate,
      'lastdate': widget.LastDate,
      'phoneNum': widget.phoneNum,
      'numDate': _effectiveNumDate,
      'selectFultime': widget.selectFulltime,
      'firstTime': widget.firstTime,
      'lastTime': widget.lastTime,
      'selectFulltime': widget.selectFulltime,
      'cid': widget.cidSub != '' ? widget.cidSub : cidLeave,
    };
    var body = json.encode(map);
    print(body);
    // return false;
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
    print(response);
    final data = json.decode(response.body);
    print(data);
    if (data['msg'] == 'success') {
      Navigator.pop(context);
      alert_end(context, "บันทึกข้อมูลใบลาเรียบร้อยแล้ว");
      return true;
    } else {
      Navigator.pop(context);
      alert_end(context, "ไม่สามารถบันทึกข้อมูลใบลา กรุณาติดต่อเจ้าหน้าที่");
      return false;
    }
  }

  insertLeave() async {
    AwesomeDialog loadingDialog =
        DialogHelper.showLoading(context, 'กำลังโหลด...');
    var uri = Uri.parse(Server().insertInfoLeave);
    print("inform uri: ${uri.toString()}");
    var request = http.MultipartRequest('POST', uri);
    request.fields['uid'] = await SharedCashe.getItemsWay(name: 'id');
    request.fields['org_id'] = await SharedCashe.getItemsWay(name: 'org_id');
    request.fields['cause'] = widget.cause;
    request.fields['firstdate'] = widget.FirstDate;
    request.fields['lastdate'] = widget.LastDate;
    request.fields['phoneNum'] = widget.phoneNum;
    request.fields['numDate'] = _effectiveNumDate;
    request.fields['selectFultime'] = widget.selectFulltime;
    request.fields['firstTime'] = widget.firstTime;
    request.fields['lastTime'] = widget.lastTime;
    request.fields['selectFulltime'] = widget.selectFulltime;
    if (widget.cidSub != '') {
      request.fields['cid'] = widget.cidSub;
    } else {
      request.fields['cid'] = cidLeave;
    }
    var lenFile = widget.filesAll.length;
    if (lenFile > 0) {
      for (int i = 0; i < lenFile; i++) {
        var ext = widget.filesAll[i].path.split('.').last;
        var file = await http.MultipartFile.fromPath(
            'file[$i]', widget.filesAll[i].path,
            contentType: MediaType('image', ext));
        request.files.add(file);
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      loadingDialog.dismiss();
      final data = jsonDecode(response.body);
      if (data['msg'] == 'success') {
        Navigator.pop(context);
        alert_end(context, "บันทึกข้อมูลใบลาเรียบร้อยแล้ว");
      } else {
        Navigator.pop(context);
        alert_end(context, "ไม่สามารถบันทึกข้อมูลใบลา กรุณาติดต่อเจ้าหน้าที่");
      }
    } else {
      loadingDialog.dismiss();
      Navigator.pop(context);
      alert_end(context, "ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์");
    }
  }

  alert_end(BuildContext context, String text) async {
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
                        fontFamily: FontStyles().FontFamily, fontSize: 24),
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
                            AwesomeDialog loadingDialog =
                                DialogHelper.showLoading(context, 'Loading...');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MainPage()),
                            ).then((_) => loadingDialog.dismiss());
                            // delay slightly to allow push to start?
                            // Just dismissing immediately might be fine if MainPage manages itself.
                            // But since we navigate away, the dialog context might be tricky.
                            // Actually, if we push MainPage, this screen is still in stack until we pop or replace.
                            // But MainPage likely replaces everything or sits on top.
                            // Let's just remove the loading here as it's not very useful for a local push unless there's heavy work in MainPage init.
                            loadingDialog.dismiss();
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
                              'รับทราบ',
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      contentPadding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
      content: SingleChildScrollView(
        child: Container(
          width: WidhtDevice().widht(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Container(
                  // width: 30,
                  height: 120,
                  child: Image.asset(
                    'assets/images/other/ic-send.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                child: Center(
                  child: Text(
                    'ส่งใบลา',
                    style: TextStyle(
                      fontFamily: FontStyles().FontFamily,
                      // height: 1,
                      fontSize: 26,
                      color: Colors.blue.shade300,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child: Text(
                        widget.fullName.toString() +
                            " เนื่องจาก " +
                            widget.cause.toString() +
                            ' ขอ' +
                            typeLeave,
                        style: TextStyle(
                          fontFamily: FontStyles().FontFamily,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (widget.selectFulltime == "1")
                    Container(
                      padding: EdgeInsets.only(left: 10, right: 5),
                      child: Text(
                        "ตั้งแต่วันที่" +
                            " " +
                            widget.FirstDate +
                            " ถึง " +
                            widget.LastDate,
                        style: TextStyle(
                          fontFamily: FontStyles().FontFamily,
                          // height: 1,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  if (widget.selectFulltime == "2")
                    Container(
                      padding: EdgeInsets.only(left: 10, right: 5),
                      child: Text(
                        "วันที่" +
                            " " +
                            widget.FirstDate +
                            " เวลา " +
                            widget.firstTime +
                            " - " +
                            widget.lastTime,
                        style: TextStyle(
                          fontFamily: FontStyles().FontFamily,
                          // height: 1,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  Container(
                    // padding: EdgeInsets.only(left: 5),
                    child: Text(
                      widget.selectFulltime == "1"
                          ? _effectiveNumDate + " วัน"
                          : _effectiveNumDate + " ชม.",
                      style: TextStyle(
                        fontFamily: FontStyles().FontFamily,
                        // height: 1,
                        fontSize: 20,
                      ),
                    ),
                  )
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
                    child: Text(
                      "เบอร์ติดต่อได้ขณะลา" + " " + widget.phoneNum,
                      style: TextStyle(
                        fontFamily: FontStyles().FontFamily,
                        // height: 1,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
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
                            color: Colors.red[100],
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20.0),
                            ),
                          ),
                          height: 50,
                          alignment: Alignment.center,
                          child: Text(
                            'ยกเลิก',
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
                          // insertInfoLeave();
                          insertLeave();
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
                            'ยืนยัน',
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
      ),
    );
  }

  _causeNote() {
    return Container(
      padding: EdgeInsets.all(10),
      child: Row(
        children: [
          Text(
            'สาเหตุ',
            style: TextStyle(fontFamily: FontStyles().FontFamily, fontSize: 22),
          ),
          Expanded(
            child: TextFormField(
              controller: _inputNote,
              keyboardType: TextInputType.text,
              style:
                  TextStyle(fontFamily: FontStyles().FontFamily, fontSize: 22),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: EdgeInsets.all(0), // add padding to adjust icon
                  child: Icon(
                    Icons.edit,
                    size: 22,
                  ),
                ),
              ),
              validator: (value) {
                print("valueOT $value");
                if (value == null || value.isEmpty) {
                  return 'กรุณาป้อนข้อมูล';
                }
                return null;
              },
            ),
          )
        ],
      ),
    );
  }
}
