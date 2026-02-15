// ignore_for_file: unnecessary_null_comparison

import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';
import 'package:intl/intl.dart';
import 'package:ismart_login/server/server.dart';
import 'package:ismart_login/system/shared_preferences.dart';

import 'leave_detail.dart';
import 'leave_filter.dart';
import 'leave_statistics_dateil.dart';

class LeaveStatisticsScreen extends StatefulWidget {
  @override
  _LeaveStatisticsScreenState createState() => _LeaveStatisticsScreenState();
}

class _LeaveStatisticsScreenState extends State<LeaveStatisticsScreen> {
  List data = [];
  List statusData = [];
  List typesData = [];

  String sick = '0';
  String leave = '0';
  String other = '0';

  String dropdownValueStartMonth = "เลือกเดือน";
  String dropdownValueStartYear = "เลือกปี";
  String dropdownValueEndMonth = "เลือกเดือน";
  String dropdownValueEndYear = "เลือกปี";

  @override
  void initState() {
    super.initState();
    onLoadListLeaveManage();
  }

  onLoadListLeaveManage() async {
    String statusLeave = '';
    String typesLeave = '';
    if (statusData != null && statusData.length > 0) {
      statusLeave = statusData.join(',');
    }
    if (typesData != null && typesData.length > 0) {
      typesLeave = typesData.join(',');
    }
    Map map = {
      "org_id": await SharedCashe.getItemsWay(name: 'org_id'),
      "uid": await SharedCashe.getItemsWay(name: 'id'),
      "status_leave": statusLeave,
      "cid": typesLeave,
      "month_start": dropdownValueStartMonth != "เลือกเดือน"
          ? dropdownValueStartMonth
          : "",
      "year_start":
          dropdownValueStartYear != "เลือกปี" ? dropdownValueStartYear : "",
      "month_end":
          dropdownValueEndMonth != "เลือกเดือน" ? dropdownValueEndMonth : "",
      "year_end": dropdownValueEndYear != "เลือกปี" ? dropdownValueEndYear : "",
    };
    var body = json.encode(map);
    final response = await http.Client().post(
      Uri.parse(Server().getListLeave),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    data = json.decode(response.body);

    if (data.isNotEmpty && data[0]['status'] == true) {
      sick = data[0]['sick'].toString();
      leave = data[0]['leave'].toString();
      other = data[0]['other'].toString();
    } else {
      if (data.isNotEmpty && data[0]['result'] == null) {
        data = [];
      }
    }
    if (mounted) {
      blocSetState(() {});
    }
  }

  onSetDataFilter(List status, List types, String monthStart, String yearStart,
      String monthEnd, String yearEnd) async {
    if (status != null && status.length > 0) {
      statusData = status;
    }
    if (types != null && types.length > 0) {
      typesData = types;
    }

    if (monthStart != null && monthStart != "") {
      dropdownValueStartMonth = monthStart;
    } else {
      dropdownValueStartMonth = "เลือกเดือน";
    }

    if (yearStart != null && yearStart != "") {
      dropdownValueStartYear = yearStart;
    } else {
      dropdownValueStartYear = "เลือกปี";
    }

    if (monthEnd != null && monthEnd != "") {
      dropdownValueEndMonth = monthEnd;
    } else {
      dropdownValueEndMonth = "เลือกเดือน";
    }

    if (yearEnd != null && yearEnd != "") {
      dropdownValueEndYear = yearEnd;
    } else {
      dropdownValueEndYear = "เลือกปี";
    }

    onLoadListLeaveManage();
  }

  @override
  Widget build(BuildContext context) {
    var now = new DateTime.now();
    var formatter = new DateFormat('yyyy-MM-dd');
    String formattedDate = formatter.format(now);
    final values = formattedDate.split('-');
    final yearCurr = int.parse(values[0]) + 543;

    List rs = [];
    if (data.length > 0 && data[0]['result'] != null) {
      rs = data[0]['result'];
    }

    return Scaffold(
      backgroundColor: Color(0xFF21CCD4),
      appBar: AppBar(
        title: Text(
          'สถิติการลา',
          style: GoogleFonts.kanit(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
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
            // Year Header
            Text(
              'สถิติการลาสะสมปี ${yearCurr}',
              style: GoogleFonts.kanit(
                fontSize: 18,
                color: Color(0xFF21CCD4),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Statistics Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard(
                      "ลาป่วย", sick, Color(0xFFFFE0B2), Color(0xFF000000)),
                  _buildStatCard(
                      "ลากิจ", leave, Color(0xFFE1BEE7), Color(0xFF000000)),
                  _buildStatCard(
                      "ลาอื่นๆ", other, Color(0xFFC8E6C9), Color(0xFF000000)),
                ],
              ),
            ),
            SizedBox(height: 12),

            // Check Rights Link
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LeaveStatisticsDetailScreen(
                        sick: sick,
                        leave: leave,
                        other: other,
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "ตรวจสอบสิทธิ",
                      style: GoogleFonts.kanit(
                        color: Colors.grey,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  ],
                ),
              ),
            ),

            Divider(height: 20, thickness: 1, indent: 16, endIndent: 16),

            // History Header & Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "ประวัติลางาน",
                    style: GoogleFonts.kanit(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _showFilterBottomSheet(context);
                    },
                    child: Row(
                      children: [
                        Text(
                          "ตัวกรอง",
                          style: GoogleFonts.kanit(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.tune, size: 18, color: Colors.grey[600]),
                      ],
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 10),

            // Leave History List
            Expanded(
              child: rs.length > 0
                  ? ListView.builder(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      itemCount: rs.length,
                      itemBuilder: (context, index) {
                        return _buildHistoryItem(rs[index]);
                      },
                    )
                  : Center(
                      child: Text(
                        "- ไม่มีข้อมูล -",
                        style: GoogleFonts.kanit(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String count, Color bgColor, Color textColor) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48) / 3,
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              title,
              style: GoogleFonts.kanit(
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.kanit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map item) {
    String typeName = item['cate_name'] ?? '';
    String dateRange = item['dateLeave'] ?? '';
    String status = item['status_leave_text'] ?? '';
    String statusId = item['status_leave'] ?? '1';

    Color badgeColor = _getTypeColor(typeName);
    Color statusColor = _getStatusColor(statusId);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeaveDetailScreen(
              id: item['id'].toString(),
              loadListLeave: onLoadListLeaveManage,
              loadData: onLoadListLeaveManage,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              padding: EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                typeName,
                style: GoogleFonts.kanit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                dateRange,
                style: GoogleFonts.kanit(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              status,
              style: GoogleFonts.kanit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[300])
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    if (type.contains("ป่วย")) return Color(0xFFFFE0B2);
    if (type.contains("กิจ")) return Color(0xFFE1BEE7);
    return Color(0xFFC8E6C9);
  }

  Color _getStatusColor(String statusId) {
    switch (statusId) {
      case '1':
        return Color(0xFFFF9800);
      case '2':
        return Color(0xFF4CAF50);
      case '3':
        return Color(0xFFF44336);
      case '9':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      context: context,
      builder: (BuildContext bc) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          height: 400, // Fixed height or use dynamic
          child: LeaveFilterScreen(
            key: UniqueKey(),
            statusDataTmp: statusData,
            typesDataTmp: typesData,
            setDataFilterLeaveData: onSetDataFilter,
            dropdownValueStartMonthTmp: dropdownValueStartMonth,
            dropdownValueStartYearTmp: dropdownValueStartYear,
            dropdownValueEndMonthTmp: dropdownValueEndMonth,
            dropdownValueEndYearTmp: dropdownValueEndYear,
          ),
        );
      },
    );
  }
}
