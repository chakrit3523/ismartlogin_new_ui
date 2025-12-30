import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ismart_login/page/managements/future/member_manage_future.dart';
import 'package:ismart_login/page/managements/model/itemMemberResultManage.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/style/font_style.dart';
import 'package:ismart_login/style/page_style.dart';
import 'package:ismart_login/system/shared_preferences.dart';

import '../main.dart';
import 'leave_detail.dart';

class LeaveNotiListScreen extends StatefulWidget {
  @override
  _LeaveNotiListScreenState createState() => _LeaveNotiListScreenState();
}

class _LeaveNotiListScreenState extends State<LeaveNotiListScreen> {
  List data = [];
  String len = '0';
  List<ItemsMemberResultManage> _itemMember = [];
  String tab = "1";

  @override
  void initState() {
    onLoadListNotiLeaveManage();
    onLoadMemberManage();
    super.initState();
  }

  onLoadListNotiLeaveManage() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
      "tab": tab
    };
    var body = json.encode(map);
    print('onLoadListNotiLeaveManage : ${body}');
    final response = await http.Client().post(
      Uri.parse(Server().getListNotiLeave),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    data = json.decode(response.body);
    if (data.isNotEmpty && data[0]['status'] == true) {
      if (data[0]['result'] != null) {
        len = data[0]['result'].length.toString();
      } else {
        len = '0';
      }
    } else {
      len = '0';
    }
    if (mounted) setState(() {});
  }

  Future<bool> onLoadMemberManage() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
    };
    await MemberManageFuture().apiGetMemberManageList(map).then((onValue) {
      if (mounted) {
        setState(() {
          if (onValue[0].STATUS) {
            _itemMember = onValue[0].RESULT;
          }
        });
      }
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    List rs = [];
    if (data.length > 0 && data[0]['result'] != null) {
      rs = data[0]['result'];
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF21CCD4), Color(0xFF0663F7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'แจ้งเตือน',
                          style: GoogleFonts.kanit(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 48), // Balance back button
                  ],
                ),
              ),

              // Content Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 10),
                      // Custom Tab Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: Colors.grey[200]!)),
                          ),
                          child: Row(
                            children: [
                              _buildTabItem("ทั้งหมด", "1"),
                              _buildTabItem("ยังไม่อ่าน", "2"),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),

                      // List
                      Expanded(
                        child: rs.length > 0
                            ? ListView.builder(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                itemCount: rs.length,
                                itemBuilder: (context, index) {
                                  return _buildNotificationItem(rs[index]);
                                },
                              )
                            : _buildEmptyState(),
                      ),
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

  Widget _buildTabItem(String title, String tabValue) {
    bool isSelected = tab == tabValue;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            tab = tabValue;
            onLoadListNotiLeaveManage();
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Color(0xFF21CCD4) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.kanit(
              fontSize: 18,
              color: isSelected ? Color(0xFF21CCD4) : Colors.grey[500],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(dynamic item) {
    Color statusColor = Color(0xFF616161);
    // status_leave: 1=Wait/Orange, 2=Approve/Green, 3=Reject/Red
    if (item['status_noti'].toString() == "0") {
      // If Unread
      if (item['status_leave'].toString() == "1")
        statusColor = Color(0xFFFF7700);
      else if (item['status_leave'].toString() == "2")
        statusColor = Color(0xFF01BB50);
      else if (item['status_leave'].toString() == "3")
        statusColor = Color(0xFFFF0000);
    }

    bool isUnread = item['status_noti'].toString() == "0";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeaveDetailScreen(
              id: item['topic_id'].toString(),
              loadData: onLoadListNotiLeaveManage,
              loadListLeave: onLoadListNotiLeaveManage,
            ),
          ),
        ).then((value) => onLoadListNotiLeaveManage());
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? Color(0xFFF0FBFC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
          border: isUnread
              ? Border.all(color: Color(0xFF21CCD4).withOpacity(0.3))
              : Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicator Dot
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 12),
              child: Icon(Icons.circle, size: 12, color: statusColor),
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['subject'].toString(),
                    style: GoogleFonts.kanit(
                        fontSize: 16,
                        fontWeight:
                            isUnread ? FontWeight.bold : FontWeight.normal,
                        color: Colors.black87,
                        height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    item['create_date'].toString(),
                    style: GoogleFonts.kanit(
                        fontSize: 14,
                        color: Color(0xFF21CCD4),
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: 0.5,
            child: Image.asset(
              'assets/images/other/ic-send.png',
              height: 80,
            ),
          ),
          SizedBox(height: 20),
          Text(
            "ไม่มีการแจ้งเตือน",
            style: GoogleFonts.kanit(
              fontSize: 18,
              color: Colors.grey[400],
            ),
          )
        ],
      ),
    );
  }
}
