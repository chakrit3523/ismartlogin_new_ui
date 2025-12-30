// ignore_for_file: unnecessary_null_comparison, unused_element

import 'dart:convert';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/system/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LeaveStatisticsDetailScreen extends StatefulWidget {
  final String sick;
  final String leave;
  final String other;
  const LeaveStatisticsDetailScreen({
    super.key,
    required this.sick,
    required this.leave,
    required this.other,
  });
  @override
  _LeaveStatisticsDetailScreenState createState() =>
      _LeaveStatisticsDetailScreenState();
}

class _LeaveStatisticsDetailScreenState
    extends State<LeaveStatisticsDetailScreen> {
  List data = [];

  String sick = '0';
  String sickAll = 'n';
  String leave = '0';
  String leaveAll = 'n';

  @override
  void initState() {
    onLoadCateLeaveOrgManage();
    super.initState();
  }

  onLoadCateLeaveOrgManage() async {
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
    };
    var body = json.encode(map);
    final response = await http.Client().post(
      Uri.parse(Server().getCateLeaveOrg),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    var responseData = json.decode(response.body);
    if (responseData is List &&
        responseData.isNotEmpty &&
        responseData[0]['result'] != null) {
      data = responseData[0]['result'];
    } else {
      data = [];
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var now = new DateTime.now();
    var formatter = new DateFormat('yyyy-MM-dd');
    String formattedDate = formatter.format(now);
    final values = formattedDate.split('-');
    final yearCurr = int.parse(values[0]) + 543;

    return Scaffold(
      backgroundColor: Color(0xFF21CCD4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'ตรวจสอบสิทธิ',
          style: GoogleFonts.kanit(
              fontSize: 24, color: Colors.white, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        margin: EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 20),
            Text(
              'สถิติการลาสะสมปี ${yearCurr.toString()}',
              style: GoogleFonts.kanit(
                  fontSize: 20,
                  color: Color(0xFF21CCD4),
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                child: Column(
                  children: [
                    // SICK LEAVE
                    _buildDetailCard(
                      color: Color(0xFFFF9C04),
                      iconPath: "assets/images/other/injured.svg",
                      title: "ลาป่วย",
                      count: widget.sick,
                      total: sickAll,
                    ),
                    SizedBox(height: 12),
                    // PERSONAL LEAVE
                    _buildDetailCard(
                      color: Color(0xFF5AD1E9),
                      iconPath: "assets/images/other/exit.svg",
                      title: "ลากิจ",
                      count: widget.leave,
                      total: leaveAll,
                    ),
                    SizedBox(height: 12),
                    // OTHER LEAVE
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF305AE3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 60,
                                  alignment: Alignment.center,
                                  child: SvgPicture.asset(
                                    "assets/images/other/travel.svg",
                                    color: Colors.white,
                                    width: 50,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "อื่น ๆ",
                                  style: GoogleFonts.kanit(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Dynamic Other List
                          if (data != null && data.length > 2)
                            for (var i = 2; i < data.length; i++)
                              Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                        color: Colors.white.withOpacity(0.5),
                                        width: 1.0),
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        data[i]['subject'].toString(),
                                        style: GoogleFonts.kanit(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      "${data[i]['total'].toString()}/${data[i]['totalAll'].toString()}",
                                      style: GoogleFonts.kanit(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required Color color,
    required String iconPath,
    required String title,
    required String count,
    required String total,
  }) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            padding: EdgeInsets.all(16),
            child: SvgPicture.asset(
              iconPath,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.kanit(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: Text(
              "$count/$total",
              style: GoogleFonts.kanit(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
