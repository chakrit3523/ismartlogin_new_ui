import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ismart_login/page/managements/future/time_manage_future.dart';
import 'package:ismart_login/page/managements/model/itemTimeResultDayManage.dart';
import 'package:ismart_login/page/managements/model/itemTimeResultMange.dart';
import 'package:ismart_login/page/managements/org_timedatail_screen.dart';
import 'package:ismart_login/style/text_style.dart';
import 'package:ismart_login/system/widht_device.dart';

class OrgTimeManage extends StatefulWidget {
  final String org_id;
  OrgTimeManage({Key? key, required this.org_id}) : super(key: key);
  @override
  _OrgTimeManageState createState() => _OrgTimeManageState();
}

class _OrgTimeManageState extends State<OrgTimeManage> {
  ///----  / GET -----
  List<ItemsTimeResultManage> _resultItem = [];
  List<ItemsTimeResultDayManage> _resultItemDay = [];
  Future<bool> onLoadGetAllTime() async {
    Map map = {
      "org_id": widget.org_id,
    };
    await TimeManageFuture().apiGetTimeManageList(map).then((onValue) {
      print(onValue[0].STATUS);
      print(onValue[0].MSG);
      if (onValue[0].STATUS == true) {
        setState(() {
          _resultItem = onValue[0].RESULT;
        });
      }
    });
    EasyLoading.dismiss();
    return true;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    onLoadGetAllTime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF21CCD4), Color(0xFF0663F7)],
          ),
        ),
        child: SafeArea(
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
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                actions: [
                  Container(
                    margin: EdgeInsets.only(right: 16),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: IconButton(
                        icon: FaIcon(FontAwesomeIcons.plus,
                            size: 18, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrgTimeDetailManage(
                                id: '0',
                                org_id: widget.org_id,
                                type: 'insert',
                                updateLoadTime: onLoadGetAllTime,
                              ),
                            ),
                          ).then((value) {
                            value ? onLoadGetAllTime() : null;
                          });
                        },
                      ),
                    ),
                  )
                ],
                title: Text(
                  'วันเวลาทำงาน',
                  style: StylesText.titleAppBar,
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: Container(
                  width: WidhtDevice().widht(context),
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
                    itemCount: _resultItem.length,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () {
                          EasyLoading.show();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrgTimeDetailManage(
                                id: _resultItem[index].ID,
                                org_id: _resultItem[index].ORG_ID,
                                type: 'update',
                                updateLoadTime: onLoadGetAllTime,
                              ),
                            ),
                          ).then((value) {
                            value ? onLoadGetAllTime() : null;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 15),
                          padding: EdgeInsets.all(16),
                          width: WidhtDevice().widht(context),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: FaIcon(
                                      FontAwesomeIcons.businessTime,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _resultItem[index].SUBJECT,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.kanit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Divider(height: 1, color: Colors.grey[200]),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    _getDay(_resultItem[index].DESCRIPTION),
                                    style: GoogleFonts.kanit(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _getDay(String _itemDay) {
    _resultItemDay = List.from(
        json.decode(_itemDay).map((m) => ItemsTimeResultDayManage.fromJson(m)));

    String display = '';
    List _day = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    for (int i = 0; i < _resultItemDay.length; i++) {
      if (i == 0) {
        display = _day[_resultItemDay[i].DAY];
      } else {
        display += ', ' + _day[_resultItemDay[i].DAY];
      }
    }
    return display;
  }
}
